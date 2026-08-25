import 'package:flutter/material.dart';
import 'package:evaluapp/themes.dart';

class NoteDisplayOnly extends StatelessWidget {
  const NoteDisplayOnly({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    final double roundedValue =
        value == 0 ? 0 : (double.tryParse(value.toStringAsFixed(1)) ?? value);

    Color getColorForValue(double v) {
      if (v <= 0) {
        return colors.noteGrey;
      }
      if (v < 1.0) {
        // Meta ya alcanzada / requerimiento mínimo
        return colors.noteGreen;
      }
      if (v > 7.0) {
        // Meta inalcanzable
        return colors.noteRed;
      }
      if (v < 4.0) {
        return colors.noteRed;
      }
      return colors.noteGreen;
    }

    String getTextForValue(double v) {
      if (v <= 0) {
        return '-';
      }
      if (v > 0 && v < 1.0) {
        return '1.0'; // Con la nota mínima posible en la escala aprueba
      }
      if (v > 7.0) {
        return '>7.0'; // Requerimiento superior al máximo posible
      }
      return v.toStringAsFixed(1);
    }

    Color getTextColorForValue(double v) {
      return colors.noteBadgeTextLight;
    }

    return Container(
      width: 50,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: getColorForValue(roundedValue),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        getTextForValue(roundedValue),
        style: TextStyle(
          color: getTextColorForValue(roundedValue),
          fontSize: (roundedValue > 7.0) ? 14 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
