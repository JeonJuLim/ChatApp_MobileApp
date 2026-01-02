import 'package:flutter/material.dart';

class TagFilterBar extends StatelessWidget {
  final Function(String tagId) onTagSelected;

  const TagFilterBar({super.key, required this.onTagSelected});

  @override
  Widget build(BuildContext context) {
    final tags = ['work', 'urgent', 'family'];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tags
            .map(
              (tag) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(tag),
              onPressed: () => onTagSelected(tag),
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}
