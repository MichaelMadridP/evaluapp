import 'package:evaluapp/data_model/data_connect.dart';
import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/components/dimension.dart';
import 'package:evaluapp/components/edit_matter.dart';
import 'package:evaluapp/components/note_display_only.dart';
import 'package:evaluapp/themes.dart';

//*****************************************************************************************************/
// Tarjeta completa de una materia. Contiene múltiples dimensiones
//*****************************************************************************************************/
class Matter extends StatefulWidget {
  const Matter({
    super.key,
    required this.matter,
    required this.idxMatter,
    required this.onRemoveMatterCB,
  });

  final MatterData matter;
  final int idxMatter;
  final Function(int) onRemoveMatterCB;

  @override
  State<StatefulWidget> createState() {
    return _MatterState();
  }
}

// *****************************************************************************************************/
class _MatterState extends State<Matter> {
// Hacer la materia de retorno actualice la actual
  void updateMatter() {
    setState(() {
      widget.matter.calculate(); // Actualizar la materia
      saveData();
    });
  }

  void deleteMatter(int idx) {
    setState(() {
      widget.onRemoveMatterCB(idx);
    });
  }

  void editMatter() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      useSafeArea: true,
      isDismissible: false,
      builder: (ctx) {
        return EditMatter(
          action: ActionType.edit,
          idxMatter: widget.idxMatter,
          matter: widget.matter,
          onMatterUpdateCB: updateMatter,
          onMatterDeleteCB: deleteMatter,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;
    widget.matter.calculate(); // Actualizar la materia
    final bool isFinal = widget.matter.isFinal();
    final averageLabel = isFinal ? 'Final' : 'Parcial';

    return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(
              color: colors.matterCardBorder,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10))),
        elevation: 40,
        borderOnForeground: true,
        margin: const EdgeInsets.all(10), // Bordes externos
        color: colors.matterCardBackground,
        child: SizedBox(
          width: double.infinity, // Usar todo el ancho
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              TextButton(
                  onPressed: () {
                    editMatter();
                  },
                  child: Text(widget.matter.matterTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.matterCardTitle,
                      ))),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                flex: 0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 10),
                      Text(
                        averageLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.matterCardText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      NoteDisplayOnly(value: widget.matter.average),
                      const SizedBox(width: 10),
                      Text(
                        'Requerido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.matterCardText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      NoteDisplayOnly(value: widget.matter.minimumRequired),
                      const SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 1,
              ),
              Divider(
                color: colors.matterCardBorder,
              ),
              const SizedBox(
                height: 1,
              ),
              for (int i = 0; i < widget.matter.dimension.length; i++)
                Dimension(
                  dimension: widget.matter.dimension[i],
                  onChanged: updateMatter,
                ),
            ],
          ),
        ));
  }
}
