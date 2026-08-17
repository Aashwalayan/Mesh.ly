import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// A fake QR-code grid used until real QR generation is implemented.
///
/// This is purely decorative — it is not a scannable code.
class QrPlaceholder extends StatelessWidget {
  const QrPlaceholder({super.key});

  static const _pattern = [
    [1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0],
    [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0],
    [1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0],
    [1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1],
    [0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0],
    [0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1],
    [1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0],
    [0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1],
    [1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1],
    [0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0],
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12,
      ),
      itemCount: 144,
      itemBuilder: (context, index) {
        final row = index ~/ 12;
        final column = index % 12;
        final isFilled = _pattern[row][column] == 1;

        return Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isFilled ? AppColors.textPrimary : Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
