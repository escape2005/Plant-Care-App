// lib/components/section_heading.dart
import 'package:flutter/material.dart';

class SectionHeading extends StatelessWidget {
  final Widget title;
  const SectionHeading({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
          child: title,
        ),
      ),
    );
  }
}
