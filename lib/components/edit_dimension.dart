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
  void dispose() {
    _controllerDim.dispose();
    _controllerPercentage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    return Card(
      margin: const EdgeInsets.symmetric(
          vertical: 5, horizontal: 15), // margen exterior
      elevation: 20,
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
                Slider(
                  value: _noteCountSliderValue,
                  max: 21,
                  min: 1,
                  divisions: 21,
                  label: _noteCountSliderValue.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _noteCountSliderValue = value;

                      // // Ajustar la cantidad de datos
                      widget.dimension.numNotes = value.round();

                      if (widget.dimension.numNotes >
                          widget.dimension.noteList.length) {
                        // si el contador es mas grande que la lista, agregar notas vacias al final
                        for (int i = widget.dimension.noteList.length;
                            i < widget.dimension.numNotes;
                            i++) {
                          widget.dimension.noteList.add(0);
                        }
                      }

                      if (widget.dimension.numNotes <
                          widget.dimension.noteList.length) {
                        // si el contador es mas chico que la lista, elimino notas al final
                        for (int i = widget.dimension.noteList.length;
                            widget.dimension.numNotes <
                                widget.dimension.noteList.length;
                            i--) {
                          widget.dimension.noteList.removeAt(i - 1);
                        }
                      }
                    });
                  },
                ),
                Text(
                  _noteCountSliderValue.round().toString(),
                  style: TextStyle(color: colors.editDimensionText),
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
                      suffixText: '%',
                      suffixStyle: TextStyle(color: colors.editDimensionText),
                      border: const OutlineInputBorder(),
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
