import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Full-screen web view used to replace the native UI when the backend
/// returns a `steer` URL on startup (same behavior as the uni-app version).
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.url});

  final String url;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  final ImagePicker _imagePicker = ImagePicker();
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    _setupAndroidWebView();
  }

  /// Configures Android-specific WebView behavior.
  ///
  /// - Registers the file selector callback; without it the WebView silently
  ///   ignores `<input type="file">` (iOS handles file inputs natively).
  /// - Makes the WebView ignore system-bar insets. Flutter's [SafeArea]
  ///   already keeps the view clear of the status/navigation bars, but newer
  ///   Android WebViews also report those insets to the page, so H5 layouts
  ///   add extra bottom padding (e.g. a Vant tab bar becomes too tall on some
  ///   devices such as the Redmi A3).
  Future<void> _setupAndroidWebView() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final androidController =
          _controller.platform as AndroidWebViewController;
      await androidController.setOnShowFileSelector(_androidFileSelector);
      await androidController.setInsetsForWebContentToIgnore(
        const [AndroidWebViewInsets.systemBars],
      );
      debugPrint('[WebView] Android WebView configured');
    } catch (error, stackTrace) {
      debugPrint(
          '[WebView] Failed to configure Android WebView: $error\n$stackTrace');
    }
  }

  /// Opens the system photo picker and hands the picked file path(s) back to
  /// the web page. Returning an empty list cancels the upload.
  Future<List<String>> _androidFileSelector(FileSelectorParams params) async {
    debugPrint('[WebView] File selector requested: '
        'mode=${params.mode}, capture=${params.isCaptureEnabled}');
    try {
      final List<XFile> files;
      if (params.mode == FileSelectorMode.openMultiple) {
        files = await _imagePicker.pickMultiImage();
      } else {
        final XFile? file = await _imagePicker.pickImage(
          source: params.isCaptureEnabled
              ? ImageSource.camera
              : ImageSource.gallery,
        );
        files = file == null ? const [] : [file];
      }
      final uris = files.map((file) => Uri.file(file.path).toString()).toList();
      debugPrint('[WebView] File selector result: $uris');
      return uris;
    } catch (error, stackTrace) {
      debugPrint('[WebView] File selector error: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('选择照片失败，请重试')),
        );
      }
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_progress < 100)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(value: _progress / 100),
              ),
          ],
        ),
      ),
    );
  }
}
