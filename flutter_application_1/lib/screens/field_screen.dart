import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/placement.dart';
import '../state/app_state.dart';
import '../services/firestore_service.dart';
import 'catalog_screen.dart';

class FieldScreen extends StatelessWidget {
  const FieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final uid = app.auth.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    final placementsQuery = db
        .collection('users/$uid/fields/default/placements')
        .orderBy('zIndex', descending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイフィールド'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CatalogScreen()),
            ),
            icon: const Icon(Icons.menu_book),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: placementsQuery.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final placements = snap.data!.docs
              .map((d) => Placement.fromMap(d.id, d.data()))
              .toList();

          return _FieldCanvas(uid: uid, placements: placements);
        },
      ),
    );
  }
}

class _FieldCanvas extends StatefulWidget {
  final String uid;
  final List<Placement> placements;
  const _FieldCanvas({required this.uid, required this.placements});

  @override
  State<_FieldCanvas> createState() => _FieldCanvasState();
}

class _FieldCanvasState extends State<_FieldCanvas> {
  final fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);

      return Stack(
        children: [
          // 背景（MVPは固定画像でOK）
          Positioned.fill(
            child: Image.asset(
              'assets/fields/sea.png',
              fit: BoxFit.cover,
            ),
          ),

          // 住民たち
          for (final p in widget.placements)
            _DraggablePlacement(
              uid: widget.uid,
              placement: p,
              canvasSize: size,
              onMoved: (nx, ny) async {
                // 0..1に正規化して保存
                await FirebaseFirestore.instance
                    .doc('users/${widget.uid}/fields/default/placements/${p.id}')
                    .set({'x': nx, 'y': ny}, SetOptions(merge: true));
              },
            ),
        ],
      );
    });
  }
}

class _DraggablePlacement extends StatefulWidget {
  final String uid;
  final Placement placement;
  final Size canvasSize;
  final Future<void> Function(double nx, double ny) onMoved;

  const _DraggablePlacement({
    required this.uid,
    required this.placement,
    required this.canvasSize,
    required this.onMoved,
  });

  @override
  State<_DraggablePlacement> createState() => _DraggablePlacementState();
}

class _DraggablePlacementState extends State<_DraggablePlacement> {
  late double nx = widget.placement.x;
  late double ny = widget.placement.y;

  @override
  Widget build(BuildContext context) {
    final px = nx * widget.canvasSize.width;
    final py = ny * widget.canvasSize.height;

    final ref = FirebaseStorage.instance.ref(widget.placement.imagePath);

    return Positioned(
      left: px - 60,
      top: py - 60,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            final newPx = (px + d.delta.dx).clamp(0.0, widget.canvasSize.width);
            final newPy = (py + d.delta.dy).clamp(0.0, widget.canvasSize.height);
            nx = (newPx / widget.canvasSize.width);
            ny = (newPy / widget.canvasSize.height);
          });
        },
        onPanEnd: (_) => widget.onMoved(nx, ny),
        child: FutureBuilder<String>(
          future: ref.getDownloadURL(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox(width: 120, height: 120);
            }
            return Transform.rotate(
              angle: widget.placement.rotation,
              child: Transform.scale(
                scale: widget.placement.scale,
                child: Image.network(
                  snap.data!,
                  width: 120,
                  height: 120,
                  filterQuality: FilterQuality.high,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
