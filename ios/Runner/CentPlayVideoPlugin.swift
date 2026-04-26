import Flutter
import AVFoundation

/// CentPlay 네이티브 비디오 플레이어 — iOS 구현.
///
/// video_player 패키지 없이 AVPlayer + FlutterTexture를 직접 연결.
/// textureId 기반 멀티 인스턴스 — 여러 플레이어 동시 운용 가능.
class CentPlayVideoPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var textureRegistry: FlutterTextureRegistry
    private var players: [Int64: VideoPlayerInstance] = [:]
    private var eventSink: FlutterEventSink?

    init(textureRegistry: FlutterTextureRegistry) {
        self.textureRegistry = textureRegistry
        super.init()
    }

    // MARK: - Registration

    static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = CentPlayVideoPlugin(textureRegistry: registrar.textures())

        let method = FlutterMethodChannel(name: "com.centplay/video_player", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(plugin, channel: method)

        let events = FlutterEventChannel(name: "com.centplay/video_player/events", binaryMessenger: registrar.messenger())
        events.setStreamHandler(plugin)
    }

    // MARK: - MethodChannel

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        if call.method == "create" {
            guard let urlString = args?["url"] as? String,
                  let url = URL(string: urlString) else {
                result(FlutterError(code: "INVALID_ARGS", message: "url required", details: nil))
                return
            }
            let instance = VideoPlayerInstance(url: url, registry: textureRegistry) { [weak self] data in
                self?.sendEvent(data)
            }
            players[instance.textureId] = instance
            result(["textureId": instance.textureId])
            return
        }

        guard let tid = args?["textureId"] as? Int64,
              let instance = players[tid] else {
            if call.method == "dispose" { result(nil); return }
            result(FlutterError(code: "NOT_FOUND", message: "player not found", details: nil))
            return
        }

        if call.method == "dispose" {
            instance.dispose()
            players.removeValue(forKey: tid)
            textureRegistry.unregisterTexture(tid)
            result(nil)
            return
        }

        instance.handle(call.method, args: args, result: result)
    }

    // MARK: - EventChannel

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func sendEvent(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in self?.eventSink?(data) }
    }
}

// =============================================================================
// 개별 플레이어 인스턴스
// =============================================================================

private class VideoPlayerInstance: NSObject, FlutterTexture {

    private(set) var textureId: Int64 = -1
    private let registry: FlutterTextureRegistry
    private let onEvent: ([String: Any]) -> Void

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    private var timeObserver: Any?

    private var statusObs: NSKeyValueObservation?
    private var bufferEmptyObs: NSKeyValueObservation?
    private var bufferKeepUpObs: NSKeyValueObservation?
    private var rateObs: NSKeyValueObservation?

    private var lastPos: Int = -1

    init(url: URL, registry: FlutterTextureRegistry, onEvent: @escaping ([String: Any]) -> Void) {
        self.registry = registry
        self.onEvent = onEvent
        super.init()

        // super.init() 후에 self를 FlutterTexture로 등록
        self.textureId = registry.register(self)
        setupPlayer(url: url)
    }

    private func setupPlayer(url: URL) {
        let asset = AVURLAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem!)
        player?.automaticallyWaitsToMinimizeStalling = true

        // GPU 공유 pixel buffer (IOSurfacePropertiesKey 필수)
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
        ])
        playerItem!.add(videoOutput!)

        // DisplayLink — 재생 중일 때만 활성
        displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink))
        displayLink?.add(to: .main, forMode: .common)
        displayLink?.isPaused = true

        setupObservers()
    }

    private func setupObservers() {
        statusObs = playerItem!.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                self.emit([
                    "event": "initialized",
                    "duration": Int(CMTimeGetSeconds(item.duration) * 1000),
                    "width": Int(item.presentationSize.width),
                    "height": Int(item.presentationSize.height),
                ])
            } else if item.status == .failed {
                self.emit(["event": "error", "message": item.error?.localizedDescription ?? "Unknown error"])
            }
        }

        bufferEmptyObs = playerItem!.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackBufferEmpty { self?.emit(["event": "buffering"]) }
        }

        bufferKeepUpObs = playerItem!.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackLikelyToKeepUp { self?.emit(["event": "bufferingEnd"]) }
        }

        rateObs = player!.observe(\.rate, options: [.new]) { [weak self] player, _ in
            guard let self = self else { return }
            let playing = player.rate > 0
            self.displayLink?.isPaused = !playing
            self.emit(["event": playing ? "playing" : "paused"])
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(onEnded),
            name: .AVPlayerItemDidPlayToEndTime, object: playerItem
        )

        let interval = CMTime(value: 1, timescale: 10)
        timeObserver = player!.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let ms = Int(CMTimeGetSeconds(time) * 1000)
            if ms != self.lastPos {
                self.lastPos = ms
                self.emit(["event": "position", "position": ms])
            }
        }
    }

    // MARK: - Commands

    func handle(_ method: String, args: [String: Any]?, result: @escaping FlutterResult) {
        switch method {
        case "play":
            player?.play(); result(nil)
        case "pause":
            player?.pause(); result(nil)
        case "seekTo":
            let ms = args?["position"] as? Int ?? 0
            player?.seek(to: CMTime(value: Int64(ms), timescale: 1000),
                         toleranceBefore: .zero, toleranceAfter: .zero) { _ in result(nil) }
        case "setPlaybackSpeed":
            player?.rate = Float(args?["speed"] as? Double ?? 1.0); result(nil)
        case "setMaxBitrate":
            playerItem?.preferredPeakBitRate = Double(args?["bitrate"] as? Int ?? 0); result(nil)
        case "getAvailableBitrates":
            var bitrates = Set<Int>()
            for event in (playerItem?.accessLog()?.events ?? []) {
                let br = Int(event.indicatedBitrate)
                if br > 0 { bitrates.insert(br) }
            }
            result(bitrates.sorted())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - DisplayLink + FlutterTexture

    @objc private func onDisplayLink() {
        guard let output = videoOutput else { return }
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        if output.hasNewPixelBuffer(forItemTime: time) {
            registry.textureFrameAvailable(textureId)
        }
    }

    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let output = videoOutput else { return nil }
        let time = output.itemTime(forHostTime: CACurrentMediaTime())
        guard let buf = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return nil }
        return Unmanaged.passRetained(buf)
    }

    // MARK: - Events

    @objc private func onEnded() {
        displayLink?.isPaused = true
        emit(["event": "completed"])
    }

    private func emit(_ data: [String: Any]) {
        var event = data
        event["textureId"] = textureId
        onEvent(event)
    }

    // MARK: - Cleanup

    func dispose() {
        displayLink?.invalidate(); displayLink = nil
        if let obs = timeObserver { player?.removeTimeObserver(obs) }; timeObserver = nil
        statusObs?.invalidate(); bufferEmptyObs?.invalidate()
        bufferKeepUpObs?.invalidate(); rateObs?.invalidate()
        NotificationCenter.default.removeObserver(self)
        player?.pause(); player = nil; playerItem = nil; videoOutput = nil
    }
}
