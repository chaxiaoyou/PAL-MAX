import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Color _pageBackground = Colors.white;

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
          onPageFinished: (_) {
            _syncStatusBarStyle();
            _resetPageSafeArea();
          },
          onUrlChange: (_) => _syncStatusBarStyle(),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    _setupAndroidWebView();
  }

  /// Some Android WebViews still report `env(safe-area-inset-*)` to the page
  /// even after [AndroidWebViewController.setInsetsForWebContentToIgnore],
  /// which makes the H5 top nav / tab bar grow by the system bar heights (e.g.
  /// doubled on Redmi A3). Force the page's safe-area paddings to zero via
  /// injected CSS/JS as a reliable fallback. The bars themselves are handled
  /// natively by [SafeArea] (top always; bottom only on 3-button-nav devices).
  Future<void> _resetPageSafeArea() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _controller.runJavaScript(
        '(function(){'
        'if (document.getElementById("__safeAreaReset__")) return;'
        'var style = document.createElement("style");'
        'style.id = "__safeAreaReset__";'
        'style.textContent = ['
        '  ":root{--safe-top:0px !important;--safe-bottom:0px !important}",'
        '  "body{padding-top:0 !important;padding-bottom:0 !important}",'
        '  ".van-tabbar{padding-bottom:0 !important}",'
        '  ".van-tabbar__placeholder{padding-bottom:0 !important}",'
        '  ".van-popup--safe-area-inset-bottom{padding-bottom:0 !important}"'
        '].join("\\n");'
        'document.head.appendChild(style);'
        'function resetNav(){'
        '  document.querySelectorAll(".van-nav-bar").forEach(function(el){'
        '    el.style.setProperty("padding-top", "0px", "important");'
        '  });'
        '}'
        'resetNav();'
        'new MutationObserver(resetNav).observe('
        '  document.body, {childList: true, subtree: true}'
        ');'
        '})()',
      );
    } catch (error, stackTrace) {
      debugPrint('[WebView] Safe-area reset failed: $error\n$stackTrace');
    }
  }

  /// Reads the web page's background color and paints the status bar area
  /// with it, choosing light/dark status bar icons to stay readable.
  Future<void> _syncStatusBarStyle() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        '(function(){'
        'function bg(el){return el ? getComputedStyle(el).backgroundColor : "";}'
        'var c = bg(document.body);'
        'if (!c || c === "transparent" || c === "rgba(0, 0, 0, 0)") {'
        '  c = bg(document.documentElement);'
        '}'
        'return c;'
        '})()',
      );
      final color = _parseCssColor(result is String ? result : '');
      if (color == null || !mounted) return;
      final dark = color.computeLuminance() < 0.5;
      setState(() => _pageBackground = color);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[WebView] Status bar sync failed: $error\n$stackTrace');
    }
  }

  /// Parses a CSS color string like `rgb(22, 26, 30)` or `rgba(...)`.
  Color? _parseCssColor(String raw) {
    final cleaned = raw.replaceAll('"', '').trim();
    final match = RegExp(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)')
        .firstMatch(cleaned);
    if (match == null) return null;
    return Color.fromARGB(
      255,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  /// Configures Android-specific WebView behavior.
  ///
  /// - Registers the file selector callback; without it the WebView silently
  ///   ignores `<input type="file">` (iOS handles file inputs natively).
  /// - Makes the WebView ignore system-bar insets. Flutter's [SafeArea]
  ///   already keeps the view clear of the status/navigation bars, but newer
  ///   Android WebViews also report those insets to the page, so H5 layouts
  ///   add extra top/bottom padding (e.g. a Vant tab bar becomes too tall on
  ///   some devices such as the Redmi A3).
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
    // Devices with a 3-button navigation bar report a clearly taller bottom
    // inset (~48dp) than gesture navigation (~24dp or less). Reserve the
    // bottom height on those devices so the H5 tab bar isn't covered by the
    // system bar; gesture-nav devices keep the full-screen look.
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bool reserveBottom =
        defaultTargetPlatform == TargetPlatform.android && bottomInset >= 36;

    return Scaffold(
      // The status bar height is reserved on top and painted with the web
      // page's background color (visible through the transparent status bar);
      // the bottom system bar is only reserved on 3-button-nav devices.
      backgroundColor: _pageBackground,
      body: SafeArea(
        top: true,
        bottom: reserveBottom,
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
