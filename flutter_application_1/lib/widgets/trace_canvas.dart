import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/checkpoint.dart';

class TraceResult {
  final double clearRate;
  final int hitCount;
  final int total;
  final Set<int> hitIndexes;

  const TraceResult({
    required this.clearRate,
    required this.hitCount,
    required this.total,
    required this.hitIndexes,
  });

  bool get cleared => total > 0 && (hitCount / total) >= clearRate;
}

class TraceCanvasController extends ChangeNotifier {
  final points = <Offset?>[]; // nullでストローク区切り
  final Set<int> hitIndexes = {};

  void addPoint(Offset p) {
    points.add(p);
    notifyListeners();
  }

  void endStroke() {
    points.add(null);
    notifyListeners();
  }

  void clear() {
    points.clear();
    hitIndexes.clear();
    notifyListeners();
  }
}

class TraceCanvas extends StatelessWidget {
  final String templateAsset;
  final List<Checkpoint> checkpoints; // 0..1
  final double hitRadius; // 正規化
  final double clearRate; // 閾値
  final TraceCanvasController controller;
  final void Function(TraceResult result)? onProgress;

  const TraceCanvas({
    super.key,
    required this.templateAsset,
    required this.checkpoints,
    required this.hitRadius,
    required this.clearRate,
    required this.controller,
    this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);

      return GestureDetector(
        onPanStart: (d) => _handlePoint(d.localPosition, size),
        onPanUpdate: (d) => _handlePoint(d.localPosition, size),
        onPanEnd: (_) => controller.endStroke(),
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return CustomPaint(
              painter: _TracePainter(
                templateAsset: templateAsset,
                points: controller.points,
                checkpoints: checkpoints,
                hitIndexes: controller.hitIndexes,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      );
    });
  }

  void _handlePoint(Offset p, Size canvasSize) {
    controller.addPoint(p);

    // 判定：チェックポイント（正規化）→実座標にして距離判定
    for (int i = 0; i < checkpoints.length; i++) {
      if (controller.hitIndexes.contains(i)) continue;

      final cp = checkpoints[i];
      final cpPos = Offset(cp.x * canvasSize.width, cp.y * canvasSize.height);
      final r = hitRadius * canvasSize.shortestSide;

      if ((p - cpPos).distance <= r) {
        controller.hitIndexes.add(i);
      }
    }

    onProgress?.call(
      TraceResult(
        clearRate: clearRate,
        hitCount: controller.hitIndexes.length,
        total: checkpoints.length,
        hitIndexes: Set.of(controller.hitIndexes),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final String templateAsset;
  final List<Offset?> points;
  final List<Checkpoint> checkpoints;
  final Set<int> hitIndexes;

  _TracePainter({
    required this.templateAsset,
    required this.points,
    required this.checkpoints,
    required this.hitIndexes,
  });

  ui.Image? _templateImage;

  @override
  void paint(Canvas canvas, Size size) async {
    // 背景（テンプレ）描画：MVPは Image widget を下に敷いてもOK
    // ここでは簡略化して、CustomPaint上で描く代わりに TraceScreen 側でStackするのがおすすめ。
    // → この painter は線とデバッグ用cp表示だけに集中する。

    // 線
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool started = false;

    for (final pt in points) {
      if (pt == null) {
        started = false;
        continue;
      }
      if (!started) {
        path.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, paint);

    // （開発用）チェックポイント表示：当たりは緑、未当たりは白
    for (int i = 0; i < checkpoints.length; i++) {
      final cp = checkpoints[i];
      final pos = Offset(cp.x * size.width, cp.y * size.height);
      final p = Paint()
        ..color = hitIndexes.contains(i) ? Colors.greenAccent : Colors.white70;
      canvas.drawCircle(pos, 6, p);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.hitIndexes != hitIndexes;
  }
}
