import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evaluapp/themes.dart';

import 'package:evaluapp/data_model/model.dart';

import 'package:flutter/gestures.dart';

class _AlwaysWinLongPressRecognizer extends LongPressGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class Note extends StatefulWidget {
  const Note({
    super.key,
    required this.iValue,
    required this.label,
    required this.isActive,
    required this.idxNote,
    required this.onNoteLostFocusCB,
    this.evaluationDetail,
    this.onLongPress,
  });

  final double iValue;
  final String label;
  final bool isActive;
  final int idxNote;
  final void Function(int position, double newNote) onNoteLostFocusCB;
  final EvaluationDetail? evaluationDetail;
  final VoidCallback? onLongPress;

  @override
  State<StatefulWidget> createState() {
    return _NoteState();
  }
}

class _NoteState extends State<Note> {
  final _noteTextController = TextEditingController();
  late Color _textColor;

  @override
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  void _syncControllerWithProps(AppColors colors) {
    if (widget.iValue > 0) {
      _noteTextController.text = widget.iValue.toStringAsFixed(1);
      _textColor =
          (widget.iValue < 4.0) ? colors.noteFailColor : colors.notePassColor;
    } else {
      _noteTextController.text = '';
      _textColor = colors.notePassColor;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colors = ThemeProvider.of(context)!.colors;
    _syncControllerWithProps(colors);
  }

  @override
  void didUpdateWidget(Note oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iValue != widget.iValue) {
      final colors = ThemeProvider.of(context)!.colors;
      _syncControllerWithProps(colors);
    }
  }

  void _checkTxtChange(String value) {
    final colors = ThemeProvider.of(context)!.colors;
    setState(() {
      if (value.isNotEmpty) {
        final clean = value.replaceAll(',', '.');
        final parsed = double.tryParse(clean);
        if (parsed != null) {
          final firstDigit = (parsed >= 10) ? parsed / 10 : parsed;
          _textColor =
              (firstDigit < 4.0) ? colors.noteFailColor : colors.notePassColor;
        } else {
          final firstChar = double.tryParse(value[0]);
          if (firstChar != null && firstChar < 4.0) {
            _textColor = colors.noteFailColor;
          } else {
            _textColor = colors.notePassColor;
          }
        }
      }
    });
  }

  void _onNoteLostFocus() {
    final rawText = _noteTextController.text.trim();
    final cleanValue = rawText.replaceAll(',', '.');
    double value = 0;

    if (cleanValue.isNotEmpty) {
      final parsed = double.tryParse(cleanValue);
      if (parsed != null) {
        if (parsed >= 1.0 && parsed <= 7.0) {
          value = parsed;
        } else if (parsed >= 10.0 && parsed <= 70.0) {
          value = parsed / 10.0;
        }
      }
    }

    setState(() {
      final colors = ThemeProvider.of(context)!.colors;
      if (value > 0) {
        _noteTextController.text = value.toStringAsFixed(1);
        _textColor =
            (value < 4.0) ? colors.noteFailColor : colors.notePassColor;
      } else {
        _noteTextController.text = '';
        _textColor = colors.notePassColor;
      }
      widget.onNoteLostFocusCB(widget.idxNote, value);
    });
  }

  Color _getIndicatorColor(int level) {
    if (level <= 3) {
      return const Color(0xFFEF4444); // Rojo (crítico/bajo)
    } else if (level <= 5) {
      return const Color(0xFFEAB308); // Ámbar/Amarillo (medio)
    } else {
      return const Color(0xFF3B82F6); // Azul (alto/excelente)
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;
    final hasDetail = widget.evaluationDetail?.hasData ?? false;
    final dotColor = hasDetail
        ? _getIndicatorColor(widget.evaluationDetail!.confidenceLevel)
        : Colors.transparent;

    Widget content = widget.isActive
        ? Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                _onNoteLostFocus();
              }
            },
            child: TextField(
              enableInteractiveSelection: false,
              onChanged: _checkTxtChange,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              controller: _noteTextController,
              maxLength: 4,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.noteFieldBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: colors.noteFieldBorder, width: 2)),
                labelText: widget.label,
                labelStyle:
                    TextStyle(color: colors.dimensionCardText, fontSize: 11),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                counterText: '',
              ),
            ),
          )
        : Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                  width: 1,
                  color: colors.noteFieldBorder,
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
          );

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        _AlwaysWinLongPressRecognizer:
            GestureRecognizerFactoryWithHandlers<_AlwaysWinLongPressRecognizer>(
          () => _AlwaysWinLongPressRecognizer(),
          (_AlwaysWinLongPressRecognizer instance) {
            instance.onLongPress = widget.onLongPress;
          },
        ),
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (hasDetail)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.6),
                      blurRadius: 3,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
