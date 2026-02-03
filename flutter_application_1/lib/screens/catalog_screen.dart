import 'package:flutter/material.dart';
import '../data/creature_defs.dart';
import 'trace_screen.dart';
import 'field_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('こせいぶつ ずかん'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FieldScreen()),
            ),
            icon: const Icon(Icons.landscape),
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: creatures.length,
        itemBuilder: (context, i) {
          final c = creatures[i];
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TraceScreen(creatureId: c.id)),
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: 0.9,
                        child: Image.asset(c.templateAsset, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
