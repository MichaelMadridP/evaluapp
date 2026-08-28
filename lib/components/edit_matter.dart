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
  final ScrollController _scrollController = ScrollController();

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

  void _addNewDimension() {
    setState(() {
      _matter.dimension.add(DimensionData(
        dimensionTitle: '',
        numNotes: 1,
        noteList: [0],
        percentageWeight: 50,
        removeWorstNote: false,
        isDismissable: false,
      ));
      calculatePercentage();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
    // Si edito una existente, copio los datos de origen preservando notas y planes de estudio,
    // sino, uso la variable temporal como esta
    if (widget.action == ActionType.edit) {
      _matter.matterTitle = widget.matter.matterTitle;
      _matter.targetNote = widget.matter.targetNote;
      _actionText = 'Editar Materia';
      // Agrego las dimensiones clonadas
      _matter.dimension.clear();
      for (int i = 0; i < widget.matter.dimension.length; i++) {
        _matter.dimension.add(widget.matter.dimension[i].clone());
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
    _scrollController.dispose();
    super.dispose();
  }

  void onPressDelete() {
    bool inUse = false;

    for (int i = 0; i < _matter.dimension.length; i++) {
      final dim = _matter.dimension[i];
      if (dim.noteList.any((note) => note != 0) ||
          dim.evaluationDetails.any((detail) => detail.hasData)) {
        inUse = true;
        break;
      }
    }

    if (inUse) {
      openAnimatedDialog(
        context: context,
        title: 'Materia en uso',
        message:
            'Esta materia contiene calificaciones o planes de estudio registrados y al eliminarla se perderán estos datos.',
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
        widget.matter.dimension.add(_matter.dimension[i].clone());
      }
      widget.onMatterUpdateCB();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        color: colors.editMatterBackground,
        height: double.infinity,
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 14,
                  bottom: 24,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.noteFieldBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _actionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.editDimensionText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        onPressed: _addNewDimension,
                        icon: Icon(
                          Icons.add,
                          color: colors.editDimensionText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (int index = 0;
                      index < _matter.dimension.length;
                      index++)
                    Dismissible(
                      key: ValueKey(_matter.dimension[index].id),
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 0),
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
                      confirmDismiss: (direction) async {
                        final dim = _matter.dimension[index];
                        final bool hasData = dim.noteList.any((n) => n > 0) ||
                            dim.evaluationDetails.any((e) => e.hasData);
                        if (hasData) {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: colors.editMatterBackground,
                              title: Text(
                                '¿Eliminar dimensión?',
                                style: TextStyle(
                                  color: colors.editDimensionText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                'La dimensión "${dim.dimensionTitle.isNotEmpty ? dim.dimensionTitle : 'Dimensión ${index + 1}'}" contiene calificaciones o planes de estudio registrados que se perderán.\n\n¿Deseas eliminarla?',
                                style: TextStyle(
                                    color: colors.editDimensionText),
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
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                        }
                        return true;
                      },
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
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: keyboardInset > 0
                    ? 8
                    : (bottomSafeArea > 0 ? bottomSafeArea + 6 : 14),
              ),
              decoration: BoxDecoration(
                color: colors.editMatterBackground,
                border: Border(
                  top: BorderSide(
                    color: colors.matterCardBorder.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ponderación Total: $_percentageTotal%',
                    style: TextStyle(
                      color: (_percentageTotal == 100)
                          ? colors.primaryTextColor
                          : colors.errorTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
