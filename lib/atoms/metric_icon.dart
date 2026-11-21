import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class MetricIcon extends StatelessWidget {
  const MetricIcon({super.key, required this.metric, this.size = 36});

  final Metric metric;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(metric.icon, color: metric.color, size: size * 0.55),
    );
  }
}
