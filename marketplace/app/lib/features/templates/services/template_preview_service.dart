import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TemplatePreviewService {
  late final WebViewController _controller;
  final _ready = Completer<void>();

  Future<void> init() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!_ready.isCompleted) _ready.complete();
          },
        ),
      )
      ..loadHtmlString(_initialHtml());
  }

  WebViewWidget buildWebView() {
    return WebViewWidget(controller: _controller);
  }

  Future<void> injectCSS(String css) async {
    await _ready.future;
    final escaped = css.replaceAll('`', '\\`');
    await _controller.runJavaScript('''
      (function(){
        let style = document.getElementById('dynamic-style');
        if(!style){
          style = document.createElement('style');
          style.id = 'dynamic-style';
          document.head.appendChild(style);
        }
        style.innerHTML = ` ${escaped} `;
      })();
    ''');
  }

  Future<void> setViewport(String mode) async {
    await _ready.future;
    // mode: 'mobile' | 'desktop'
    final width = mode == 'mobile' ? 390 : 1200;
    await _controller.runJavaScript('''
      (function(){
        const meta = document.querySelector('meta[name="viewport"]') || (function(){
          const m = document.createElement('meta');
          m.name='viewport'; document.head.appendChild(m); return m;})();
        meta.setAttribute('content', 'width=$width, initial-scale=1.0');
      })();
    ''');
  }

  String _initialHtml() {
    return '''
<!doctype html>
<html lang="fr">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=390, initial-scale=1.0" />
    <style id="dynamic-style">body{font-family: -apple-system, Roboto, Arial, sans-serif; padding: 12px}</style>
  </head>
  <body>
    <div class="header">Template Preview</div>
    <div class="content">Votre contenu apparaîtra ici.</div>
  </body>
</html>
''';
  }
}





