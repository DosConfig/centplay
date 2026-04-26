package com.centplay.centplay

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.C
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

/**
 * CentPlay 네이티브 비디오 플레이어 — Android 구현.
 *
 * textureId 기반 멀티 인스턴스 — 여러 플레이어 동시 운용 가능.
 */
class CentPlayVideoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var textureRegistry: TextureRegistry
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private val players = mutableMapOf<Long, VideoPlayerInstance>()
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        textureRegistry = binding.textureRegistry

        methodChannel = MethodChannel(binding.binaryMessenger, "com.centplay/video_player")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.centplay/video_player/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        players.values.forEach { it.dispose() }
        players.clear()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "create") {
            val url = call.argument<String>("url")
            if (url == null) { result.error("INVALID_ARGS", "url required", null); return }

            val instance = VideoPlayerInstance(context, textureRegistry, url) { data ->
                mainHandler.post { eventSink?.success(data) }
            }
            players[instance.textureId] = instance
            result.success(mapOf("textureId" to instance.textureId))
            return
        }

        val tid = call.argument<Number>("textureId")?.toLong()
        val instance = if (tid != null) players[tid] else null

        if (call.method == "dispose") {
            instance?.dispose()
            if (tid != null) players.remove(tid)
            result.success(null)
            return
        }

        if (instance == null) {
            result.error("NOT_FOUND", "player not found", null)
            return
        }

        instance.handle(call, result)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { eventSink = events }
    override fun onCancel(arguments: Any?) { eventSink = null }
}

// =============================================================================
// 개별 플레이어 인스턴스
// =============================================================================

private class VideoPlayerInstance(
    context: Context,
    textureRegistry: TextureRegistry,
    url: String,
    private val onEvent: (Map<String, Any>) -> Unit,
) {
    val textureId: Long

    private val player: ExoPlayer
    private val trackSelector: DefaultTrackSelector
    private val textureEntry: TextureRegistry.SurfaceTextureEntry
    private val surface: Surface
    private val mainHandler = Handler(Looper.getMainLooper())

    private var positionRunnable: Runnable? = null
    private var lastPos: Long = -1
    private var hasEmittedInitialized = false

    init {
        trackSelector = DefaultTrackSelector(context)
        player = ExoPlayer.Builder(context).setTrackSelector(trackSelector).build()

        textureEntry = textureRegistry.createSurfaceTexture()
        textureId = textureEntry.id()
        surface = Surface(textureEntry.surfaceTexture())
        player.setVideoSurface(surface)

        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                when (state) {
                    Player.STATE_READY -> {
                        // bufferingEnd는 항상 보냄
                        emit(mapOf("event" to "bufferingEnd"))
                        // initialized는 최초 1회만
                        if (!hasEmittedInitialized) {
                            hasEmittedInitialized = true
                            val format = player.videoFormat
                            emit(mapOf(
                                "event" to "initialized",
                                "duration" to player.duration.toInt(),
                                "width" to (format?.width ?: 0),
                                "height" to (format?.height ?: 0),
                            ))
                        }
                    }
                    Player.STATE_BUFFERING -> emit(mapOf("event" to "buffering"))
                    Player.STATE_ENDED -> emit(mapOf("event" to "completed"))
                    else -> {}
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                emit(mapOf("event" to if (isPlaying) "playing" else "paused"))
            }

            override fun onPlayerError(error: PlaybackException) {
                emit(mapOf("event" to "error", "message" to (error.message ?: "Unknown error")))
            }
        })

        player.setMediaItem(MediaItem.fromUri(url))
        player.prepare()
        startPositionUpdates()
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> { player.play(); result.success(null) }
            "pause" -> { player.pause(); result.success(null) }
            "seekTo" -> {
                player.seekTo(call.argument<Int>("position")?.toLong() ?: 0)
                result.success(null)
            }
            "setPlaybackSpeed" -> {
                player.setPlaybackSpeed(call.argument<Double>("speed")?.toFloat() ?: 1f)
                result.success(null)
            }
            "setMaxBitrate" -> {
                val bitrate = call.argument<Int>("bitrate") ?: 0
                trackSelector.parameters = trackSelector.buildUponParameters()
                    .setMaxVideoBitrate(if (bitrate == 0) Int.MAX_VALUE else bitrate)
                    .build()
                result.success(null)
            }
            "getAvailableBitrates" -> {
                val bitrates = mutableSetOf<Int>()
                for (group in player.currentTracks.groups) {
                    if (group.type == C.TRACK_TYPE_VIDEO) {
                        for (i in 0 until group.length) {
                            val br = group.getTrackFormat(i).bitrate
                            if (br > 0) bitrates.add(br)
                        }
                    }
                }
                result.success(bitrates.sorted())
            }
            else -> result.notImplemented()
        }
    }

    private fun startPositionUpdates() {
        positionRunnable = object : Runnable {
            override fun run() {
                val pos = player.currentPosition
                if (pos != lastPos) {
                    lastPos = pos
                    emit(mapOf("event" to "position", "position" to pos.toInt()))
                }
                mainHandler.postDelayed(this, 100)
            }
        }
        mainHandler.post(positionRunnable!!)
    }

    private fun emit(data: Map<String, Any>) {
        val event = data.toMutableMap()
        event["textureId"] = textureId
        onEvent(event)
    }

    fun dispose() {
        positionRunnable?.let { mainHandler.removeCallbacks(it) }; positionRunnable = null
        player.release()
        surface.release()
        textureEntry.release()
    }
}
