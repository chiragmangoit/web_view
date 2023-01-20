import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
      );
  await Permission.storage.request();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();
  final ReceivePort _port = ReceivePort();
  InAppWebViewController? webView;
  List? languages;

  @override
  void initState() {
    getCurrentLanguage();
    super.initState();
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      // final language = getCurrentLanguage();
      // print("Current language: $language");

      setState(() {});
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  getCurrentLanguage() async {
    languages = await Devicelocale.preferredLanguages;
    String? locale = await Devicelocale.currentLocale;
    print("Current language: $languages");
    // return Localizations.localeOf(context).languageCode;
  }

  @override
  void dispose() {
    super.dispose();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: const <Locale>[
        Locale('de'),
        Locale('en'),
        Locale('es'),
        Locale('tr'),
        Locale('it'),
        Locale('sp'),
      ],
      home: WillPopScope(
        onWillPop: () async {
          // detect Android back button click
          final controller = webView;
          if (controller != null) {
            if (await controller.canGoBack()) {
              controller.goBack();
              return false;
            }
          }
          return true;
        },
        child: Scaffold(
            body: SafeArea(
          child: InAppWebView(
            key: webViewKey,
            initialUrlRequest:
                URLRequest(url: WebUri('http://vcloud.mangoitsol.com/login')),
            initialSettings: InAppWebViewSettings(
                allowsBackForwardNavigationGestures: true,
                useOnDownloadStart: true),
            onWebViewCreated: (InAppWebViewController controller) {
              webView = controller;
            },
            onDownloadStartRequest: (controller, url) async {
              print("onDownloadStart $url");
              final taskId = await FlutterDownloader.enqueue(
                url: url.url.toString(),
                savedDir: (await getExternalStorageDirectory())!.path,
                // saveInPublicStorage: true,
                showNotification: true,
                // show download progress in status bar (for Android)
                openFileFromNotification:
                    true, // click on notification to open downloaded file (for Android)
              );
            },
            onLoadStart: (controller, url) {
              controller.evaluateJavascript(
                  source:
                      "window.localStorage.setItem('language', '${languages![0].substring(0, 2)}')");
            },
          ),
        )),
      ),
    );
  }
}
