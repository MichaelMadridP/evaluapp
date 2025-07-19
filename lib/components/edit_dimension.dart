import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';

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
  double _noteCountSliderValue = 1;
  double _notePercentageSliderValue = 50;
  bool? _isRemoveChecked = false;

  @override
  void initState() {
    super.initState();
    // Cargar los valores originales
    _controllerDim.text = widget.dimension.dimensionTitle;
    _noteCountSliderValue = widget.dimension.numNotes.toDouble();
    _notePercentageSliderValue = widget.dimension.percentageWeight.toDouble();
    _isRemoveChecked = widget.dimension.removeWorstNote;
  }

  @override
  void dispose() {
    _controllerDim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          vertical: 5, horizontal: 15), // margen exterior
      elevation: 20,
      color: const Color.fromARGB(255, 162, 123, 255),
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
                    style:
                        const TextStyle(color: Color.fromARGB(255, 22, 20, 26)),
                    controller: _controllerDim,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Dimensión',
                      labelStyle: TextStyle(
                        color: Color.fromARGB(255, 22, 20, 26),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'Cant. de Notas',
                  style: TextStyle(color: Color.fromARGB(255, 22, 20, 26)),
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
                  style:
                      const TextStyle(color: Color.fromARGB(255, 22, 20, 26)),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'Ponderación',
                  style: TextStyle(color: Color.fromARGB(255, 22, 20, 26)),
                ),
                Slider(
                  value: _notePercentageSliderValue,
                  max: 100,
                  min:
                      1, // min 1 divisions 99, min 5 division 19, min 10 divisions 20
                  divisions: 99,
                  label: _notePercentageSliderValue.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      // Actualizar el Padre con los cambios
                      _notePercentageSliderValue = value;
                      widget.dimension.percentageWeight = value.round();
                      widget.onChanged();
                    });
                  },
                ),
                Text(
                  '${_notePercentageSliderValue.round().toString()}%',
                  style:
                      const TextStyle(color: Color.fromARGB(255, 22, 20, 26)),
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
                        widget.onChanged();
                      });
                    }),
                const Text(
                  'Elimina la peor Nota',
                  style: TextStyle(color: Color.fromARGB(255, 22, 20, 26)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
