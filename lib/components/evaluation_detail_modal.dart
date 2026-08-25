import 'package:flutter/material.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/themes.dart';

class EvaluationDetailModal extends StatefulWidget {
  const EvaluationDetailModal({
    super.key,
    required this.matterTitle,
    required this.dimensionTitle,
    required this.noteIndex,
    required this.grade,
    required this.detail,
    required this.onSaveCB,
  });

  final String matterTitle;
  final String dimensionTitle;
  final int noteIndex;
  final double grade;
  final EvaluationDetail detail;
  final VoidCallback onSaveCB;

  @override
  State<EvaluationDetailModal> createState() => _EvaluationDetailModalState();
}

class _EvaluationDetailModalState extends State<EvaluationDetailModal> {
  DateTime? _selectedDate;
  int _confidenceLevel = 4;
  late TextEditingController _contentController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.detail.date;
    _confidenceLevel = widget.detail.confidenceLevel;
    _contentController = TextEditingController(text: widget.detail.content);
    _notesController = TextEditingController(text: widget.detail.notes);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = _selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Color _getConfidenceColor(int level, AppColors colors) {
    switch (level) {
      case 1:
      case 2:
        return const Color(0xFFEF4444); // Rojo alerta
      case 3:
        return const Color(0xFFF97316); // Naranja
      case 4:
        return const Color(0xFFEAB308); // Amarillo/Ámbar
      case 5:
        return const Color(0xFF10B981); // Verde esmeralda
      case 6:
        return const Color(0xFF3B82F6); // Azul
      case 7:
        return const Color(0xFF8B5CF6); // Violeta excelente
      default:
        return colors.drawerButton;
    }
  }

  String _getConfidenceText(int level) {
    switch (level) {
      case 1:
        return '1 - Nivel Crítico (Muy bajo)';
      case 2:
        return '2 - Nivel Bajo';
      case 3:
        return '3 - Nivel Insuficiente';
      case 4:
        return '4 - Nivel Aceptable / Medio';
      case 5:
        return '5 - Nivel Bueno';
      case 6:
        return '6 - Nivel Muy Bueno';
      case 7:
        return '7 - Nivel Excelente (Máxima confianza)';
      default:
        return '$level / 7';
    }
  }

  void _onSave() {
    widget.detail.date = _selectedDate;
    widget.detail.confidenceLevel = _confidenceLevel;
    widget.detail.content = _contentController.text.trim();
    widget.detail.notes = _notesController.text.trim();

    widget.onSaveCB();
    Navigator.pop(context);
  }

  void _onClear() {
    setState(() {
      _selectedDate = null;
      _confidenceLevel = 4;
      _contentController.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;
    final confidenceColor = _getConfidenceColor(_confidenceLevel, colors);

    return Container(
      color: colors.editMatterBackground,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            const SizedBox(height: 14),

            // Encabezado contextual
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.drawerButton.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.drawerButton.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Evaluación #${widget.noteIndex + 1}',
                    style: TextStyle(
                      color: colors.drawerButton,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.grade > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.noteGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nota: ${widget.grade.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: colors.editDimensionText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.matterTitle.isNotEmpty ? widget.matterTitle : 'Materia',
              style: TextStyle(
                color: colors.editDimensionText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.dimensionTitle.isNotEmpty)
              Text(
                widget.dimensionTitle,
                style: TextStyle(
                  color: colors.editDimensionText.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 18),

            // 1. Selector de Fecha
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: colors.noteFieldBorder),
              ),
              leading: Icon(Icons.event_outlined, color: colors.drawerButton),
              title: Text(
                'Fecha de la Evaluación',
                style: TextStyle(
                  color: colors.editDimensionText.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              subtitle: Text(
                _selectedDate != null ? _formatDate(_selectedDate!) : 'Toca para asignar fecha',
                style: TextStyle(
                  color: colors.editDimensionText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: _selectedDate != null
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colors.iconDeleteColor),
                      tooltip: 'Borrar fecha',
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                    )
                  : Icon(Icons.edit_calendar, color: colors.drawerButton),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),

            // 2. Nivel de Confianza (1 a 7)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.editDimensionBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.matterCardBorder.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nivel de Confianza / Preparación',
                        style: TextStyle(
                          color: colors.editDimensionText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: confidenceColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: confidenceColor, width: 1.2),
                        ),
                        child: Text(
                          '$_confidenceLevel / 7',
                          style: TextStyle(
                            color: confidenceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getConfidenceText(_confidenceLevel),
                    style: TextStyle(
                      color: confidenceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Selector de 1 a 7 en botones táctiles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final val = index + 1;
                      final isSelected = val == _confidenceLevel;
                      final col = _getConfidenceColor(val, colors);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _confidenceLevel = val;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? col : colors.noteFieldBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? col : colors.noteFieldBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '$val',
                            style: TextStyle(
                              color: isSelected ? Colors.white : colors.editDimensionText,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Contenidos de la Evaluación
            TextField(
              controller: _contentController,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: colors.editDimensionText),
              decoration: InputDecoration(
                labelText: 'Contenidos / Temas de la Evaluación',
                hintText: 'Ej: Capítulos 1 al 4, Integrales dobles, Modelos de optimización...',
                labelStyle: TextStyle(color: colors.editDimensionText),
                hintStyle: TextStyle(color: colors.editDimensionText.withValues(alpha: 0.5), fontSize: 13),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.menu_book_outlined),
                ),
                prefixIconColor: colors.drawerButton,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.drawerButton, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Apuntes y Recordatorios
            TextField(
              controller: _notesController,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: colors.editDimensionText),
              decoration: InputDecoration(
                labelText: 'Apuntes / Notas de Estudio',
                hintText: 'Ej: Llevar calculadora, repasar ejercicios de la guía 3, recordar teorema de Taylor...',
                labelStyle: TextStyle(color: colors.editDimensionText),
                hintStyle: TextStyle(color: colors.editDimensionText.withValues(alpha: 0.5), fontSize: 13),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.edit_note_outlined),
                ),
                prefixIconColor: colors.drawerButton,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.drawerButton, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botones de acción
            Row(
              children: [
                TextButton.icon(
                  icon: Icon(Icons.restart_alt, color: colors.editDimensionText.withValues(alpha: 0.7)),
                  label: Text('Limpiar', style: TextStyle(color: colors.editDimensionText.withValues(alpha: 0.7))),
                  onPressed: _onClear,
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.authButtonBackground,
                    foregroundColor: colors.authButtonText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _onSave,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
