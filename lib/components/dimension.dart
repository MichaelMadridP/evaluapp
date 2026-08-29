import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/components/note.dart';
import 'package:evaluapp/components/note_display_only.dart';
import 'package:evaluapp/components/evaluation_detail_modal.dart';
import 'package:evaluapp/themes.dart';

//*****************************************************************************************************/
// Despliega una sola Dimension
//*****************************************************************************************************/
class Dimension extends StatefulWidget {
  const Dimension({
    super.key,
    required this.dimension,
    required this.onChanged,
    this.matterTitle,
  });

  final DimensionData dimension;
  final void Function() onChanged;
  final String? matterTitle;

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

  void _openEvaluationDetail(int index) {
    while (widget.dimension.evaluationDetails.length <= index) {
      widget.dimension.evaluationDetails.add(EvaluationDetail());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      builder: (ctx) {
        return EvaluationDetailModal(
          matterTitle: widget.matterTitle ?? '',
          dimensionTitle: widget.dimension.dimensionTitle,
          noteIndex: index,
          grade: (index < widget.dimension.noteList.length)
              ? widget.dimension.noteList[index]
              : 0.0,
          detail: widget.dimension.evaluationDetails[index],
          previousDate: index > 0
              ? widget.dimension.evaluationDetails[index - 1].date
              : null,
          nextDate: index + 1 < widget.dimension.evaluationDetails.length
              ? widget.dimension.evaluationDetails[index + 1].date
              : null,
          periodStartDate: activePeriod?.startDate,
          periodEndDate: activePeriod?.endDate,
          onSaveCB: () {
            setState(() {});
            saveData();
          },
        );
      },
    );
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
        final int noteIndex = thisNote;
        if (thisNote < numNotesToDisplay) {
          setActive = true;
          iValue = widget.dimension.noteList[thisNote];
        } else {
          setActive = false;
          iValue = 0;
        }

        final EvaluationDetail? detail =
            (noteIndex < widget.dimension.evaluationDetails.length)
                ? widget.dimension.evaluationDetails[noteIndex]
                : null;

        subList.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Note(
              iValue: iValue,
              label: (thisNote + 1).toString().padLeft(2, '0'),
              isActive: setActive,
              idxNote: thisNote,
              evaluationDetail: detail,
              onLongPress:
                  setActive ? () => _openEvaluationDetail(noteIndex) : null,
              onNoteLostFocusCB: _updateNote,
            ),
          ),
        ));
        thisNote++;
      }

      retList.add(Row(children: [...subList]));
      retList.add(const SizedBox(height: 8)); //Separador
      // Borrar la sublista para la siguiente iteracion
      subList.clear();
    }

    return retList;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    // Actualizar el indicador * basado en el estado actual
    noHelperForRemoveWorstNote = widget.dimension.removeWorstNote ? '(*)' : '';

    final bool isFinal = widget.dimension.isFinal();
    final averageLabel = isFinal ? 'Promedio Final' : 'Promedio Parcial';

    return Card(
      color: colors.dimensionCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
      margin: const EdgeInsetsDirectional.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(
                widget.dimension.dimensionTitle,
                style: TextStyle(color: colors.dimensionCardText, fontSize: 18),
              ),
              const SizedBox(
                height: 8,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(averageLabel,
                      style: TextStyle(color: colors.dimensionCardText)),
                  NoteDisplayOnly(value: widget.dimension.average),
                  Text('Requerido',
                      style: TextStyle(color: colors.dimensionCardText)),
                  NoteDisplayOnly(value: widget.dimension.minimumRequired),
                ],
              ),
              const SizedBox(height: 8),
              Text('Notas $noHelperForRemoveWorstNote',
                  style: TextStyle(color: colors.dimensionCardText)),
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
