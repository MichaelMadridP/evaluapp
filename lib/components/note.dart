import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para usar FilteringTextInputFormatter

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
  Color _textColor = Colors.blueAccent;

  @override
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.iValue != 0) {
      _noteTextController.text = widget.iValue.toStringAsFixed(1);
      if (widget.iValue < 4) {
        _textColor = Colors.redAccent;
      } else {
        _textColor = Colors.blueAccent;
      }
    }
    super.initState();
  }

  void _checkTxtChange(String value) {
    setState(
      () {
        if (value.isNotEmpty) {
          if (double.parse(value[0]) < 4) {
            _textColor = Colors.redAccent;
          } else {
            _textColor = Colors.blueAccent;
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
    return widget.isActive
        ? // Si el widget esta activo

        SizedBox(
            width: 48,
            child: Focus(
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
                textAlign: TextAlign.end,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 93, 69, 126))),
                  labelText: widget.label,
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 190, 190, 190)),
                  counterText: '',
                ),
              ),
            ),
          )
        // Retorna solo un container de decoracion si no está activo
        : Container(
            decoration: BoxDecoration(
              border: Border.all(
                  width: 1,
                  color: const Color.fromARGB(255, 93, 69, 126),
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(6),
            ),
            width: 48,
            height: 55,
            child: const Center(
              child: Text(''),
            ),
          );
  }
}
