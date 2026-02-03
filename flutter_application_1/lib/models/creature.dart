import 'checkpoint.dart';

class Creature {
  final String id;
  final String name;
  final String category; // "sea" | "land" | ...
  final String templateAsset; // 下絵PNG/SVG（MVPはPNGでOK）
  final List<Checkpoint> checkpoints;
  final double hitRadius; // 判定半径（正規化）
  final double clearRate; // 0..1 クリア閾値

  const Creature({
    required this.id,
    required this.name,
    required this.category,
    required this.templateAsset,
    required this.checkpoints,
    this.hitRadius = 0.05,
    this.clearRate = 0.6,
  });
}
