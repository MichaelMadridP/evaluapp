// Clase para definir una dimension medible dentro de una materia
// Utiliza uuid package par acrear un ID unico a nivel de la instancia de clase
// se instala con flutter pub add uuid
import 'package:uuid/uuid.dart';
import 'dart:math';

enum ActionType { add, edit }

const uuid = Uuid();

// Clase para administrar una dimensión específica dentro de una materia
// Pueden existir muchas dimensiones en cada materia, cada una con su
// porcentaje de ponderación, todas juntas suman 100%
class DimensionData {
  DimensionData(
      {required this.dimensionTitle,
      required this.numNotes,
      required this.noteList,
      required this.percentageWeight,
      required this.removeWorstNote,
      required this.isDismissable})
      : id = uuid.v4();

  final String id;
  String dimensionTitle;
  int numNotes;
  List<double> noteList;
  int percentageWeight;
  bool removeWorstNote;
  bool isDismissable;
  double _average = 0;
  double _minimumRequired = 0;
  double targetNote = 4;

  double get average {
    return _average;
  }

  double get minimumRequired {
    return _minimumRequired;
  }

  void calculate() {
    // Calcular el promedio y el requerido
    double sum = 0;
    List<double> onlyNzValues =
        noteList.where((element) => element > 0).toList();
    double minimumNote = onlyNzValues.isNotEmpty ? onlyNzValues.reduce(min) : 0;
    int cNotes = 0;
    int numNotesActual = 0;
    bool noteRemoved = false;

    for (int i = 0; i < noteList.length; i++) {
      if (noteList[i] > 0) {
        if ((noteList[i] == minimumNote) &&
            (removeWorstNote) &&
            (!noteRemoved) &&
            onlyNzValues.length > 1) {
          // Eliminar la nota más baja
          noteRemoved = true;
        } else {
          sum += noteList[i];
          cNotes++;
        }
      }
    }

    if (sum == 0) {
      _average = 0;
    } else {
      _average = sum / cNotes;
    }

    // Calcular el requerido para las siguientes notas
    // considerando si se elimina la peor nota o no
    numNotesActual = (noteRemoved) ? numNotes - 1 : numNotes;
    if ((numNotesActual - cNotes) != 0) {
      _minimumRequired =
          ((targetNote * numNotesActual) - sum) / (numNotesActual - cNotes);
    } else {
      _minimumRequired = 0;
    }
  }

  bool isFinal() {
    for (int i = 0; i < noteList.length; i++) {
      if (noteList[i] == 0) {
        return false;
      }
    } 
    return true;
  }

  // Serializacion para base de datos
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dimensionTitle'] = dimensionTitle;
    data['numNotes'] = numNotes;
    data['noteList'] = noteList;
    data['percentageWeight'] = percentageWeight;
    data['removeWorstNote'] = removeWorstNote;
    data['isDismissable'] = isDismissable;
    return data;
  }

  // DesSerializacion desde la base de datos
  factory DimensionData.fromMap(Map<String, dynamic> data) {
    List<double> noteList=[];
    for (var n in data['noteList']) {
      noteList.add(n.toDouble());
    } 

    final dimensionTitle = data['dimensionTitle'];
    final numNotes = data['numNotes'];
    final percentageWeight = data['percentageWeight'];
    final removeWorstNote = data['removeWorstNote'];
    final isDismissable = data['isDismissable'];

    return DimensionData(
      dimensionTitle: dimensionTitle,
      numNotes: numNotes,
      noteList: noteList,
      percentageWeight: percentageWeight,
      removeWorstNote: removeWorstNote,
      isDismissable: isDismissable,
    );
  }

}

// Clase para definir una materia, con sus propias dimensiones
// Todas las materias juntan hacen el semestre
class MatterData {
  MatterData({
    required this.matterTitle,
    required this.dimension,
    double targetNote = 4.0,
  }) : _targetNote = targetNote {
    for (int i = 0; i < dimension.length; i++) {
      dimension[i].targetNote = _targetNote;
    }
  }

  String matterTitle;
  double _average = 0;
  double _minimumRequired = 0;
  double _targetNote = 4;
  List<DimensionData> dimension;

  set targetNote(double value) {
    _targetNote = value;
    for (int i = 0; i < dimension.length; i++) {
      dimension[i].targetNote = value;
    }
  }

  double get targetNote {
    return _targetNote;
  }

  double get average {
    return _average;
  }

  double get minimumRequired {
    return _minimumRequired;
  }

  void calculate() {
    if (dimension.isEmpty) {
      _average = 0;
      _minimumRequired = 0;
      return;
    }

    // Primero calcular los promedios de las dimensiones
    for (int i = 0; i < dimension.length; i++) {
      dimension[i].targetNote = _targetNote;
      dimension[i].calculate();
    }

    // Calcular el peso de las dimensiones que tienen notas ingresadas (average > 0)
    int usedWeight = 0;
    for (int i = 0; i < dimension.length; i++) {
      if (dimension[i].average > 0) {
        usedWeight += dimension[i].percentageWeight;
      }
    }

    // Normalización proporcional del promedio ponderado entre dimensiones activas
    if (usedWeight > 0) {
      double sum = 0;
      for (int i = 0; i < dimension.length; i++) {
        if (dimension[i].average > 0) {
          final double relativeWeight = dimension[i].percentageWeight / usedWeight;
          sum += dimension[i].average * relativeWeight;
        }
      }
      _average = sum;
    } else {
      _average = 0;
    }

    // Cálculo de la nota requerida en las dimensiones pendientes
    final int remainingWeight = 100 - usedWeight;
    if (remainingWeight > 0) {
      final double usedFraction = usedWeight / 100.0;
      final double remainingFraction = remainingWeight / 100.0;
      _minimumRequired =
          (_targetNote - (_average * usedFraction)) / remainingFraction;
    } else {
      _minimumRequired = 0;
    }
  }

  bool isFinal() {
    for (int i = 0; i < dimension.length; i++) {
      if (!dimension[i].isFinal()) {
        return false;
      }
    } 
    return true;
  }

  // Serializacion para base de datos
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['matterTitle'] = matterTitle;
    data['average'] = average;
    data['minimumRequired'] = minimumRequired;
    data['targetNote'] = targetNote;
    data['dimension'] = dimension.map((d) => d.toMap()).toList();
    return data;
  }

  // DesSerializacion desde la base de datos
  static MatterData fromMap(Map<String, dynamic> data) {
    List<DimensionData> dimensionList = [];

    if (data['dimension'] != null) {
      for (var d in data['dimension']) {
        final localDimensionMap = Map<String, dynamic>.from(d as Map);
        DimensionData localDimension = DimensionData.fromMap(localDimensionMap);
        dimensionList.add(localDimension);
      }
    }

    final double restoredTargetNote = (data['targetNote'] != null)
        ? (data['targetNote'] as num).toDouble()
        : 4.0;

    final matter = MatterData(
      matterTitle: data['matterTitle'] ?? '',
      dimension: dimensionList,
      targetNote: restoredTargetNote,
    );
    matter.calculate();
    return matter;
  }
}
