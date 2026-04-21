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

  @override
  void initState() {
    super.initState();
    // Landscape 허용
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          // viewport를 화면에 맞게 스케일링
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
      ));
  }

  @override
  void dispose() {
    // Portrait로 복원
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
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
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop()),
        ],
      ),
      body: game == null || game.webglUrl.isEmpty
          ? const Center(child: Text('게임 URL이 설정되지 않았습니다'))
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading) const LoadingWidget(),
              ],
            ),
    );
  }
}
