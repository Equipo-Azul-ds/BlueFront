
import 'package:flutter/material.dart';
import '../../domain/entities/kahoot.dart';
import '../widget/kahootListItem.dart';

List<Widget> buildKahootWidgets(BuildContext context, List<Kahoot> kahoots) {
  return kahoots.asMap().entries.map((entry) {
    int index = entry.key;
    Kahoot kahoot = entry.value;

    return SizedBox(
      width: 250,
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: KahootListItem(
          number: (index + 1).toString(),
          kahoot: kahoot,
          onTap: () {
            Navigator.of(context).pushNamed(
              '/kahoot-detail',
              arguments: kahoot.id,
            );
          },
        ),
      ),
    );
  }).toList();
}