import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:lottie/lottie.dart';

class LottieHeader extends Header {
  final String assetName;

  const LottieHeader({
    required this.assetName,
    double triggerOffset = 100,
    Duration? completeDuration,
    bool hapticFeedback = false,
    bool safeArea = true,
    bool clamping = false,
    bool spring = false,
    bool frictionFactor = false,
    bool infiniteOffset = false,
    bool hitOver = true,
    bool infiniteHitOver = false,
    bool position = false,
  }) : super(
          triggerOffset: triggerOffset,
          clamping: clamping,
          hitOver: hitOver,
          infiniteHitOver: infiniteHitOver,
          position:
              position ? IndicatorPosition.locator : IndicatorPosition.above,
          hapticFeedback: hapticFeedback,
        );

  @override
  Widget build(BuildContext context, IndicatorState state) {
    final displayRatio = state.offset / state.triggerOffset;

    if (displayRatio >= 0.3 || state.mode == IndicatorMode.processing) {
      final opacity = ((displayRatio - 0.3) / 0.7).clamp(0.0, 1.0);
      return Opacity(
        opacity: state.mode == IndicatorMode.processing ? 1.0 : opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieBuilder.asset(
              assetName,
              animate: state.mode != IndicatorMode.inactive,
              width: 100 *
                  (state.mode == IndicatorMode.processing
                      ? 1.0
                      : displayRatio.clamp(0.3, 1.0)),
              height: 100 *
                  (state.mode == IndicatorMode.processing
                      ? 1.0
                      : displayRatio.clamp(0.3, 1.0)),
            ),
            const SizedBox(height: 10),
            Text(
              _getRefreshText(state.mode),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  String _getRefreshText(IndicatorMode mode) {
    switch (mode) {
      case IndicatorMode.drag:
        return '下拉刷新...';
      case IndicatorMode.armed:
        return '松开刷新...';
      case IndicatorMode.processing:
      case IndicatorMode.ready:
        return '正在努力加载中...';
      case IndicatorMode.processed:
        return '加载完毕';
      case IndicatorMode.done:
        return '溜了溜了...';
      default:
        return '';
    }
  }
}