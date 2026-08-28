// Clase para definir una dimension medible dentro de una materia
// Utiliza uuid package par acrear un ID unico a nivel de la instancia de clase
// se instala con flutter pub add uuid
import 'package:uuid/uuid.dart';
import 'dart:math';

enum ActionType { add, edit }

const uuid = Uuid();

// Clase para almacenar los metadatos y plan de estudio de una evaluación/nota individual
class EvaluationDetail {
  EvaluationDetail({
    this.date,
    this.content = '',
    this.confidenceLevel = 4,
    this.notes = '',
  });

  DateTime? date;
  String content;
  int confidenceLevel; // Rango de 1 (muy bajo) a 7 (excelente)
  String notes;

  bool get hasData =>
      date != null || content.trim().isNotEmpty || notes.trim().isNotEmpty;

  String get dateFormatted {
    if (date == null) return 'Sin fecha';
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date!.day} ${months[date!.month - 1]} ${date!.year}';
  }

  String get confidenceLabel {
    switch (confidenceLevel) {
      case 1:
        return 'Muy crítico (1)';
      case 2:
        return 'Bajo (2)';
      case 3:
        return 'Insuficiente (3)';
      case 4:
        return 'Aceptable (4)';
      case 5:
        return 'Bueno (5)';
      case 6:
        return 'Muy bueno (6)';
      case 7:
        return 'Excelente (7)';
      default:
        return 'Medio ($confidenceLevel)';
    }
  }

  EvaluationDetail clone() {
    return EvaluationDetail(
      date: date,
      content: content,
      confidenceLevel: confidenceLevel,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date?.toIso8601String(),
      'content': content,
      'confidenceLevel': confidenceLevel,
      'notes': notes,
    };
  }

  factory EvaluationDetail.fromMap(Map<String, dynamic> data) {
    return EvaluationDetail(
      date: data['date'] != null
          ? DateTime.tryParse(data['date'].toString())
          : null,
      content: data['content']?.toString() ?? '',
      confidenceLevel: (data['confidenceLevel'] is num)
          ? (data['confidenceLevel'] as num).toInt().clamp(1, 7)
          : 4,
      notes: data['notes']?.toString() ?? '',
    );
  }
}

// Representación consolidada de una evaluación para la vista de Plan de Estudio
class StudyEvaluationItem {
  StudyEvaluationItem({
    required this.matter,
    required this.dimension,
    required this.noteIndex,
    required this.grade,
    required this.detail,
  });

  final MatterData matter;
  final DimensionData dimension;
  final int noteIndex;
  final double grade;
  final EvaluationDetail detail;

  bool get isPending => grade == 0;
}

// Clase para administrar una dimensión específica dentro de una materia
// Pueden existir muchas dimensiones en cada materia, cada una con su
// porcentaje de ponderación, todas juntas suman 100%
class DimensionData {
  DimensionData({
    String? id,
    required this.dimensionTitle,
    required this.numNotes,
    required this.noteList,
    required this.percentageWeight,
    required this.removeWorstNote,
    required this.isDismissable,
    List<EvaluationDetail>? evaluationDetails,
  })  : id = id ?? uuid.v4(),
        evaluationDetails = evaluationDetails ?? [] {
    syncNotes();
  }

  final String id;
  String dimensionTitle;
  int numNotes;
  List<double> noteList;
  int percentageWeight;
  bool removeWorstNote;
  bool isDismissable;
  List<EvaluationDetail> evaluationDetails;
  double _average = 0;
  double _minimumRequired = 0;
  double targetNote = 4;

  void syncNotes() {
    while (noteList.length < numNotes) {
      noteList.add(0.0);
    }
    while (noteList.length > numNotes) {
      noteList.removeLast();
    }
    while (evaluationDetails.length < numNotes) {
      evaluationDetails.add(EvaluationDetail());
    }
    while (evaluationDetails.length > numNotes) {
      evaluationDetails.removeLast();
    }
  }

  DimensionData clone() {
    return DimensionData(
      id: id,
      dimensionTitle: dimensionTitle,
      numNotes: numNotes,
      noteList: List<double>.from(noteList),
      percentageWeight: percentageWeight,
      removeWorstNote: removeWorstNote,
      isDismissable: isDismissable,
      evaluationDetails: evaluationDetails.map((e) => e.clone()).toList(),
    );
  }

  double get average {
    return _average;
  }

  double get minimumRequired {
    return _minimumRequired;
  }

  void calculate() {
    syncNotes();

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
    syncNotes();
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['dimensionTitle'] = dimensionTitle;
    data['numNotes'] = numNotes;
    data['noteList'] = noteList;
    data['percentageWeight'] = percentageWeight;
    data['removeWorstNote'] = removeWorstNote;
    data['isDismissable'] = isDismissable;
    data['evaluationDetails'] =
        evaluationDetails.map((e) => e.toMap()).toList();
    return data;
  }

