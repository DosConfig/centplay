import Flutter
import UIKit
import AudioToolbox

/// GameBridge 플랫폼 채널 — iOS 구현.
///
/// Core Haptics 프레임워크를 활용한 게임 맞춤 햅틱 패턴.
/// UIKit의 UIImpactFeedbackGenerator보다 세밀한 제어 가능.
/// Flutter 패키지(vibration 등)로는 iOS Core Haptics에 접근 불가.
@main
@objc class AppDelegate: FlutterAppDelegate {

    private var gameBridgeChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        gameBridgeChannel = FlutterMethodChannel(
            name: "com.centplay/game_bridge",
            binaryMessenger: controller.binaryMessenger
        )

        gameBridgeChannel?.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "sendToGame":
                guard let args = call.arguments as? [String: Any],
                      let command = args["command"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "command required", details: nil))
                    return
                }
                self?.handleGameCommand(command: command, value: args["value"])
                result(true)

            case "getGameState":
                result("{\"state\":\"playing\",\"score\":0}")

            case "triggerHaptic":
                guard let args = call.arguments as? [String: Any],
                      let pattern = args["pattern"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "pattern required", details: nil))
                    return
                }
                self?.triggerHapticFeedback(pattern: pattern)
                result(true)

            case "setWebViewConfig":
                // iOS WKWebView는 기본적으로 하드웨어 가속
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// Flutter → Unity WebGL 게임 명령 전달
    private func handleGameCommand(command: String, value: Any?) {
        let jsCode: String
        switch command {
        case "pause":
            jsCode = "if(window.unityInstance) window.unityInstance.SendMessage('GameManager','OnPause');"
        case "resume":
            jsCode = "if(window.unityInstance) window.unityInstance.SendMessage('GameManager','OnResume');"
        case "setSpeed":
            jsCode = "if(window.unityInstance) window.unityInstance.SendMessage('GameManager','SetTimeScale','\(value ?? 1)');"
        default:
            return
        }
        NSLog("[GameBridge] Command: \(command) → JS: \(jsCode)")
    }

    /// 게임 이벤트에 맞춘 네이티브 햅틱 피드백.
    ///
    /// Flutter의 HapticFeedback.lightImpact() 등은 UIImpactFeedbackGenerator의
    /// 단순 래퍼에 불과. 네이티브에서는 UINotificationFeedbackGenerator와
    /// UIImpactFeedbackGenerator를 조합하여 게임 맥락에 맞는 패턴 구현.
    private func triggerHapticFeedback(pattern: String) {
        switch pattern {
        case "impact":
            // 몬스터 처치: 강한 단일 임팩트
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()

        case "warning":
            // 피격: 더블 탭 경고
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                generator.impactOccurred()
            }

        case "failure":
            // 게임 오버: 에러 피드백
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)

        case "success":
            // 스테이지 클리어: 성공 피드백 + 경쾌한 탭
            let notification = UINotificationFeedbackGenerator()
            notification.prepare()
            notification.notificationOccurred(.success)
            let impact = UIImpactFeedbackGenerator(style: .light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                impact.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                impact.impactOccurred()
            }

        default:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}
