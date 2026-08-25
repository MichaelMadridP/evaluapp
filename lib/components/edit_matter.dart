import 'package:evaluapp/data_model/data_connect.dart';
import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/components/edit_dimension.dart';
import 'package:evaluapp/components/note.dart';
import 'package:evaluapp/themes.dart';

// Esta clase edita sobre una variable local _matter, si todo va bien, copia
// sobre el contenido sobre el parametro de entrada matter
class EditMatter extends StatefulWidget {
  const EditMatter(
      {super.key,
      required this.action,
      required this.matter,
      required this.idxMatter,
      required this.onMatterUpdateCB,
      required this.onMatterDeleteCB});

  final ActionType action;
  final MatterData matter;
  final int idxMatter;
  final void Function() onMatterUpdateCB;
  final void Function(int idxMatter) onMatterDeleteCB;

  @override
  State<StatefulWidget> createState() {
    return _EditMatterState();
  }
}

class _EditMatterState extends State<EditMatter> {
  final _controllerTextTitle = TextEditingController();
  final _controllerTargetNote = TextEditingController();

  int _percentageTotal = 0;
  final MatterData _matter = MatterData(matterTitle: '', dimension: [
    DimensionData(
        dimensionTitle: '',
        numNotes: 1,
        noteList: [0],
        percentageWeight: 100,
        removeWorstNote: false,
        isDismissable: false)
  ]);
  String _actionText = '';

  void calculatePercentage() {
    _percentageTotal = 0;
    for (int i = 0; i < _matter.dimension.length; i++) {
      _percentageTotal += _matter.dimension[i].percentageWeight;
    }
  }

  void updateDimension() {
    setState(() {
      calculatePercentage();
    });
  }

