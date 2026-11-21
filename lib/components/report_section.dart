import 'package:flutter/material.dart';
import '../atoms/app_card.dart';
import '../atoms/bullet_text.dart';
import '../atoms/card_title.dart';

class ReportSection extends StatelessWidget {
  const ReportSection({super.key, required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [CardTitle(title), for (final i in items) BulletText(i)],
        ),
      ),
    );
  }
}
