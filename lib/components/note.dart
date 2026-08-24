import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para usar FilteringTextInputFormatter
import 'package:evaluapp/themes.dart';

class Note extends StatefulWidget {
  const Note(
      {super.key,
      required this.iValue,
      required this.label,
      required this.isActive,
      required this.idxNote,
      required this.onNoteLostFocusCB});

  final double iValue;
  final String label;
  final bool isActive;
  final int idxNote;
  final void Function(int position, double newNote) onNoteLostFocusCB;

  @override
  State<StatefulWidget> createState() {
    return _NoteState();
  }
}

class _NoteState extends State<Note> {
  // este controlador necesita eliminarse despues con dispose
  final _noteTextController = TextEditingController();
  late Color _textColor;

  @override
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colors = ThemeProvider.of(context)!.colors;

    if (widget.iValue != 0) {
      _noteTextController.text = widget.iValue.toStringAsFixed(1);
      if (widget.iValue < 4) {
        _textColor = colors.noteFailColor;
      } else {
        _textColor = colors.notePassColor;
      }
    } else {
      _textColor = colors.notePassColor;
    }
  }

  void _checkTxtChange(String value) {
    final colors = ThemeProvider.of(context)!.colors;
    setState(
      () {
        if (value.isNotEmpty) {
          if (double.parse(value[0]) < 4) {
            _textColor = colors.noteFailColor;
          } else {
            _textColor = colors.notePassColor;
          }
        }
      },
    );
  }

  void _onNoteLostFocus() {
    final currentValue = _noteTextController.text;
    double value = 0;

    setState(
      () {
        if (currentValue.isNotEmpty) {
          if ((double.parse(currentValue) >= 1) &&
              (double.parse(currentValue) <= 7)) {
            value = double.parse(currentValue);
            _noteTextController.text = value.toStringAsFixed(1);
          } else {
            if ((double.parse(currentValue) >= 10) &&
                (double.parse(currentValue) <= 70)) {
              value = double.parse(currentValue) / 10;
              _noteTextController.text = value.toStringAsFixed(1);
            } else {
              value = 0;
              _noteTextController.text = '';
            }
          }

          // Actualizo la dimension
          widget.onNoteLostFocusCB(widget.idxNote, value);
        } else {
          // Si no tiene valor, pongo 0 para que no se muestre
          widget.onNoteLostFocusCB(widget.idxNote, 0);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    return widget.isActive
        ? // Si el widget esta activo

        Focus(
            onFocusChange: (hasFocus) {
              if (hasFocus == false) {
                _onNoteLostFocus();
              }
            },
            child: TextField(
              onChanged: (value) {
                _checkTxtChange(value);
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9]'))
              ],
              controller: _noteTextController,
              maxLength: 2,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: TextStyle(color: _textColor, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.noteFieldBorder)),
                focusedBorder: OutlineInputBorder(
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
        // Retorna solo un container de decoracion si no está activo
        : Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                  width: 1,
                  color: colors.noteFieldBorder,
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(6),
            ),
          );
  }
}
