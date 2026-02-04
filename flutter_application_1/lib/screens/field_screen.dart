import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/placement.dart';
import '../state/app_state.dart';
import '../services/local_db_service.dart';
import 'catalog_screen.dart';

class FieldScreen extends StatelessWidget {
  const FieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return _FieldScreenBody(uid: app.uid);
  }
}

class _FieldScreenBody extends StatefulWidget {
  final String? uid;
  const _FieldScreenBody({required this.uid});

  @override
  State<_FieldScreenBody> createState() => _FieldScreenBodyState();
}

class _FieldScreenBodyState extends State<_FieldScreenBody> {
  final db = LocalDbService();
  List<Placement> placements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlacements();
  }

  Future<void> _loadPlacements() async {
    final data = await db.loadPlacements();
    if (!mounted) return;
    setState(() {
      placements = data
          .map((p) => Placement.fromMap(p['id'] as String, p))
          .toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _FieldCanvas(
              placements: placements,
              onPlacementUpdated: (id, nx, ny) async {
                await db.updatePlacement(id, {'x': nx, 'y': ny});
                if (!mounted) return;
                setState(() {
                  placements = [
                    for (final p in placements)
                      if (p.id == id)
                        Placement(
                          id: p.id,
                          creatureId: p.creatureId,
                          imagePath: p.imagePath,
                          x: nx,
                          y: ny,
                          scale: p.scale,
                          rotation: p.rotation,
                          zIndex: p.zIndex,
                        )
                      else
                        p,
                  ];
                });
              },
            ),
    );
  }
}

class _FieldCanvas extends StatefulWidget {
  final List<Placement> placements;
  final Future<void> Function(String id, double nx, double ny) onPlacementUpdated;
  const _FieldCanvas({
    required this.placements,
    required this.onPlacementUpdated,
  });

  @override
  State<_FieldCanvas> createState() => _FieldCanvasState();
}

class _FieldCanvasState extends State<_FieldCanvas> {
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
              placement: p,
              canvasSize: size,
              onMoved: (nx, ny) async {
                // 0..1に正規化して保存
                await widget.onPlacementUpdated(p.id, nx, ny);
              },
            ),
        ],
      );
    });
  }
}

class _DraggablePlacement extends StatefulWidget {
  final Placement placement;
  final Size canvasSize;
  final Future<void> Function(double nx, double ny) onMoved;

  const _DraggablePlacement({
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

    final imageFile = File(widget.placement.imagePath);

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
        child: Transform.rotate(
          angle: widget.placement.rotation,
          child: Transform.scale(
            scale: widget.placement.scale,
            child: Image.file(
              imageFile,
              width: 120,
              height: 120,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  const SizedBox(width: 120, height: 120),
            ),
          ),
        ),
      ),
    );
  }
}
