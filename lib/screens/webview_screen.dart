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
  bool _controllerConnected = false;
  final FocusNode _focusNode = FocusNode();

  // Keyboard + Gamepad key → JS key mapping
  static final _keyMap = <LogicalKeyboardKey, String>{
    // Arrow keys (keyboard & D-pad)
    LogicalKeyboardKey.arrowUp: 'ArrowUp',
    LogicalKeyboardKey.arrowDown: 'ArrowDown',
    LogicalKeyboardKey.arrowLeft: 'ArrowLeft',
    LogicalKeyboardKey.arrowRight: 'ArrowRight',
    // Common game keys
    LogicalKeyboardKey.space: ' ',
    LogicalKeyboardKey.enter: 'Enter',
    LogicalKeyboardKey.escape: 'Escape',
    // WASD
    LogicalKeyboardKey.keyW: 'ArrowUp',
    LogicalKeyboardKey.keyA: 'ArrowLeft',
    LogicalKeyboardKey.keyS: 'ArrowDown',
    LogicalKeyboardKey.keyD: 'ArrowRight',
    // Gamepad buttons (BT controller mapped by Flutter)
    LogicalKeyboardKey.gameButtonA: ' ',        // A → Space (confirm/jump)
    LogicalKeyboardKey.gameButtonB: 'Escape',   // B → Escape (back)
    LogicalKeyboardKey.gameButtonStart: 'Enter', // Start → Enter
    LogicalKeyboardKey.gameButtonSelect: 'Escape',
    // Shoulder buttons
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

    // Detect connected controllers
    _checkController();

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

  void _checkController() {
    // Flutter detects BT controllers as hardware keyboards
    final hasHardwareKeyboard = HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty;
    if (hasHardwareKeyboard && !_controllerConnected) {
      setState(() => _controllerConnected = true);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    // Detect controller connection
    if (!_controllerConnected) {
      setState(() => _controllerConnected = true);
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
    final title = game?.title ?? '게임';

    if (game != null && game.webglUrl.isNotEmpty && !_urlLoaded) {
      _urlLoaded = true;
      _controller.loadRequest(Uri.parse(game.webglUrl));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Controller status indicator
          if (_controllerConnected)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gamepad, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text('연결됨',
                      style: TextStyle(fontSize: 11, color: Colors.green)),
                ],
              ),
            ),
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop()),
        ],
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: game == null || game.webglUrl.isEmpty
            ? const Center(child: Text('게임 URL이 설정되지 않았습니다'))
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading) const LoadingWidget(),
                ],
              ),
      ),
    );
  }
}
