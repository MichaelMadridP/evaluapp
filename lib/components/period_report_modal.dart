import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/data_connect.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:evaluapp/services/period_report_service.dart';
import 'package:evaluapp/themes.dart';
import 'package:url_launcher/url_launcher.dart';

class PeriodReportModal extends StatefulWidget {
  const PeriodReportModal({
    super.key,
    this.initialPeriod,
  });

  final PeriodData? initialPeriod;

  @override
  State<PeriodReportModal> createState() => _PeriodReportModalState();
}

class _PeriodReportModalState extends State<PeriodReportModal> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  late PeriodData _selectedPeriod;
  final List<String> _recipients = [];
  bool _includeStudyPlan = true;
  bool _showPreview = false;
  bool _isSending = false;

  final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    // Determinar período a reportar
    _selectedPeriod = widget.initialPeriod ?? activePeriod ?? (allPeriodsData.isNotEmpty ? allPeriodsData.first : PeriodData(name: 'Sin período'));
    // Cargar lista de destinatarios recordados
    _recipients.addAll(getReportRecipients());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _addEmail(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;

    // Permitir ingresar múltiples emails separados por coma o espacio
    final parts = text.split(RegExp(r'[,;\s]+'));
    bool addedAny = false;
    String? invalidEmail;

    for (final part in parts) {
      final clean = part.trim();
      if (clean.isEmpty) continue;

      if (!_emailRegex.hasMatch(clean)) {
        invalidEmail = clean;
        continue;
      }

      if (!_recipients.contains(clean)) {
        _recipients.add(clean);
        addedAny = true;
      }
    }

    if (addedAny) {
      saveReportRecipients(_recipients);
      _emailController.clear();
      setState(() {});
    }

    if (invalidEmail != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Formato de correo no válido: $invalidEmail'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeEmail(int index) {
    setState(() {
      _recipients.removeAt(index);
      saveReportRecipients(_recipients);
    });
  }

  String _getUserName() {
    return getStringPreference('username') ?? 'Estudiante';
  }

  Future<void> _sendReport() async {
    if (_recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa al menos un correo destinatario.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _emailFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isSending = true;
    });

    final userName = _getUserName();
    final subject = PeriodReportService.generateSubject(
      period: _selectedPeriod,
      userName: userName,
    );
    final body = PeriodReportService.generatePlainTextReport(
      period: _selectedPeriod,
      userName: userName,
      includeStudyPlan: _includeStudyPlan,
    );

    final mailtoUri = PeriodReportService.generateMailtoUri(
      recipients: _recipients,
      subject: subject,
      body: body,
    );

    try {
      final canLaunch = await canLaunchUrl(mailtoUri);
      if (canLaunch) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      } else {
        // En caso de que no haya cliente por defecto configurado, copiar al portapapeles
        await Clipboard.setData(ClipboardData(text: body));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No se pudo abrir el cliente de correo. Reporte copiado al portapapeles.'),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: body));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte copiado al portapapeles (Nota: $e)'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    final userName = _getUserName();
    final body = PeriodReportService.generatePlainTextReport(
      period: _selectedPeriod,
      userName: userName,
      includeStudyPlan: _includeStudyPlan,
    );

    Clipboard.setData(ClipboardData(text: body));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Reporte copiado al portapapeles'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeProvider.of(context)!.colors;
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    final userName = _getUserName();
    final previewText = PeriodReportService.generatePlainTextReport(
      period: _selectedPeriod,
      userName: userName,
      includeStudyPlan: _includeStudyPlan,
    );

    return SafeArea(
      top: false,
      child: Container(
        color: colors.editMatterBackground,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 16,
          bottom: keyboardInset + bottomSafeArea + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de arrastre superior
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

            // Encabezado del Modal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      color: colors.drawerButton,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Reporte del Período',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.editDimensionText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.editDimensionText),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contenido desplazable
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector de Período
                    if (allPeriodsData.length > 1) ...[
                      Text(
                        'Período Académico',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.editDimensionText.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.editDimensionBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.noteFieldBorder,
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PeriodData>(
                            value: allPeriodsData.any((p) => p.id == _selectedPeriod.id)
                                ? allPeriodsData.firstWhere((p) => p.id == _selectedPeriod.id)
                                : allPeriodsData.first,
                            dropdownColor: colors.editMatterBackground,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: colors.editDimensionText),
                            items: allPeriodsData.map((period) {
                              return DropdownMenuItem<PeriodData>(
                                value: period,
                                child: Text(
                                  period.name,
                                  style: TextStyle(
                                    color: colors.editDimensionText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newPeriod) {
                              if (newPeriod != null) {
                                setState(() {
                                  _selectedPeriod = newPeriod;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Sección de Destinatarios
                    Text(
                      'Destinatarios (Mails)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.editDimensionText.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Input para agregar email
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: colors.editDimensionText),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'ej: profesor@mail.com, papa@gmail.com',
                              hintStyle: TextStyle(
                                color: colors.editDimensionText
                                    .withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: colors.noteFieldBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: colors.drawerButton, width: 1.5),
                              ),
                            ),
                            onSubmitted: _addEmail,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => _addEmail(_emailController.text),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.drawerButton,
                            foregroundColor: colors.drawerText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          tooltip: 'Agregar correo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chips de correos agregados
                    if (_recipients.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(_recipients.length, (index) {
                          final email = _recipients[index];
                          return Chip(
                            label: Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.editDimensionText,
                              ),
                            ),
                            backgroundColor: colors.editDimensionBackground,
                            deleteIcon: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: colors.editDimensionText
                                  .withValues(alpha: 0.7),
                            ),
                            onDeleted: () => _removeEmail(index),
                            side: BorderSide(
                              color: colors.noteFieldBorder,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        }),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Sin destinatarios agregados aún.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: colors.editDimensionText
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Switch: Incluir Plan de Estudio
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.editDimensionBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.matterCardBorder.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            color: colors.drawerButton,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Incluir Plan de Estudio',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colors.editDimensionText,
                                  ),
                                ),
                                Text(
                                  'Detalla fechas, nivel de confianza y apuntes de notas faltantes',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.editDimensionText
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _includeStudyPlan,
                            activeThumbColor: colors.drawerButton,
                            onChanged: (val) {
                              setState(() {
                                _includeStudyPlan = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botón para alternar previsualización
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showPreview = !_showPreview;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showPreview
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 16,
                              color: colors.drawerButton,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showPreview
                                  ? 'Ocultar vista previa'
                                  : 'Ver vista previa del reporte',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.drawerButton,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Caja de previsualización
                    if (_showPreview) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.matterCardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.matterCardBorder,
                          ),
                        ),
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            previewText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: colors.editDimensionText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botones de Acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.editDimensionText,
                      side: BorderSide(color: colors.noteFieldBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text(
                      'Copiar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.drawerButton,
                      foregroundColor: colors.drawerText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSending ? 'Abriendo Correo...' : 'Enviar Reporte',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
