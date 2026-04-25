import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/games_provider.dart';
import '../services/game_bridge_service.dart';
import '../widgets/loading_widget.dart';

class WebViewScreen extends ConsumerStatefulWidget {
  final String id;

  const WebViewScreen({super.key, required this.id});

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen>
    with WidgetsBindingObserver {
  late WebViewController _controller;
  final GameBridgeService _bridge = GameBridgeService();
  bool _isLoading = true;
  bool _urlLoaded = false;
  bool _controllerNotified = false;
  final FocusNode _focusNode = FocusNode();

  // 게임 상태 (플랫폼 채널로 수신)
  String _gameState = 'loading';
  int _score = 0;

  // Draggable exit button position
  Offset _exitButtonPos = const Offset(20, 60);

  static final _keyMap = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.arrowUp: 'ArrowUp',
    LogicalKeyboardKey.arrowDown: 'ArrowDown',
    LogicalKeyboardKey.arrowLeft: 'ArrowLeft',
    LogicalKeyboardKey.arrowRight: 'ArrowRight',
    LogicalKeyboardKey.space: ' ',
    LogicalKeyboardKey.enter: 'Enter',
    LogicalKeyboardKey.escape: 'Escape',
    LogicalKeyboardKey.keyW: 'ArrowUp',
    LogicalKeyboardKey.keyA: 'ArrowLeft',
    LogicalKeyboardKey.keyS: 'ArrowDown',
    LogicalKeyboardKey.keyD: 'ArrowRight',
    LogicalKeyboardKey.gameButtonA: ' ',
    LogicalKeyboardKey.gameButtonB: 'Escape',
    LogicalKeyboardKey.gameButtonStart: 'Enter',
    LogicalKeyboardKey.gameButtonSelect: 'Escape',
    LogicalKeyboardKey.gameButtonLeft1: 'q',
    LogicalKeyboardKey.gameButtonRight1: 'e',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // GameBridge 이벤트 리스너 — 플랫폼 채널로 게임 이벤트 수신
    _bridge.onGameEvent = _handleGameEvent;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          // Unity WebGL 로드 완료 시 뷰포트 최적화
          _controller.runJavaScript('''
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
              meta = document.createElement('meta');
              meta.name = 'viewport';
              document.head.appendChild(meta);
            }
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.body.style.margin = '0';
            document.body.style.padding = '0';
            document.body.style.overflow = 'hidden';
            var canvas = document.querySelector('canvas');
            if (canvas) {
              canvas.style.width = '100vw';
              canvas.style.height = '100vh';
              canvas.style.objectFit = 'contain';
            }
          ''');
          setState(() => _isLoading = false);
        },
      ))
      ..addJavaScriptChannel(
        'GameBridge',
        onMessageReceived: (message) {
          // JS → Dart 경로 (webview_flutter 패키지 채널)
          // 이 메시지를 네이티브 MethodChannel로 포워딩하여
          // 햅틱 등 네이티브 기능을 트리거
          debugPrint('[GameBridge JS] ${message.message}');
        },
      );
  }

  /// 플랫폼 채널로 수신된 게임 이벤트 처리
  void _handleGameEvent(GameEvent event) {
    if (!mounted) return;

    setState(() {
      _gameState = event.type;
      if (event.data.containsKey('score')) {
        _score = event.data['score'] as int? ?? _score;
      }
    });

    // 게임 오버 시 결과 다이얼로그
    if (event.type == 'game_over') {
      _showGameOverDialog();
    }
  }

  /// 앱 라이프사이클 — 백그라운드 진입 시 게임 자동 일시정지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 플랫폼 채널로 네이티브 레벨에서 게임 일시정지
        _bridge.pauseGame();
        break;
      case AppLifecycleState.resumed:
        _bridge.resumeGame();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bridge.onGameEvent = null;
    _focusNode.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!_controllerNotified && mounted) {
      _controllerNotified = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.gamepad, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('컨트롤러 연결됨'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    final jsKey = _keyMap[event.logicalKey];
    if (jsKey == null) return;

    final eventType = event is KeyDownEvent ? 'keydown' : 'keyup';
    _controller.runJavaScript('''
      document.dispatchEvent(new KeyboardEvent('$eventType', {
        key: '$jsKey',
        code: '$jsKey',
        bubbles: true,
        cancelable: true
      }));
    ''');
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('게임 종료'),
        content: Text('점수: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('나가기'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.reload();
            },
            child: const Text('다시하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameByIdProvider(widget.id));

    if (game != null && game.webglUrl.isNotEmpty && !_urlLoaded) {
      _urlLoaded = true;
      _controller.loadRequest(Uri.parse(game.webglUrl));
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            // Full-screen WebView
            if (game == null || game.webglUrl.isEmpty)
              const Center(child: Text('게임 URL이 설정되지 않았습니다'))
            else
              WebViewWidget(controller: _controller),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black,
                child: const LoadingWidget(),
              ),

            // Draggable floating exit button
            Positioned(
              left: _exitButtonPos.dx,
              top: _exitButtonPos.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _exitButtonPos += details.delta;
                    final size = MediaQuery.of(context).size;
                    _exitButtonPos = Offset(
                      _exitButtonPos.dx.clamp(0, size.width - 48),
                      _exitButtonPos.dy.clamp(0, size.height - 48),
                    );
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
