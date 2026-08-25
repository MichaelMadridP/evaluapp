import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/components/evaluation_detail_modal.dart';
import 'package:evaluapp/themes.dart';

enum StudyPlanSortOrder {
  confidence, // Menor nivel de confianza primero (urgencia de estudio)
  date,       // Próximas fechas primero (cronológico)
}

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  StudyPlanSortOrder _sortOrder = StudyPlanSortOrder.confidence;
  bool _onlyPending = false;

  Color _getConfidenceColor(int level) {
    switch (level) {
      case 1:
      case 2:
        return const Color(0xFFEF4444); // Rojo (crítico/bajo)
      case 3:
        return const Color(0xFFF97316); // Naranja
      case 4:
        return const Color(0xFFEAB308); // Ámbar/Amarillo
      case 5:
        return const Color(0xFF10B981); // Verde esmeralda
      case 6:
        return const Color(0xFF3B82F6); // Azul
      case 7:
        return const Color(0xFF8B5CF6); // Violeta excelente
      default:
        return const Color(0xFF94A3B8);
    }
  }

  void _openDetailModal(BuildContext context, StudyEvaluationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      builder: (ctx) {
        return EvaluationDetailModal(
          matterTitle: item.matter.matterTitle,
          dimensionTitle: item.dimension.dimensionTitle,
          noteIndex: item.noteIndex,
          grade: item.grade,
          detail: item.detail,
          onSaveCB: () {
            setState(() {});
            saveData();
          },
        );
      },
    );
  }

  List<StudyEvaluationItem> _getFilteredAndSortedItems() {
    final allItems = activePeriod?.getAllEvaluations() ?? [];

    // Filtrar pendientes si está activado
    var list = _onlyPending
        ? allItems.where((item) => item.isPending).toList()
        : List<StudyEvaluationItem>.from(allItems);

    // Ordenar
    if (_sortOrder == StudyPlanSortOrder.confidence) {
      list.sort((a, b) {
        final cmp = a.detail.confidenceLevel.compareTo(b.detail.confidenceLevel);
        if (cmp != 0) return cmp;
        // Si empatan en confianza, ordenar por fecha más próxima
        if (a.detail.date != null && b.detail.date != null) {
          return a.detail.date!.compareTo(b.detail.date!);
        } else if (a.detail.date != null) {
          return -1;
        } else if (b.detail.date != null) {
          return 1;
        }
        return 0;
      });
    } else {
      // Orden por fecha
      list.sort((a, b) {
        if (a.detail.date != null && b.detail.date != null) {
          final cmp = a.detail.date!.compareTo(b.detail.date!);
          if (cmp != 0) return cmp;
        } else if (a.detail.date != null) {
          return -1;
        } else if (b.detail.date != null) {
          return 1;
        }
        // Si empatan en fecha (o ambas sin fecha), ordenar por menor confianza primero
        return a.detail.confidenceLevel.compareTo(b.detail.confidenceLevel);
      });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;
    final items = _getFilteredAndSortedItems();
    final allItems = activePeriod?.getAllEvaluations() ?? [];
    final criticalCount = allItems.where((i) => i.detail.confidenceLevel <= 3).length;
    final withDateCount = allItems.where((i) => i.detail.date != null).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.appBarBackground,
        iconTheme: IconThemeData(color: colors.appBarIcon),
        title: Text(
          'Plan de Estudio',
          style: TextStyle(
            color: colors.appBarTitle,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            // Panel de resumen y métricas de estudio
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.matterCardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.matterCardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: colors.drawerButton, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Período: ${activePeriod?.name ?? "Sin período"}',
                        style: TextStyle(
                          color: colors.matterCardTitle,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricChip(
                        context: context,
                        icon: Icons.checklist,
                        label: 'Total',
                        value: '${allItems.length}',
                        color: colors.drawerButton,
                      ),
                      _buildMetricChip(
                        context: context,
                        icon: Icons.warning_amber_rounded,
                        label: 'Foco Crítico',
                        value: '$criticalCount',
                        color: const Color(0xFFEF4444),
                      ),
                      _buildMetricChip(
                        context: context,
                        icon: Icons.calendar_month,
                        label: 'Con Fecha',
                        value: '$withDateCount',
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Controles de Orden y Filtro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<StudyPlanSortOrder>(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: StudyPlanSortOrder.confidence,
                          icon: Icon(Icons.priority_high, size: 16),
                          label: Text('Por Confianza', style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: StudyPlanSortOrder.date,
                          icon: Icon(Icons.event, size: 16),
                          label: Text('Por Fecha', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                      selected: {_sortOrder},
                      onSelectionChanged: (val) {
                        setState(() {
                          _sortOrder = val.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Solo Pendientes', style: TextStyle(fontSize: 11)),
                    selected: _onlyPending,
                    onSelected: (val) {
                      setState(() {
                        _onlyPending = val;
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Lista de Evaluaciones
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 56,
                              color: colors.primaryTextColor.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron evaluaciones',
                              style: TextStyle(
                                color: colors.primaryTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Mantén presionada (Long Press) cualquier nota en la pantalla principal para registrar fechas, contenidos y nivel de confianza.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.primaryTextColor.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: items.length,
                      itemBuilder: (ctx, index) {
                        final item = items[index];
                        final confColor = _getConfidenceColor(item.detail.confidenceLevel);
                        final hasContent = item.detail.content.isNotEmpty;
                        final hasNotes = item.detail.notes.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: item.detail.confidenceLevel <= 3
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                  : colors.matterCardBorder,
                              width: item.detail.confidenceLevel <= 3 ? 1.4 : 1,
                            ),
                          ),
                          color: colors.matterCardBackground,
                          elevation: 1.5,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openDetailModal(context, item),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Fila superior: Materia + Dimensión + Nota actual
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.matter.matterTitle.isNotEmpty
                                                  ? item.matter.matterTitle
                                                  : 'Sin Materia',
                                              style: TextStyle(
                                                color: colors.matterCardTitle,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              '${item.dimension.dimensionTitle} • Evaluación #${item.noteIndex + 1}',
                                              style: TextStyle(
                                                color: colors.matterCardText.withValues(alpha: 0.8),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (item.grade > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colors.noteGreen,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Nota ${item.grade.toStringAsFixed(1)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colors.noteGrey.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: colors.noteGrey.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            'Pendiente',
                                            style: TextStyle(
                                              color: colors.matterCardText,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Fila de Badges: Fecha + Nivel de Confianza
                                  Row(
                                    children: [
                                      // Badge Fecha
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.detail.date != null
                                              ? colors.drawerButton.withValues(alpha: 0.15)
                                              : colors.noteFieldBorder.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: item.detail.date != null
                                                ? colors.drawerButton.withValues(alpha: 0.3)
                                                : colors.noteFieldBorder.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event,
                                              size: 14,
                                              color: item.detail.date != null
                                                  ? colors.drawerButton
                                                  : colors.matterCardText.withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.detail.dateFormatted,
                                              style: TextStyle(
                                                color: item.detail.date != null
                                                    ? colors.matterCardTitle
                                                    : colors.matterCardText.withValues(alpha: 0.6),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Badge Confianza
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: confColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: confColor.withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.psychology, size: 14, color: confColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.detail.confidenceLabel,
                                              style: TextStyle(
                                                color: confColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.edit_note_outlined,
                                        color: colors.drawerButton,
                                        size: 20,
                                      ),
                                    ],
                                  ),

                                  // Contenidos (si existen)
                                  if (hasContent) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colors.dimensionCardBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.menu_book, size: 13, color: colors.drawerButton),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Temas a evaluar:',
                                                style: TextStyle(
                                                  color: colors.drawerButton,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.detail.content,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colors.matterCardText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Apuntes (si existen)
                                  if (hasNotes) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colors.dimensionCardBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.notes, size: 13, color: colors.matterCardText),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Apuntes de estudio:',
                                                style: TextStyle(
                                                  color: colors.matterCardText,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.detail.notes,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colors.matterCardText.withValues(alpha: 0.8),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
