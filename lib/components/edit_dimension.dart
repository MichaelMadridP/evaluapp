import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/themes.dart';

class EditDimension extends StatefulWidget {
  const EditDimension(
      {super.key, required this.dimension, required this.onChanged});

  final DimensionData dimension;
  final void Function() onChanged;

  @override
  State<StatefulWidget> createState() {
    return _EditDimensionState();
  }
}

class _EditDimensionState extends State<EditDimension> {
  final _controllerDim = TextEditingController();
  final _controllerPercentage = TextEditingController();
  double _noteCountSliderValue = 1;
  bool? _isRemoveChecked = false;

  @override
  void initState() {
    super.initState();
    // Cargar los valores originales
    _controllerDim.text = widget.dimension.dimensionTitle;
    _controllerPercentage.text = widget.dimension.percentageWeight.toString();
    _noteCountSliderValue = widget.dimension.numNotes.toDouble();
    _isRemoveChecked = widget.dimension.removeWorstNote;
  }

  @override
  void didUpdateWidget(EditDimension oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dimension.id != widget.dimension.id ||
        oldWidget.dimension.dimensionTitle != widget.dimension.dimensionTitle ||
        oldWidget.dimension.percentageWeight != widget.dimension.percentageWeight ||
        oldWidget.dimension.numNotes != widget.dimension.numNotes ||
        oldWidget.dimension.removeWorstNote != widget.dimension.removeWorstNote) {
      _controllerDim.text = widget.dimension.dimensionTitle;
      _controllerPercentage.text = widget.dimension.percentageWeight.toString();
      _noteCountSliderValue = widget.dimension.numNotes.toDouble();
      _isRemoveChecked = widget.dimension.removeWorstNote;
    }
  }

  @override
  void dispose() {
    _controllerDim.dispose();
    _controllerPercentage.dispose();
    super.dispose();
  }

  void _applyNoteCount(int newCount) {
    widget.dimension.numNotes = newCount;
    widget.dimension.syncNotes();
    widget.dimension.calculate();
    widget.onChanged();
  }

  bool _hasDataInDroppedNotes(int newCount) {
    for (int i = newCount; i < widget.dimension.noteList.length; i++) {
      if (widget.dimension.noteList[i] > 0) return true;
    }
    for (int i = newCount; i < widget.dimension.evaluationDetails.length; i++) {
      if (widget.dimension.evaluationDetails[i].hasData) return true;
    }
    return false;
  }

  Future<void> _handleSliderChangeEnd(double value) async {
    final int newCount = value.round();
    final int currentCount = widget.dimension.numNotes;

    if (newCount == currentCount) {
      setState(() {
        _noteCountSliderValue = currentCount.toDouble();
      });
      return;
    }

    if (newCount < currentCount && _hasDataInDroppedNotes(newCount)) {
      final colors = ThemeProvider.of(context)!.colors;
      final int droppedCount = currentCount - newCount;
      final startNoteNum = newCount + 1;
      final endNoteNum = currentCount;
      final rangeText = droppedCount == 1
          ? 'la nota $startNoteNum'
          : 'las notas $startNoteNum a $endNoteNum';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.editMatterBackground,
          title: Text(
            '¿Reducir cantidad de notas?',
            style: TextStyle(
              color: colors.editDimensionText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Al reducir de $currentCount a $newCount ${newCount == 1 ? "nota" : "notas"}, se descartarán $rangeText que contienen calificaciones o planes de estudio registrados.\n\n¿Deseas continuar y descartar estos datos?',
            style: TextStyle(color: colors.editDimensionText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.errorTextColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Descartar y Reducir'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() {
          _noteCountSliderValue = newCount.toDouble();
          _applyNoteCount(newCount);
        });
      } else {
        setState(() {
          _noteCountSliderValue = currentCount.toDouble();
        });
      }
    } else {
      setState(() {
        _noteCountSliderValue = newCount.toDouble();
        _applyNoteCount(newCount);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    return Card(
      margin: const EdgeInsets.symmetric(
          vertical: 6, horizontal: 0), // margen exterior
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.matterCardBorder.withValues(alpha: 0.5)),
      ),
      color: colors.editDimensionBackground,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  // Para evitar que el Textfield se expanda infinitamente
                  child: TextField(
                    onChanged: (value) {
                      // Actualizar el Padre con los cambios
                      widget.dimension.dimensionTitle = _controllerDim.text;
                    },
                    style: TextStyle(color: colors.editDimensionText),
                    controller: _controllerDim,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: 'Nombre Dimensión',
                      labelStyle: TextStyle(
                        color: colors.editDimensionText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Cant. de Notas',
                  style: TextStyle(color: colors.editDimensionText),
                ),
                Expanded(
                  child: Slider(
                    value: _noteCountSliderValue,
                    max: 21,
                    min: 1,
                    divisions: 20,
                    activeColor: colors.drawerButton,
                    inactiveColor: colors.noteFieldBorder,
                    label: _noteCountSliderValue.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _noteCountSliderValue = value;
                      });
                    },
                    onChangeEnd: (double value) {
                      _handleSliderChangeEnd(value);
                    },
                  ),
                ),
                Text(
                  _noteCountSliderValue.round().toString(),
                  style: TextStyle(
                      color: colors.editDimensionText,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Ponderación',
                  style: TextStyle(color: colors.editDimensionText),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _controllerPercentage,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: TextStyle(color: colors.editDimensionText),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: '%',
                      suffixStyle: TextStyle(color: colors.editDimensionText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      // Validar que esté entre 0 y 100
                      if (value.isEmpty) {
                        widget.dimension.percentageWeight = 0;
                        widget.onChanged();
                        return;
                      }

                      int? newValue = int.tryParse(value);
                      if (newValue != null) {
                        if (newValue > 100) {
                          // Si excede 100, establecer en 100
                          _controllerPercentage.text = '100';
                          _controllerPercentage.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: _controllerPercentage.text.length),
                          );
                          widget.dimension.percentageWeight = 100;
                        } else if (newValue < 0) {
                          // Si es menor que 0, establecer en 0
                          _controllerPercentage.text = '0';
                          _controllerPercentage.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: _controllerPercentage.text.length),
                          );
                          widget.dimension.percentageWeight = 0;
                        } else {
                          // Valor válido
                          widget.dimension.percentageWeight = newValue;
                        }
                        widget.onChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                    value: _isRemoveChecked,
                    activeColor: colors.drawerButton,
                    onChanged: (bool? value) {
                      setState(() {
                        // Actualizar el Padre con los cambios
                        _isRemoveChecked = value;
                        widget.dimension.removeWorstNote = value ?? false;
                        // Recalcular promedios con el nuevo estado
                        widget.dimension.calculate();
                        widget.onChanged();
                      });
                    }),
                Text(
                  'Elimina la peor Nota',
                  style: TextStyle(color: colors.editDimensionText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
