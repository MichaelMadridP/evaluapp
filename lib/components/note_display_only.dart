import 'package:flutter/material.dart';

class NoteDisplayOnly extends StatefulWidget {
  const NoteDisplayOnly({super.key, required this.value});

  final double value;

  @override
  State<StatefulWidget> createState() {
    return _NoteDisplayOnlyState();
  }
}

class _NoteDisplayOnlyState extends State<NoteDisplayOnly> {
  @override
  Widget build(BuildContext context) {
    var iColor = Colors.white;
    var iText = '';

    if (widget.value != 0) {
      iColor = (widget.value < 4) ? Colors.redAccent : Colors.white;
      iText = widget.value.toStringAsFixed(1).toString();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            width: 1,
            color: const Color.fromARGB(255, 179, 157, 209),
            style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(6),
      ),
      width: 50,
      height: 40,
      child: Center(
        child: Text(
          iText,
          style: TextStyle(fontSize: 16, color: iColor),
        ),
      ),
    );
  }
}