  // DesSerializacion desde la base de datos
  factory DimensionData.fromMap(Map<String, dynamic> data) {
    List<double> noteList = [];
    if (data['noteList'] != null) {
      for (var n in data['noteList']) {
        noteList.add(n.toDouble());
      }
    }

    final id = data['id']?.toString();
    final dimensionTitle = data['dimensionTitle'] ?? '';
    final numNotes = data['numNotes'] ?? 1;
    final percentageWeight = data['percentageWeight'] ?? 100;
    final removeWorstNote = data['removeWorstNote'] ?? false;
    final isDismissable = data['isDismissable'] ?? false;

    List<EvaluationDetail> evaluationDetails = [];
    if (data['evaluationDetails'] != null) {
      if (data['evaluationDetails'] is List) {
        for (var e in data['evaluationDetails']) {
          if (e != null) {
            evaluationDetails.add(
                EvaluationDetail.fromMap(Map<String, dynamic>.from(e as Map)));
          }
        }
      } else if (data['evaluationDetails'] is Map) {
        for (var e in (data['evaluationDetails'] as Map).values) {
          if (e != null) {
            evaluationDetails.add(
                EvaluationDetail.fromMap(Map<String, dynamic>.from(e as Map)));
          }
        }
      }
    }

    return DimensionData(
      id: id,
      dimensionTitle: dimensionTitle,
      numNotes: numNotes,
      noteList: noteList,
      percentageWeight: percentageWeight,
      removeWorstNote: removeWorstNote,
      isDismissable: isDismissable,
      evaluationDetails: evaluationDetails,
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

  MatterData clone() {
    final matter = MatterData(
      matterTitle: matterTitle,
      dimension: dimension.map((d) => d.clone()).toList(),
      targetNote: targetNote,
    );
    matter.calculate();
    return matter;
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

// Clase para definir un período académico (Semestre, Trimestre, Año, etc.)
// Un período agrupa materias con sus dimensiones y notas
class PeriodData {
  PeriodData({
    String? id,
    required this.name,
    this.startDate,
    this.endDate,
    List<MatterData>? matters,
    DateTime? createdAt,
  })  : id = id ?? uuid.v4(),
        matters = matters ?? [],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  DateTime? startDate;
  DateTime? endDate;
  List<MatterData> matters;
  final DateTime createdAt;

  void calculate() {
    for (var matter in matters) {
      matter.calculate();
    }
  }

  // Helper para mostrar el rango de fechas en formato legible (ej: 15/03/2026 - 30/07/2026)
  String get dateRangeFormatted {
    if (startDate == null && endDate == null) {
      return '';
    }
    String formatD(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    if (startDate != null && endDate != null) {
      return '${formatD(startDate!)} - ${formatD(endDate!)}';
    } else if (startDate != null) {
      return 'Desde ${formatD(startDate!)}';
    } else {
      return 'Hasta ${formatD(endDate!)}';
    }
  }

  // Serialización para Firebase
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['startDate'] = startDate?.toIso8601String();
    data['endDate'] = endDate?.toIso8601String();
    data['createdAt'] = createdAt.toIso8601String();
    data['matters'] = matters.map((m) => m.toMap()).toList();
    return data;
  }

  // Deserialización desde Firebase
  static PeriodData fromMap(Map<String, dynamic> data) {
    List<MatterData> matterList = [];

    if (data['matters'] != null) {
      if (data['matters'] is List) {
        for (var m in data['matters']) {
          if (m != null) {
            final localMatterMap = Map<String, dynamic>.from(m as Map);
            matterList.add(MatterData.fromMap(localMatterMap));
          }
        }
      } else if (data['matters'] is Map) {
        for (var m in (data['matters'] as Map).values) {
          if (m != null) {
            final localMatterMap = Map<String, dynamic>.from(m as Map);
            matterList.add(MatterData.fromMap(localMatterMap));
          }
        }
      }
    }

    final id = data['id']?.toString() ?? uuid.v4();
    final name = data['name']?.toString() ?? 'Sin Nombre';
    final startDate = data['startDate'] != null
        ? DateTime.tryParse(data['startDate'].toString())
        : null;
    final endDate = data['endDate'] != null
        ? DateTime.tryParse(data['endDate'].toString())
        : null;
    final createdAt = data['createdAt'] != null
        ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();
    final period = PeriodData(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      matters: matterList,
      createdAt: createdAt,
    );
    period.calculate();
    return period;
  }

  // Retorna todas las evaluaciones del período para la pantalla de Plan de Estudio
  List<StudyEvaluationItem> getAllEvaluations() {
    final List<StudyEvaluationItem> list = [];
    for (var m in matters) {
      for (var d in m.dimension) {
        for (int i = 0; i < d.numNotes; i++) {
          final grade = (i < d.noteList.length) ? d.noteList[i] : 0.0;
          final detail = (i < d.evaluationDetails.length)
              ? d.evaluationDetails[i]
              : EvaluationDetail();
          list.add(StudyEvaluationItem(
            matter: m,
            dimension: d,
            noteIndex: i,
            grade: grade,
            detail: detail,
          ));
        }
      }
    }
    return list;
  }
}