  void openAnimatedDialog(
      {required BuildContext context,
      required String title,
      required String message,
      List<Widget> actions = const []}) {
    final colors = ThemeProvider.of(context)!.colors;

    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (context, animation1, animation2) {
          return Theme(
            data: Theme.of(context).copyWith(
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: colors.editDimensionText,
                ),
              ),
            ),
            child: AlertDialog(
              title: Text(
                title,
                style: TextStyle(color: colors.editDimensionText),
              ),
              content: Text(
                message,
                style: TextStyle(color: colors.editDimensionText),
              ),
              backgroundColor: colors.editMatterBackground,
              actions: actions,
              shape: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
        transitionBuilder: (context, a1, a2, widget) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(a1),
            child: widget,
          );
        });
  }

  @override
  void initState() {
    // Si edito una existente, copio los datos de origen,
    // sino, uso la variable temporal como esta
    if (widget.action == ActionType.edit) {
      _matter.matterTitle = widget.matter.matterTitle;
      _matter.targetNote = widget.matter.targetNote;
      _actionText = 'Editar Materia';
      // Agrego las dimensiones
      _matter.dimension.clear();
      for (int i = 0; i < widget.matter.dimension.length; i++) {
        _matter.dimension.add(DimensionData(
            dimensionTitle: widget.matter.dimension[i].dimensionTitle,
            numNotes: widget.matter.dimension[i].numNotes,
            noteList: List<double>.from(widget.matter.dimension[i].noteList),
            percentageWeight: widget.matter.dimension[i].percentageWeight,
            removeWorstNote: widget.matter.dimension[i].removeWorstNote,
            isDismissable: widget.matter.dimension[i].isDismissable));
      }
    } else {
      _actionText = 'Crear Nueva Materia';
      _matter.dimension.clear();
    }

    _controllerTextTitle.text = _matter.matterTitle;
    _controllerTargetNote.text = _matter.targetNote.toString();

    calculatePercentage();
    super.initState();
  }

  @override
  void dispose() {
    _controllerTextTitle.dispose();
    _controllerTargetNote.dispose();
    super.dispose();
  }

  void onPressDelete() {
    bool inUse = false;

    for (int i = 0; i < _matter.dimension.length; i++) {
      for (int j = 0; j < _matter.dimension[i].noteList.length; j++) {
        if (_matter.dimension[i].noteList[j] != 0) {
          inUse = true;
          break;
        }
      }
    }

    if (inUse) {
      openAnimatedDialog(
        context: context,
        title: 'Materia en uso',
        message:
            'Esta materia está en uso y al eliminarla se perderán sus notas.',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo actual
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Confirmar la eliminación
              widget.onMatterDeleteCB(widget.idxMatter);
              saveData(); // Actualizar la base de datos
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context); // Cierra la pantalla actual
            },
            child: const Text('Eliminar'),
          ),
        ],
      );
    } else {
      widget.onMatterDeleteCB(widget.idxMatter);
      saveData(); // Actualizar la base de datos
      Navigator.pop(context);
    }
  }

  void onPressOk() {
    String errDescription = '';
    int limitedCount = 0;

    if (_controllerTextTitle.text.isEmpty) {
      errDescription += '- El nombre de la materia no puede estar en blanco.\n';
    }

    if ((_matter.targetNote < 4) || (_matter.targetNote > 7)) {
      errDescription += '- La nota objetivo debe estar entre 4 y 7.\n';
    }

    if (_matter.dimension.isEmpty) {
      errDescription +=
          '- La materia no tiene dimensiones (Tareas, Pruebas, Controles, etc.)\n';
    }

    limitedCount =
        (_matter.dimension.length < 10) ? _matter.dimension.length : 10;
    for (int i = 0; i < limitedCount; i++) {
      if (_matter.dimension[i].dimensionTitle.isEmpty) {
        errDescription += '- La dimensión ${i + 1} no tiene un nombre.\n';
      }
      if (_matter.dimension[i].percentageWeight == 0) {
        errDescription +=
            '- La dimensión ${i + 1} no tiene un peso porcentual ponderado.\n';
      }
    }

    if (_percentageTotal != 100) {
      errDescription +=
          '- La materia no cumple con el 100% de la ponderación total de las dimensiones.\n';
    }

    if (errDescription.isNotEmpty) {
      openAnimatedDialog(
        context: context,
        title: 'Hay errores que corregir',
        message: errDescription,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo actual
            },
            child: const Text('Ok'),
          ),
        ],
      );
    } else {
      // Si todo Ok, paso los datos al parent
      widget.matter.matterTitle = _controllerTextTitle.text;
      widget.matter.targetNote = _matter.targetNote;
      widget.matter.dimension.clear();
      for (int i = 0; i < _matter.dimension.length; i++) {
        widget.matter.dimension.add(_matter.dimension[i]);
      }
      widget.onMatterUpdateCB();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    return SafeArea(
      top: false,
      child: Container(
        color: colors.editMatterBackground,
        padding: const EdgeInsets.all(10),
        height: double.infinity,
        width: double.infinity,
        child: Column(
        children: [
          Text(
            _actionText,
            style: TextStyle(
              color: colors.editDimensionText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: colors.editDimensionText),
                  controller: _controllerTextTitle,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  decoration: InputDecoration(
                    labelText: 'Materia',
                    helperStyle: TextStyle(
                      color: colors.editDimensionText,
                      fontSize: 12,
                    ),
                    labelStyle: TextStyle(
                      color: colors.editDimensionText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text('Nota Objetivo',
                      style: TextStyle(
                          color: colors.editDimensionText,
                          fontWeight: FontWeight.w500,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Note(
                        iValue: _matter.targetNote,
                        label: '',
                        isActive: true,
                        idxNote: 0,
                        onNoteLostFocusCB: (idx, value) {
                          _matter.targetNote = value;
                        }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dimensiones',
                style: TextStyle(
                  color: colors.editDimensionText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(
                    () {
                      _matter.dimension.add(DimensionData(
                        dimensionTitle: '',
                        numNotes: 1,
                        noteList: [0],
                        percentageWeight: 50,
                        removeWorstNote: false,
                        isDismissable: false,
                      ));
                      calculatePercentage();
                    },
                  );
                },
                icon: Icon(
                  Icons.add,
                  color: colors.editDimensionText,
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _matter.dimension.length,
              itemBuilder: (ctx, index) {
                return Dismissible(
                  key: ValueKey(_matter.dimension[index].id),
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    decoration: BoxDecoration(
                      color: colors.errorTextColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.delete,
                        color: colors.iconDeleteColor,
                      ),
                    ),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      _matter.dimension.removeAt(index);
                      calculatePercentage();
                    });
                  },
                  child: EditDimension(
                    key: ValueKey(_matter.dimension[index].id),
                    dimension: _matter.dimension[index],
                    onChanged: updateDimension,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ponderación Total: $_percentageTotal%',
            style: TextStyle(
              color: (_percentageTotal == 100)
                  ? colors.primaryTextColor
                  : colors.errorTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.action == ActionType.edit)
                TextButton(
                  onPressed: onPressDelete,
                  child: Text('Eliminar Materia',
                      style: TextStyle(
                          color: colors.iconDeleteColor,
                          fontWeight: FontWeight.w600)),
                ),
              if (widget.action == ActionType.edit)
                const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onPressOk,
                child: const Text('Ok'),
              ),
            ],
          ),
          SizedBox(
              height: MediaQuery.of(context).viewPadding.bottom > 0
                  ? MediaQuery.of(context).viewPadding.bottom + 8
                  : MediaQuery.of(context).size.height * 0.04),
        ],
      ),
    ));
  }
}
