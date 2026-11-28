import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

import 'package:dlauncher/pages/settings/common/text_input_dialog.dart';
import 'package:dlauncher/services/background_service.dart';

/// 固定背景选择页：PageView 左右翻看背景图，第一项为「不使用背景」。
/// 背景按 16:9 展示，选中后把图片地址返回给设置页，空串表示不使用背景。
class BackgroundGalleryPage extends StatefulWidget {
  const BackgroundGalleryPage({super.key, required this.initialImage});

  /// 当前已选背景，用于进入时定位
  final String initialImage;

  @override
  State<BackgroundGalleryPage> createState() => _BackgroundGalleryPageState();
}

class _BackgroundGalleryPageState extends State<BackgroundGalleryPage> {
  /// 视口占比小于 1，让前后背景同时露出一部分
  static const _viewportFraction = 0.42;

  /// 空串代表「不使用背景」，固定在首位；其余来自服务器清单和本地资源
  List<String> _images = const [''];
  PageController? _pageController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// 每次进入都拉取服务器最新清单并覆盖首页缓存；失败时用旧缓存 + 本地资源兜底
  Future<void> _load() async {
    // 实时拉取成功后立即覆盖缓存，首页下次启动即用上新清单
    final remote = await BackgroundService.fetchImages();
    if (remote != null && remote.isNotEmpty) {
      await BackgroundService.saveImages(remote);
    }

    List<String> localImages = const [];
    try {
      localImages = await BackgroundService.loadLocalImages();
    } catch (_) {
      // 读取 asset 清单失败时仍可用服务器图，不影响选择页打开
    }
    final images = <String>[''];
    // 拉取成功用新清单，失败退回未覆盖的旧缓存
    for (final image in [
      ...(remote ?? BackgroundService.cachedImages),
      ...localImages,
    ]) {
      if (!images.contains(image)) images.add(image);
    }
    final initial = images.indexOf(widget.initialImage);
    if (!mounted) return;
    setState(() {
      _images = images;
      _current = initial < 0 ? 0 : initial;
      _pageController = PageController(
        initialPage: _current,
        viewportFraction: _viewportFraction,
      );
    });
  }

  /// 左右键翻页，确认键选中当前项；返回键交回系统由 GetX 弹栈（返回 null 即取消）
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (_pageController == null) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_current > 0) _goTo(_current - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (_current < _images.length - 1) _goTo(_current + 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _select(_images[_current]);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _goTo(int index) {
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _select(String image) => Get.back<String>(result: image);

  /// 保留手动填地址的能力，给无法从清单选到的图片用
  Future<void> _inputUrl() async {
    final value = await Get.dialog<String>(
      TextInputDialog(
        title: '输入图片地址',
        hint: 'http://... 或 assets/images/...',
        initial: widget.initialImage,
      ),
      barrierDismissible: false,
    );
    if (value != null && value.isNotEmpty) _select(value);
  }

  Widget _buildTile(int index) {
    final image = _images[index];
    final isNone = image.isEmpty;
    final current = index == _current;
    return Center(
      child: GestureDetector(
        onTap: () => _select(image),
        child: AnimatedScale(
          scale: current ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(3),
            // 选中光效参考卡片：外层柔光 + 中层光带 + 内层清晰白边
            decoration: current
                ? BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white54, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.7),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
            // 宽度取 PageView 视口宽，按 16:9 自动算高度
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: isNone
                    ? Container(
                        color: const Color(0xFF2A2A2A),
                        alignment: Alignment.center,
                        child: const Text(
                          '不使用背景',
                          style: TextStyle(color: Colors.white70, fontSize: 28),
                        ),
                      )
                    : image.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            memCacheHeight: 1080,
                            fadeInDuration: const Duration(milliseconds: 300),
                          )
                        : Image.asset(image, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _pageController;
    return Scaffold(
      appBar: AppBar(
        title: Text('选择背景 ${_current + 1}/${_images.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: '输入图片地址',
            onPressed: _inputUrl,
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: controller == null
            ? const Center(child: CircularProgressIndicator())
            : PageView.builder(
                controller: controller,
                itemCount: _images.length,
                onPageChanged: (index) => setState(() => _current = index),
                itemBuilder: (context, index) => _buildTile(index),
              ),
      ),
    );
  }
}
