import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Simple avatar picker for students using DiceBear (free avatars).
/// Returns a selected image URL via Navigator.pop<String>(context, url).
class AvatarPickerPage extends StatefulWidget {
  const AvatarPickerPage({super.key});

  @override
  State<AvatarPickerPage> createState() => _AvatarPickerPageState();
}

class _AvatarPickerPageState extends State<AvatarPickerPage> {
  static const List<String> _seeds = [
    'tiger','fox','wolf','racoon','panda','frog','owl','eagle','penguin','dove',
    'bear','moose','dog','cat','rabbit','koala','goat','unicorn','dragon','yak',
    'monster','pink','brain','blue','skeleton','earth','lion','elephant','deer','otter',
  ];

  String _urlForSeed(String seed) {
    // DiceBear v7 micah PNG avatars
    return 'https://api.dicebear.com/7.x/micah/png?seed=$seed&background=%23ffffff&size=128';
  }

  void _select(String seed) {
    Navigator.of(context).pop<String>(seed); // Devuelve solo el seed
  }

  void _randomSelect() {
    final r = Random();
    final seed = _seeds[r.nextInt(_seeds.length)];
    _select(seed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu avatar')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Toca para seleccionar uno. Puedes cambiarlo después.',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                TextButton.icon(
                  onPressed: _randomSelect,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Aleatorio'),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _seeds.length,
              itemBuilder: (context, index) {
                final seed = _seeds[index];
                final url = _urlForSeed(seed);
                return InkWell(
                  onTap: () => _select(seed),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 120),
                          fadeOutDuration: const Duration(milliseconds: 80),
                          placeholder: (context, _) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, _, __) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
