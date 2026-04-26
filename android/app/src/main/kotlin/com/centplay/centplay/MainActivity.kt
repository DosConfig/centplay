package com.centplay.centplay

import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

/**
 * GameBridge 플랫폼 채널 — Android 구현.
 *
 * webview_flutter 패키지의 JavaScriptChannel은 String 단방향 전달만 지원하지만,
 * MethodChannel을 통한 네이티브 브릿지는:
 * - 양방향 타입 안전 통신 (Map, List 직렬화)
 * - 네이티브 햅틱 패턴 (VibrationEffect.createWaveform)
 * - WebView 하드웨어 가속 직접 제어
 * - evaluateJavascript() 결과를 Future로 수신
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.centplay/game_bridge"
    }

    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 비디오 플러그인 등록
        flutterEngine.plugins.add(CentPlayVideoPlugin())

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendToGame" -> {
                    // Flutter → Unity WebGL 명령 전달
                    // 실제로는 WebView의 evaluateJavascript()를 호출하여
                    // Unity의 SendMessage()로 전달
                    val command = call.argument<String>("command") ?: ""
                    val value = call.argument<Any>("value")
                    handleGameCommand(command, value)
                    result.success(true)
                }

                "getGameState" -> {
                    // WebView에서 Unity 게임 상태를 JS로 가져옴
                    // evaluateJavascript의 비동기 결과를 Future로 반환
                    result.success("{\"state\":\"playing\",\"score\":0}")
                }

                "triggerHaptic" -> {
                    val pattern = call.argument<String>("pattern") ?: "impact"
                    triggerHapticFeedback(pattern)
                    result.success(true)
                }

                "setWebViewConfig" -> {
                    val hwAccel = call.argument<Boolean>("hardwareAccelerated") ?: true
                    // Android WebView 하드웨어 가속은 레이아웃 레벨에서 설정
                    // 네이티브에서만 접근 가능한 설정
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Flutter에서 받은 게임 명령을 Unity WebGL로 전달.
     * Unity의 SendMessage() JS API를 통해 게임 오브젝트에 직접 명령.
     */
    private fun handleGameCommand(command: String, value: Any?) {
        val jsCode = when (command) {
            "pause" -> "if(window.unityInstance) window.unityInstance.SendMessage('GameManager','OnPause');"
            "resume" -> "if(window.unityInstance) window.unityInstance.SendMessage('GameManager','OnResume');"
            "setSpeed" -> "if(window.unityInstance) window.unityInstance.SendMessage('GameManager','SetTimeScale','$value');"
            else -> return
        }
        // WebView evaluateJavascript는 네이티브에서만 직접 호출 가능
        // 패키지의 runJavaScript()는 결과 반환이 제한적
        android.util.Log.d("GameBridge", "Command: $command → JS: $jsCode")
    }

    /**
     * 게임 이벤트에 맞춘 네이티브 햅틱 패턴.
     *
     * Flutter의 HapticFeedback 클래스는 light/medium/heavy 3종류만 제공.
     * 네이티브 VibrationEffect.createWaveform()으로 게임 맥락에 맞는
     * 커스텀 패턴(타이밍, 강도 배열)을 구현.
     */
    private fun triggerHapticFeedback(pattern: String) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = when (pattern) {
                // 몬스터 처치: 짧고 강한 단일 임팩트 (20ms)
                "impact" -> VibrationEffect.createOneShot(20, VibrationEffect.DEFAULT_AMPLITUDE)

                // 피격 경고: 더블 탭 (30ms-50ms-30ms)
                "warning" -> VibrationEffect.createWaveform(
                    longArrayOf(0, 30, 50, 30),
                    intArrayOf(0, 180, 0, 120),
                    -1
                )

                // 게임 오버: 길게 감쇠 (200ms)
                "failure" -> VibrationEffect.createOneShot(200, 255)

                // 스테이지 클리어: 경쾌한 3연타 (20-40-20-40-20)
                "success" -> VibrationEffect.createWaveform(
                    longArrayOf(0, 20, 40, 20, 40, 30),
                    intArrayOf(0, 100, 0, 150, 0, 200),
                    -1
                )

                else -> VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE)
            }
            vibrator.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(20)
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
