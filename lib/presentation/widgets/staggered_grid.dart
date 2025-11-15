import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class StaggeredGrid extends StatelessWidget {
  final List<Widget> children;

  const StaggeredGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
