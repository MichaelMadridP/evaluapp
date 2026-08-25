import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/themes.dart';

class EditPeriod extends StatefulWidget {
  const EditPeriod({
    super.key,
    required this.action,
    required this.period,
    required this.onPeriodUpdateCB,
    required this.onPeriodDeleteCB,
  });

  final ActionType action;
  final PeriodData period;
  final VoidCallback onPeriodUpdateCB;
  final Function(String periodId) onPeriodDeleteCB;

  @override
  State<EditPeriod> createState() => _EditPeriodState();
}

class _EditPeriodState extends State<EditPeriod> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.period.name;
    _startDate = widget.period.startDate;
    _endDate = widget.period.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final initialDate = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _errorMessage = '';
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final initialDate = _endDate ?? (_startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _errorMessage = '';
      });
    }
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'El nombre del período no puede estar vacío.';
      });
      return;
    }

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      setState(() {
        _errorMessage = 'La fecha de término no puede ser anterior a la fecha de inicio.';
      });
      return;
    }

    widget.period.name = name;
    widget.period.startDate = _startDate;
    widget.period.endDate = _endDate;

    if (widget.action == ActionType.add) {
      addPeriod(widget.period);
    } else {
      updatePeriod(widget.period);
    }

    widget.onPeriodUpdateCB();
    Navigator.pop(context);
  }

  void _onDelete() {
    final colors = ThemeProvider.of(context)!.colors;
    final int matterCount = widget.period.matters.length;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.editMatterBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.iconDeleteColor, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  matterCount > 0 ? '¿Eliminar período en uso?' : '¿Eliminar período?',
                  style: TextStyle(
                    color: colors.editDimensionText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            matterCount > 0
                ? 'Este período contiene $matterCount ${matterCount == 1 ? "materia" : "materias"} registradas con sus notas.\n\nAl eliminar "${widget.period.name}", se perderán permanentemente todas las materias y evaluaciones asociadas.'
                : '¿Estás seguro de eliminar el período "${widget.period.name}"?',
            style: TextStyle(color: colors.editDimensionText, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(color: colors.editDimensionText),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.iconDeleteColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx); // Cierra diálogo
                widget.onPeriodDeleteCB(widget.period.id);
                Navigator.pop(context); // Cierra modal de edición
              },
              child: const Text('Eliminar Todo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;
    final isAdd = widget.action == ActionType.add;
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        color: colors.editMatterBackground,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: keyboardInset + bottomSafeArea + 24,
        ),
        child: SingleChildScrollView(
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
            Text(
              isAdd ? 'Crear Nuevo Período' : 'Editar Período',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.editDimensionText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Nombre del Período
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: colors.editDimensionText),
              decoration: InputDecoration(
                labelText: 'Nombre del Período *',
                hintText: 'Ej: Primer Semestre 2026, Trimestre 1',
                labelStyle: TextStyle(color: colors.editDimensionText),
                hintStyle: TextStyle(color: colors.editDimensionText.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.school_outlined, color: colors.drawerButton),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.drawerButton, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fecha de Inicio (Opcional)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: colors.noteFieldBorder),
              ),
              leading: Icon(Icons.calendar_today_outlined, color: colors.drawerButton),
              title: Text(
                'Fecha de Inicio (Opcional)',
                style: TextStyle(
                  color: colors.editDimensionText.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              subtitle: Text(
                _startDate != null ? _formatDate(_startDate!) : 'Sin fecha definida',
                style: TextStyle(
                  color: colors.editDimensionText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: _startDate != null
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colors.iconDeleteColor),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                    )
                  : IconButton(
                      icon: Icon(Icons.edit_calendar, color: colors.drawerButton),
                      onPressed: () => _selectStartDate(context),
                    ),
              onTap: () => _selectStartDate(context),
            ),
            const SizedBox(height: 12),

            // Fecha de Término (Opcional)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: colors.noteFieldBorder),
              ),
              leading: Icon(Icons.event_available_outlined, color: colors.drawerButton),
              title: Text(
                'Fecha de Término (Opcional)',
                style: TextStyle(
                  color: colors.editDimensionText.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              subtitle: Text(
                _endDate != null ? _formatDate(_endDate!) : 'Sin fecha definida',
                style: TextStyle(
                  color: colors.editDimensionText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: _endDate != null
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colors.iconDeleteColor),
                      onPressed: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    )
                  : IconButton(
                      icon: Icon(Icons.edit_calendar, color: colors.drawerButton),
                      onPressed: () => _selectEndDate(context),
                    ),
              onTap: () => _selectEndDate(context),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: TextStyle(color: colors.errorTextColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isAdd) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: colors.iconDeleteColor,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                    onPressed: _onDelete,
                  ),
                  const Spacer(),
                ],
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.authButtonBackground,
                    foregroundColor: colors.authButtonText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _onSave,
                  child: Text(isAdd ? 'Crear Período' : 'Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
