import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/games_provider.dart';
import '../widgets/loading_widget.dart';

class WebViewScreen extends ConsumerStatefulWidget {
  final String id;

  const WebViewScreen({super.key, required this.id});

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _urlLoaded = false;
  bool _controllerNotified = false;
  final FocusNode _focusNode = FocusNode();

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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
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
          debugPrint('GameBridge: ${message.message}');
        },
      );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    // Show controller snackbar once
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
                    // Clamp within screen
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
