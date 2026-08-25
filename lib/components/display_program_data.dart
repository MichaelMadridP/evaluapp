import 'package:evaluapp/data_model/data_connect.dart';
import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/components/matter.dart';
import 'package:evaluapp/themes.dart';

class DisplayProgramData extends StatefulWidget {
  const DisplayProgramData({super.key, required this.matters});

  final List<MatterData> matters;

  @override
  State<StatefulWidget> createState() {
    return _DisplayProgramDataState();
  }
}

class _DisplayProgramDataState extends State<DisplayProgramData> {
  void removeMatter(int idxMatter) {
    setState(() {
      widget.matters.removeAt(idxMatter);
      saveData(); // Actualizar la base de datos
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    return (widget.matters.isEmpty)
        ? Center(
            child: Text(
                'Al parecer no hay materias creadas aún. \nAgrega algunas con el signo + de arriba',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.primaryTextColor, fontSize: 18)),
          )
        : ListView.builder(
            itemCount: widget.matters.length,
            itemBuilder: (ctx, index) {
              return Matter(
                key: ValueKey('${widget.matters[index].matterTitle}_$index'),
                idxMatter: index,
                matter: widget.matters[index],
                onRemoveMatterCB: removeMatter,
              );
            },
          );
  }
}
