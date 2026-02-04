class Placement {
  final String id;
  final String creatureId;
  final String imagePath;
  final double x, y, scale, rotation;
  final int zIndex;

  Placement({
    required this.id,
    required this.creatureId,
    required this.imagePath,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.zIndex,
  });

  factory Placement.fromMap(String id, Map<String, dynamic> m) {
    return Placement(
      id: id,
      creatureId: m['creatureId'] as String,
      imagePath: m['imagePath'] as String,
      x: (m['x'] as num).toDouble(),
      y: (m['y'] as num).toDouble(),
      scale: (m['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (m['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: (m['zIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
