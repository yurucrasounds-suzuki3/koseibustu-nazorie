import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/creature_defs.dart';
import '../state/app_state.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/trace_canvas.dart';
import 'field_screen.dart';

class TraceScreen extends StatefulWidget {
  final String creatureId;
  const TraceScreen({super.key, required this.creatureId});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  final controller = TraceCanvasController();
  final repaintKey = GlobalKey(); // RepaintBoundary 用
  TraceResult? lastResult;
  bool saving = false;

  final fs = FirestoreService();
  final st = StorageService();

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final uid = app.auth.currentUser!.uid;

    final creature = creatures.firstWhere((c) => c.id == widget.creatureId);

    return Scaffold(
      appBar: AppBar(
        title: Text(creature.name),
        actions: [
          IconButton(
            onPressed: saving ? null : () => controller.clear(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // 進捗バー
          _ProgressBar(result: lastResult),

          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 2 / 3, // だいたいカード縦比率（好みで）
                child: RepaintBoundary(
                  key: repaintKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 下絵
                      Opacity(
                        opacity: 0.25,
                        child: Image.asset(
                          creature.templateAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // なぞり線 + チェックポイント
                      TraceCanvas(
                        templateAsset: creature.templateAsset,
                        checkpoints: creature.checkpoints,
                        hitRadius: creature.hitRadius,
                        clearRate: creature.clearRate,
                        controller: controller,
                        onProgress: (r) => setState(() => lastResult = r),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (saving || !(lastResult?.cleared ?? false))
                        ? null
                        : () => _saveAndGoField(uid, creature.id),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      (lastResult?.cleared ?? false) ? 'できた！フィールドへ' : 'もうちょい！',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndGoField(String uid, String creatureId) async {
    setState(() => saving = true);
    try {
      await fs.ensureUserDoc(uid);

      // RepaintBoundary を PNG bytes に
      final boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Storage へアップロード
      final placementId = const Uuid().v4();
      final path = 'users/$uid/drawings/$creatureId/$placementId.png';
      await st.uploadPngBytes(path: path, bytes: pngBytes);

      // Firestore：アンロック + 配置を追加（初期位置は中央）
      await fs.unlockCreature(uid, creatureId);
      await fs.addPlacement(
        uid: uid,
        fieldId: 'default',
        placementId: placementId,
        creatureId: creatureId,
        imagePath: path,
        x: 0.5,
        y: 0.6,
        scale: 1.0,
        rotation: 0.0,
        zIndex: DateTime.now().millisecondsSinceEpoch,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FieldScreen()),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final TraceResult? result;
  const _ProgressBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final total = r?.total ?? 0;
    final hit = r?.hitCount ?? 0;
    final ratio = (total == 0) ? 0.0 : (hit / total).clamp(0.0, 1.0);
    final cleared = r?.cleared ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0 ? 'なぞってね' : 'チェック：$hit / $total',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio,
              backgroundColor: Colors.black12,
            ),
          ),
          const SizedBox(height: 8),
          if (total > 0)
            Text(
              cleared ? 'クリア！' : 'あと少し！',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cleared ? Colors.green : Colors.orange,
              ),
            ),
        ],
      ),
    );
  }
}
