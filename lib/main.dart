import 'dart:async';
import 'dart:io'; // Add this import.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(
    const MaterialApp(
      home: WebViewApp(),
    ),
  );
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

late WebViewController controllerGlobal;

Future<bool> _exitApp(BuildContext context) async {
  if (await controllerGlobal.canGoBack()) {
    print("onwill goback");
    controllerGlobal.goBack();
    return Future.value(false);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No back history item")),
    );
    return Future.value(false);
  }
}

class _WebViewAppState extends State<WebViewApp> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  // Add from here ...
  @override
  void initState() {
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        body: SafeArea(
          child: WebView(
            initialUrl: 'http://vcloud.mangoitsol.com/login',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller.complete(webViewController);
            },
          ),
        ),
      ),
    );
  }
}
