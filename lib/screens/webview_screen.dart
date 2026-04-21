import 'package:flutter/material.dart';
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
      ));
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
