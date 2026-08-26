import 'package:evaluapp/data_model/model.dart';

class PeriodReportService {
  /// Retorna el asunto estándar del correo para el reporte del período
  static String generateSubject({
    required PeriodData period,
    String? userName,
  }) {
    final userSuffix =
        (userName != null && userName.trim().isNotEmpty) ? ' - $userName' : '';
    return '[EvaluApp] Reporte de Avance Académico: ${period.name}$userSuffix';
  }

  /// Construye un resumen consolidado de las estadísticas del período
  static Map<String, dynamic> calculatePeriodStats(PeriodData period) {
    period.calculate();

    int totalMatters = period.matters.length;
    int totalNotes = 0;
    int completedNotes = 0;
    int pendingNotes = 0;
    double sumAverages = 0;
    int mattersWithAverage = 0;
    int onTrackMatters = 0;

    for (var m in period.matters) {
      m.calculate();
      if (m.average > 0) {
        sumAverages += m.average;
        mattersWithAverage++;
        if (m.average >= m.targetNote) {
          onTrackMatters++;
        }
      }

      for (var d in m.dimension) {
        totalNotes += d.numNotes;
        for (int i = 0; i < d.numNotes; i++) {
          final val = (i < d.noteList.length) ? d.noteList[i] : 0.0;
          if (val > 0) {
            completedNotes++;
          } else {
            pendingNotes++;
          }
        }
      }
    }

    final double overallAverage =
        mattersWithAverage > 0 ? (sumAverages / mattersWithAverage) : 0.0;

    return {
      'totalMatters': totalMatters,
      'totalNotes': totalNotes,
      'completedNotes': completedNotes,
      'pendingNotes': pendingNotes,
      'overallAverage': overallAverage,
      'onTrackMatters': onTrackMatters,
    };
  }

  static String _generateProgressBar(int completed, int total, {int length = 8}) {
    if (total <= 0) return '${'▱' * length} 0%';
    final ratio = (completed / total).clamp(0.0, 1.0);
    final filled = (ratio * length).round();
    final empty = length - filled;
    final percent = (ratio * 100).round();
    return '${'▰' * filled}${'▱' * empty} $percent%';
  }

  static String _confidenceBadge(int level) {
    switch (level) {
      case 1:
        return '🔴 Muy Baja (1/5)';
      case 2:
        return '🟠 Baja (2/5)';
      case 3:
        return '🟡 Regular (3/5)';
      case 4:
        return '🟢 Buena (4/5)';
      case 5:
        return '⭐ Excelente (5/5)';
      default:
        return '⚪ Sin definir';
    }
  }

