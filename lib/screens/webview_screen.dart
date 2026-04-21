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
  final FocusNode _focusNode = FocusNode();

  // Key mapping: physical keyboard/gamepad → JS keydown events
  static final _keyMap = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.arrowUp: 'ArrowUp',
    LogicalKeyboardKey.arrowDown: 'ArrowDown',
    LogicalKeyboardKey.arrowLeft: 'ArrowLeft',
    LogicalKeyboardKey.arrowRight: 'ArrowRight',
    LogicalKeyboardKey.space: ' ',
    LogicalKeyboardKey.enter: 'Enter',
    LogicalKeyboardKey.escape: 'Escape',
    LogicalKeyboardKey.keyW: 'w',
    LogicalKeyboardKey.keyA: 'a',
    LogicalKeyboardKey.keyS: 's',
    LogicalKeyboardKey.keyD: 'd',
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for immersive gaming
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
          // Game → Flutter communication (e.g., score updates)
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
    final jsKey = _keyMap[event.logicalKey];
    if (jsKey == null) return;

    final eventType = event is KeyDownEvent ? 'keydown' : 'keyup';
    _controller.runJavaScript('''
      document.dispatchEvent(new KeyboardEvent('$eventType', {
        key: '$jsKey',
        bubbles: true
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
          // Gamepad indicator
          if (HardwareKeyboard.instance.logicalKeysPressed.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.gamepad, size: 20, color: Colors.green),
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
