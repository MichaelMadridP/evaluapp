import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/components/note.dart';
import 'package:evaluapp/components/note_display_only.dart';

//*****************************************************************************************************/
// Despliega una sola Dimension
//*****************************************************************************************************/
class Dimension extends StatefulWidget {
  const Dimension({
    super.key,
    required this.dimension,
    required this.onChanged,
  });

  final DimensionData dimension;
  final void Function() onChanged;

  @override
  State<StatefulWidget> createState() {
    return _DimensionState();
  }
}

class _DimensionState extends State<Dimension> {
  String noHelperForRemoveWorstNote = '';

  void _updateNote(int idx, double value) {
    setState(() {
      noHelperForRemoveWorstNote =
          widget.dimension.removeWorstNote ? '(*)' : '';
      widget.dimension.noteList[idx] = value;
      widget.dimension.calculate();
      widget.onChanged();
    });
  }

  // Esta función despliega las casillas de notas de acuerdo a la cantidad configurada
  List<Widget> createNoteList(int numNotesToDisplay) {
    const int notesBreakLine =
        7; // La cantidad de casillas que pueden verse horizontalmente
    int numLines = (numNotesToDisplay ~/ notesBreakLine);
    List<Widget> retList = [];
    List<Widget> subList = [];

    if (numNotesToDisplay % notesBreakLine != 0) {
      numLines++;
    }

    // Agrego 2 widgets por linea, un Row y un Sizedbox como separador
    int thisNote = 0;
    bool setActive = false;
    double iValue = 0;

    // Agregar las lineas de Notas según la cantidad indicada
    for (int lines = 0; lines < numLines; lines++) {
      for (int j = 0; j < notesBreakLine; j++) {
        if (thisNote < numNotesToDisplay) {
          setActive = true;
          iValue = widget.dimension.noteList[thisNote];
        } else {
          setActive = false;
          iValue = 0;
        }
        subList.add(Note(
          iValue: iValue,
          label: (thisNote + 1).toString().padLeft(2, '0'),
          isActive: setActive,
          idxNote: thisNote,
          onNoteLostFocusCB: _updateNote,
        ));
        thisNote++;
      }

      retList.add(Row(
          mainAxisAlignment: MainAxisAlignment.center, children: [...subList]));
      retList.add(const SizedBox(height: 8)); //Separador
      // Borrar la sublista para la siguiente iteracion
      subList.clear();
    }

    return retList;
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinal = widget.dimension.isFinal();
    final averageLabel = isFinal ? 'Promedio Final' : 'Promedio Parcial';
    return Card(
      //color: const Color.fromARGB(255, 67, 2, 153),
      color: const Color.fromARGB(255, 58, 0, 134),
      margin: const EdgeInsetsDirectional.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(
                widget.dimension.dimensionTitle,
                style: const TextStyle(
                    color: Color.fromARGB(255, 221, 201, 248), fontSize: 18),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(averageLabel,
                      style:
                          const TextStyle(color: Color.fromARGB(255, 221, 201, 248))),
                  const SizedBox(width: 8),
                  NoteDisplayOnly(value: widget.dimension.average),
                  const SizedBox(width: 8),
                  const Text('Requerido',
                      style:
                          TextStyle(color: Color.fromARGB(255, 221, 201, 248))),
                  const SizedBox(width: 8),
                  NoteDisplayOnly(value: widget.dimension.minimumRequired),
                ],
              ),
              const SizedBox(height: 8),
              Text('Notas $noHelperForRemoveWorstNote',
                  style: const TextStyle(
                      color: Color.fromARGB(255, 221, 201, 248))),
              const SizedBox(height: 8),
              // Casilleros de Notas ***************************************
              ...createNoteList(widget.dimension
                  .numNotes), //los 3 puntos, son el operador que expande una lista en elementos separados por comas
            ],
          ),
        ),
      ),
    );
  }
}