  /// Genera el reporte en formato Texto Plano / Markdown (ideal para apps de correo y compartir)
  static String generatePlainTextReport({
    required PeriodData period,
    required String userName,
    required bool includeStudyPlan,
  }) {
    period.calculate();
    final stats = calculatePeriodStats(period);
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final buffer = StringBuffer();

    // ==========================================
    // ENCABEZADO
    // ==========================================
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(' 📊 EVALUAPP - REPORTE DE AVANCE ACADÉMICO');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(' 👤 Estudiante:        $userName');
    buffer.writeln(' 📅 Período:           ${period.name}');
    if (period.dateRangeFormatted.isNotEmpty) {
      buffer.writeln(' 🗓️  Vigencia:          ${period.dateRangeFormatted}');
    }
    buffer.writeln(' ⏰ Fecha de Emisión:  $dateStr');
    buffer.writeln('');

    // ==========================================
    // RESUMEN GENERAL
    // ==========================================
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(' 📈 RESUMEN GENERAL DEL PERÍODO');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final double overallAvg = stats['overallAverage'] as double;
    final avgFormatted = overallAvg > 0 ? overallAvg.toStringAsFixed(1) : 'Sin notas';
    final int totalN = stats['totalNotes'] as int;
    final int compN = stats['completedNotes'] as int;
    final progressGlobalBar = _generateProgressBar(compN, totalN);

    buffer.writeln(' • Promedio General Actual:  $avgFormatted');
    buffer.writeln(' • Progreso Global de Notas: $progressGlobalBar ($compN de $totalN)');
    buffer.writeln(' • Materias Registradas:     ${stats['totalMatters']}');
    buffer.writeln(' • Evaluaciones Rendidas:    $compN de $totalN');
    buffer.writeln(' • Evaluaciones Pendientes:  ${stats['pendingNotes']}');
    buffer.writeln('');

    // ==========================================
    // DETALLE POR MATERIA
    // ==========================================
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(' 📚 ESTADO DETALLADO POR MATERIA');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (period.matters.isEmpty) {
      buffer.writeln('No hay materias registradas en este período.');
      buffer.writeln('');
    } else {
      for (int i = 0; i < period.matters.length; i++) {
        final matter = period.matters[i];
        matter.calculate();

        final avgStr = matter.average > 0
            ? matter.average.toStringAsFixed(1)
            : 'Sin notas registradas';

        // Contar notas obtenidas y faltantes de la materia
        int matterPendingNotes = 0;
        int matterCompletedNotes = 0;

        for (var dim in matter.dimension) {
          for (int n = 0; n < dim.numNotes; n++) {
            final grade = (n < dim.noteList.length) ? dim.noteList[n] : 0.0;
            if (grade > 0) {
              matterCompletedNotes++;
            } else {
              matterPendingNotes++;
            }
          }
        }

        final int matterTotal = matterCompletedNotes + matterPendingNotes;
        final progressBar = _generateProgressBar(matterCompletedNotes, matterTotal);

        buffer.writeln('');
        buffer.writeln('┌───────────────────────────────────────────────────');
        buffer.writeln('│ 📖 [${i + 1}] ${matter.matterTitle.toUpperCase()}');
        buffer.writeln('│    • Promedio Actual:  $avgStr');
        buffer.writeln('│    • Nota Objetivo: ${matter.targetNote.toStringAsFixed(1)}');
        buffer.writeln('│    • Avance de Notas:  $progressBar ($matterCompletedNotes obtenidas / $matterPendingNotes pendientes)');

        // Requerimiento para nota objetivo
        if (matter.isFinal()) {
          buffer.writeln('│    • Estado: ✅ Materia Finalizada (Promedio Final: ${matter.average.toStringAsFixed(1)})');
        } else if (matter.minimumRequired > 0) {
          String reqStr;
          if (matter.minimumRequired < 1.0) {
            reqStr = '1.0 (Meta alcanzada con nota mínima)';
          } else if (matter.minimumRequired > 7.0) {
            reqStr = '> 7.0 (Inalcanzable matemáticamente)';
          } else {
            reqStr = matter.minimumRequired.toStringAsFixed(1);
          }
          buffer.writeln('│    • Nota Requerida en Evaluaciones Restantes: $reqStr');
        } else {
          buffer.writeln('│    • Nota Requerida: Pendiente de inicio');
        }

        // Desglose de dimensiones
        buffer.writeln('├───────────────────────────────────────────────────');
        buffer.writeln('│ 🔹 Dimensiones y Calificaciones:');
        for (var dim in matter.dimension) {
          final List<String> obtainedGrades = [];
          int dimPendingCount = 0;

          for (int n = 0; n < dim.numNotes; n++) {
            final grade = (n < dim.noteList.length) ? dim.noteList[n] : 0.0;
            if (grade > 0) {
              obtainedGrades.add(grade.toStringAsFixed(1));
            } else {
              dimPendingCount++;
            }
          }

          final gradesText = obtainedGrades.isNotEmpty
              ? obtainedGrades.join(', ')
              : 'Ninguna';
          final worstNoteText = dim.removeWorstNote ? ' [Elimina peor nota]' : '';

          buffer.writeln('│    • ${dim.dimensionTitle} (${dim.percentageWeight}%)$worstNoteText:');
          buffer.writeln('│      - Notas obtenidas: $gradesText');
          buffer.writeln('│      - Notas faltantes: $dimPendingCount');
        }

        // Plan de estudio para notas faltantes de esta materia
        if (includeStudyPlan) {
          final List<Map<String, dynamic>> pendingPlan = [];
          for (var dim in matter.dimension) {
            for (int n = 0; n < dim.numNotes; n++) {
              final grade = (n < dim.noteList.length) ? dim.noteList[n] : 0.0;
              if (grade == 0) {
                final detail = (n < dim.evaluationDetails.length)
                    ? dim.evaluationDetails[n]
                    : EvaluationDetail();
                pendingPlan.add({
                  'dimension': dim.dimensionTitle,
                  'noteIndex': n + 1,
                  'detail': detail,
                });
              }
            }
          }

          if (pendingPlan.isNotEmpty) {
            buffer.writeln('│');
            buffer.writeln('│ 🎯 Plan de Estudio (Evaluaciones Faltantes):');
            for (var p in pendingPlan) {
              final String dimName = p['dimension'];
              final int nIdx = p['noteIndex'];
              final EvaluationDetail detail = p['detail'];
              final confBadge = _confidenceBadge(detail.confidenceLevel);

              buffer.writeln('│    📌 $dimName (Nota #$nIdx):');
              buffer.writeln('│       • Fecha prevista:     ${detail.dateFormatted}');
              buffer.writeln('│       • Nivel de confianza: $confBadge');
              if (detail.content.trim().isNotEmpty) {
                buffer.writeln('│       • Temario/Contenido:  ${detail.content.trim()}');
              }
              if (detail.notes.trim().isNotEmpty) {
                buffer.writeln('│       • Apuntes/Estrategia: ${detail.notes.trim()}');
              }
            }
          }
        }

        buffer.writeln('└───────────────────────────────────────────────────');
      }
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(' Generado automáticamente por EvaluApp');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return buffer.toString();
  }

  /// Genera el reporte en formato HTML con diseño limpio y compatible con clientes de correo
  static String generateHtmlReport({
    required PeriodData period,
    required String userName,
    required bool includeStudyPlan,
  }) {
    period.calculate();
    final stats = calculatePeriodStats(period);
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final double overallAvg = stats['overallAverage'] as double;
    final String avgFormatted =
        overallAvg > 0 ? overallAvg.toStringAsFixed(1) : '-';

    final buffer = StringBuffer();

    buffer.write('''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reporte Académico EvaluApp</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0f0a1c; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #f1f5f9;">
  <table width="100%" border="0" cellpadding="0" cellspacing="0" style="background-color: #0f0a1c; padding: 24px 12px;">
    <tr>
      <td align="center">
        <!-- Contenedor Principal -->
        <table width="100%" border="0" cellpadding="0" cellspacing="0" style="max-width: 600px; background-color: #1e162f; border-radius: 16px; overflow: hidden; border: 1px solid #3b2d5a; box-shadow: 0 10px 25px rgba(0,0,0,0.5);">
          
          <!-- Banner Superior -->
          <tr>
            <td style="background: linear-gradient(135deg, #7c3aed 0%, #4c1d95 100%); padding: 28px 24px; text-align: center;">
              <table width="100%" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <span style="display: inline-block; background-color: rgba(255,255,255,0.15); padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: bold; letter-spacing: 1px; color: #ffffff; text-transform: uppercase;">Informe Académico</span>
                    <h1 style="margin: 8px 0 4px 0; color: #ffffff; font-size: 24px; font-weight: 800;">EvaluApp</h1>
                    <p style="margin: 0; color: #e9d5ff; font-size: 14px;">${period.name}</p>
                    ${period.dateRangeFormatted.isNotEmpty ? '<p style="margin: 4px 0 0 0; color: #c4b5fd; font-size: 12px;">${period.dateRangeFormatted}</p>' : ''}
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Metadata del Alumno -->
          <tr>
            <td style="padding: 16px 24px; background-color: #261c3b; border-bottom: 1px solid #3b2d5a;">
              <table width="100%" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="color: #cbd5e1; font-size: 13px;">
                    👤 <strong>Estudiante:</strong> <span style="color: #ffffff;">$userName</span>
                  </td>
                  <td align="right" style="color: #94a3b8; font-size: 12px;">
                    📅 $dateStr
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Resumen de Métricas -->
          <tr>
            <td style="padding: 20px 24px 10px 24px;">
              <table width="100%" border="0" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="32%" style="background-color: #2b1f44; border-radius: 12px; padding: 14px; text-align: center; border: 1px solid #4a3873;">
                    <div style="font-size: 11px; color: #a78bfa; text-transform: uppercase; font-weight: bold;">Promedio</div>
                    <div style="font-size: 22px; font-weight: 800; color: ${overallAvg >= 4.0 ? '#4ade80' : (overallAvg > 0 ? '#f87171' : '#94a3b8')}; margin-top: 4px;">$avgFormatted</div>
                  </td>
                  <td width="2%"></td>
                  <td width="32%" style="background-color: #2b1f44; border-radius: 12px; padding: 14px; text-align: center; border: 1px solid #4a3873;">
                    <div style="font-size: 11px; color: #a78bfa; text-transform: uppercase; font-weight: bold;">Materias</div>
                    <div style="font-size: 22px; font-weight: 800; color: #ffffff; margin-top: 4px;">${stats['totalMatters']}</div>
                  </td>
                  <td width="2%"></td>
                  <td width="32%" style="background-color: #2b1f44; border-radius: 12px; padding: 14px; text-align: center; border: 1px solid #4a3873;">
                    <div style="font-size: 11px; color: #a78bfa; text-transform: uppercase; font-weight: bold;">Pendientes</div>
                    <div style="font-size: 22px; font-weight: 800; color: #fbbf24; margin-top: 4px;">${stats['pendingNotes']}</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Lista de Materias -->
          <tr>
            <td style="padding: 10px 24px 24px 24px;">
              <h2 style="font-size: 16px; color: #e2e8f0; margin: 16px 0 12px 0; border-bottom: 2px solid #7c3aed; padding-bottom: 6px; display: inline-block;">
                📚 Estado por Materia
              </h2>
''');

    if (period.matters.isEmpty) {
      buffer.write('''
              <div style="background-color: #261c3b; border-radius: 12px; padding: 20px; text-align: center; color: #94a3b8; font-size: 14px;">
                No hay materias registradas en este período académico.
              </div>
''');
    } else {
      for (var matter in period.matters) {
        matter.calculate();

        final double avg = matter.average;
        final String avgText = avg > 0 ? avg.toStringAsFixed(1) : '-';
        final String avgColor = avg >= 4.0 ? '#4ade80' : (avg > 0 ? '#f87171' : '#94a3b8');

        int matterPending = 0;
        int matterCompleted = 0;
        for (var dim in matter.dimension) {
          for (int n = 0; n < dim.numNotes; n++) {
            final grade = (n < dim.noteList.length) ? dim.noteList[n] : 0.0;
            if (grade > 0) {
              matterCompleted++;
            } else {
              matterPending++;
            }
          }
        }

        String reqText = '-';
        String reqColor = '#94a3b8';
        if (matter.isFinal()) {
          reqText = 'Finalizada';
          reqColor = '#4ade80';
        } else if (matter.minimumRequired > 0) {
          if (matter.minimumRequired < 1.0) {
            reqText = '1.0 (Aprobado)';
            reqColor = '#4ade80';
          } else if (matter.minimumRequired > 7.0) {
            reqText = '> 7.0';
            reqColor = '#f87171';
          } else {
            reqText = matter.minimumRequired.toStringAsFixed(1);
            reqColor = matter.minimumRequired <= 4.0 ? '#4ade80' : '#fbbf24';
          }
        }

        buffer.write('''
              <!-- Tarjeta Materia -->
              <div style="background-color: #261c3b; border: 1px solid #3b2d5a; border-radius: 14px; padding: 18px; margin-bottom: 16px;">
                
                <!-- Encabezado Materia -->
                <table width="100%" border="0" cellpadding="0" cellspacing="0" style="margin-bottom: 12px;">
                  <tr>
                    <td>
                      <h3 style="margin: 0; font-size: 17px; font-weight: 700; color: #ffffff;">${matter.matterTitle}</h3>
                      <span style="font-size: 11px; color: #a78bfa;">Meta Objetivo: <strong>${matter.targetNote.toStringAsFixed(1)}</strong></span>
                    </td>
                    <td align="right">
                      <span style="background-color: #1e162f; border: 1px solid #4a3873; border-radius: 8px; padding: 4px 10px; font-size: 12px; color: #cbd5e1;">
                        Promedio: <strong style="color: $avgColor; font-size: 14px;">$avgText</strong>
                      </span>
                    </td>
                  </tr>
                </table>

                <!-- Indicadores de Avance y Requerimiento -->
                <table width="100%" border="0" cellpadding="0" cellspacing="0" style="background-color: #1e162f; border-radius: 10px; padding: 10px 14px; margin-bottom: 12px; font-size: 12px;">
                  <tr>
                    <td style="color: #cbd5e1;">
                      📊 <strong>Progreso:</strong> $matterCompleted de ${matterCompleted + matterPending} notas
                    </td>
                    <td align="right" style="color: #cbd5e1;">
                      🎯 <strong>Nota Requerida:</strong> <strong style="color: $reqColor; font-size: 13px;">$reqText</strong>
                    </td>
                  </tr>
                </table>

                <!-- Desglose de Dimensiones -->
                <table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 12px; color: #cbd5e1; border-collapse: collapse;">
''');

        for (var dim in matter.dimension) {
          final List<String> grades = [];
          int dimPending = 0;
          for (int n = 0; n < dim.numNotes; n++) {
            final g = (n < dim.noteList.length) ? dim.noteList[n] : 0.0;
            if (g > 0) {
              grades.add(g.toStringAsFixed(1));
            } else {
              dimPending++;
            }
          }

          final gradesBadges = grades.isNotEmpty
              ? grades.map((g) {
                  final double numG = double.tryParse(g) ?? 0;
                  final badgeBg = numG >= 4.0 ? 'rgba(74, 222, 128, 0.15)' : 'rgba(248, 113, 113, 0.15)';
                  final badgeColor = numG >= 4.0 ? '#4ade80' : '#f87171';
                  return '<span style="display: inline-block; background-color: $badgeBg; color: $badgeColor; font-weight: bold; border-radius: 6px; padding: 2px 6px; margin: 1px 3px; font-size: 11px;">$g</span>';
                }).join('')
              : '<span style="color: #64748b; font-style: italic;">Sin notas</span>';

          final pendingBadge = dimPending > 0
              ? '<span style="color: #fbbf24; font-size: 11px;">($dimPending pend.)</span>'
              : '<span style="color: #4ade80; font-size: 11px;">(Completa)</span>';

          buffer.write('''
                  <tr>
                    <td style="padding: 6px 0; border-bottom: 1px dashed #372952;">
                      <strong>${dim.dimensionTitle}</strong> <span style="color: #a78bfa; font-size: 11px;">(${dim.percentageWeight}%)</span>:
                    </td>
                    <td align="right" style="padding: 6px 0; border-bottom: 1px dashed #372952;">
                      $gradesBadges $pendingBadge
                    </td>
                  </tr>
''');
        }

        buffer.write('''
                </table>
''');

        // Plan de estudio para notas faltantes
        if (includeStudyPlan) {
          final List<Map<String, dynamic>> pendingPlan = [];
          for (var dim in matter.dimension) {
            for (int n = 0; n < dim.numNotes; n++) {
              final grade = (n < dim.noteList.length) ? dim.noteList[n] : 0.0;
              if (grade == 0) {
                final detail = (n < dim.evaluationDetails.length)
                    ? dim.evaluationDetails[n]
                    : EvaluationDetail();
                pendingPlan.add({
                  'dimension': dim.dimensionTitle,
                  'noteIndex': n + 1,
                  'detail': detail,
                });
              }
            }
          }

          if (pendingPlan.isNotEmpty) {
            buffer.write('''
                <!-- Sección Plan de Estudio -->
                <div style="margin-top: 14px; padding-top: 12px; border-top: 1px solid #3b2d5a;">
                  <div style="font-size: 12px; font-weight: bold; color: #a78bfa; margin-bottom: 8px;">
                    🎯 Plan de Estudio - Evaluaciones Pendientes
                  </div>
''');

            for (var p in pendingPlan) {
              final String dimName = p['dimension'];
              final int nIdx = p['noteIndex'];
              final EvaluationDetail detail = p['detail'];

              String confColor;
              if (detail.confidenceLevel <= 2) {
                confColor = '#ef4444'; // Crítico/Bajo
              } else if (detail.confidenceLevel <= 4) {
                confColor = '#f59e0b'; // Regular/Aceptable
              } else {
                confColor = '#3b82f6'; // Bueno/Excelente
              }

              buffer.write('''
                  <div style="background-color: #1a1229; border-radius: 8px; padding: 10px 12px; margin-bottom: 8px; border-left: 3px solid $confColor;">
                    <table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 12px;">
                      <tr>
                        <td>
                          <strong style="color: #ffffff;">$dimName (Nota #$nIdx)</strong>
                        </td>
                        <td align="right" style="color: #94a3b8; font-size: 11px;">
                          🗓️ ${detail.dateFormatted}
                        </td>
                      </tr>
                      <tr>
                        <td colspan="2" style="padding-top: 4px;">
                          <span style="display: inline-block; background-color: rgba(255,255,255,0.08); color: $confColor; border-radius: 4px; padding: 1px 6px; font-size: 10px; font-weight: bold;">
                            Confianza: ${detail.confidenceLabel}
                          </span>
                        </td>
                      </tr>
                      ${detail.content.trim().isNotEmpty ? '<tr><td colspan="2" style="padding-top: 6px; color: #e2e8f0; font-size: 11px;">📖 <strong>Temas:</strong> ${detail.content.trim()}</td></tr>' : ''}
                      ${detail.notes.trim().isNotEmpty ? '<tr><td colspan="2" style="padding-top: 4px; color: #cbd5e1; font-size: 11px; font-style: italic;">📝 <strong>Apuntes:</strong> ${detail.notes.trim()}</td></tr>' : ''}
                    </table>
                  </div>
''');
            }

            buffer.write('''
                </div>
''');
          }
        }

        buffer.write('''
              </div>
''');
      }
    }

    buffer.write('''
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #140f21; padding: 20px 24px; text-align: center; border-top: 1px solid #3b2d5a;">
              <p style="margin: 0; color: #94a3b8; font-size: 12px;">
                Generado automáticamente por <strong style="color: #a78bfa;">EvaluApp</strong> &copy; ${now.year}
              </p>
              <p style="margin: 4px 0 0 0; color: #64748b; font-size: 11px;">
                Monitorea tus calificaciones y alcanza tus metas académicas.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''');

    return buffer.toString();
  }

  /// Construye un enlace URI 'mailto:' listo para despachar con los clientes de correo
  static Uri generateMailtoUri({
    required List<String> recipients,
    required String subject,
    required String body,
  }) {
    return Uri(
      scheme: 'mailto',
      path: recipients.join(','),
      query: _encodeQueryParameters({
        'subject': subject,
        'body': body,
      }),
    );
  }

  static String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
