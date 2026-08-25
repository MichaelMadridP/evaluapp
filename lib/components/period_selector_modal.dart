import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/components/edit_period.dart';
import 'package:evaluapp/themes.dart';

class PeriodSelectorModal extends StatefulWidget {
  const PeriodSelectorModal({
    super.key,
    required this.onPeriodChangedCB,
  });

  final VoidCallback onPeriodChangedCB;

  @override
  State<PeriodSelectorModal> createState() => _PeriodSelectorModalState();
}

class _PeriodSelectorModalState extends State<PeriodSelectorModal> {
  void _openCreatePeriod(BuildContext context) {
    final newPeriod = PeriodData(
      name: '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      builder: (ctx) {
        return EditPeriod(
          action: ActionType.add,
          period: newPeriod,
          onPeriodUpdateCB: () {
            setState(() {});
            widget.onPeriodChangedCB();
          },
          onPeriodDeleteCB: (id) {},
        );
      },
    );
  }

  void _openEditPeriod(BuildContext context, PeriodData period) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      builder: (ctx) {
        return EditPeriod(
          action: ActionType.edit,
          period: period,
          onPeriodUpdateCB: () {
            setState(() {});
            widget.onPeriodChangedCB();
          },
          onPeriodDeleteCB: (id) {
            setState(() {
              deletePeriod(id);
            });
            widget.onPeriodChangedCB();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;

    return Container(
      color: colors.editMatterBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Períodos Académicos',
                style: TextStyle(
                  color: colors.editDimensionText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: colors.drawerButton, size: 28),
                tooltip: 'Crear Nuevo Período',
                onPressed: () => _openCreatePeriod(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allPeriodsData.length,
              itemBuilder: (ctx, index) {
                final period = allPeriodsData[index];
                final bool isActive = activePeriod?.id == period.id;
                final dateRange = period.dateRangeFormatted;
                final int count = period.matters.length;

                return Card(
                  color: isActive
                      ? colors.dimensionCardBackground
                      : colors.editDimensionBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isActive
                          ? colors.drawerButton
                          : colors.matterCardBorder.withValues(alpha: 0.3),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: isActive ? 2 : 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setActivePeriod(period.id);
                      widget.onPeriodChangedCB();
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isActive ? colors.drawerButton : colors.noteFieldBorder,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  period.name,
                                  style: TextStyle(
                                    color: colors.editDimensionText,
                                    fontSize: 16,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                                if (dateRange.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    dateRange,
                                    style: TextStyle(
                                      color: colors.editDimensionText.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.noteFieldBorder.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$count ${count == 1 ? "materia" : "materias"}',
                                    style: TextStyle(
                                      color: colors.editDimensionText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: colors.editDimensionText.withValues(alpha: 0.8)),
                            tooltip: 'Editar Período',
                            onPressed: () => _openEditPeriod(context, period),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.authButtonBackground,
              foregroundColor: colors.authButtonText,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Crear Nuevo Período',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _openCreatePeriod(context),
          ),
        ],
      ),
    );
  }
}
