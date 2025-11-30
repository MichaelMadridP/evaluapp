import 'package:flutter/material.dart';
import 'package:evaluapp/themes.dart';

class NoteDisplayOnly extends StatelessWidget {
  const NoteDisplayOnly({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    Color getColorForValue(double v) {
      if (v == 0) {
        return colors.noteGrey;
      }
      if (v < 4) {
        return colors.noteRed;
      }
      if (v >= 7) {
        return colors.noteYellow;
      }
      return colors.noteGreen;
    }

    return Container(
      width: 50,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: getColorForValue(value),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        value == 0 ? '-' : value.toStringAsFixed(1),
        style: TextStyle(
          color: colors.noteFieldText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
