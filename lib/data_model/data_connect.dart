import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Lista global de períodos
List<PeriodData> allPeriodsData = [];

// Período activo actualmente seleccionado
PeriodData? activePeriod;

// Fallback en caso de que aún no haya período cargado
final List<MatterData> _fallbackMatters = [];

// Base de las materias del período activo (retrocompatibilidad)
List<MatterData> get allMattersData {
  if (activePeriod != null) {
    return activePeriod!.matters;
  }
  if (allPeriodsData.isNotEmpty) {
    activePeriod = allPeriodsData.first;
    return activePeriod!.matters;
  }
  return _fallbackMatters;
}

Timer? _saveDebounceTimer;
Future<void>? _activeGetDataFuture;
String? _activeGetDataUserId;

/// Limpia los datos de sesión en memoria y cancela temporizadores pendientes
void clearSessionData() {
  _saveDebounceTimer?.cancel();
  _activeGetDataFuture = null;
  _activeGetDataUserId = null;
  allPeriodsData.clear();
  activePeriod = null;
  _fallbackMatters.clear();
}

Future<void> createNewUserOnDatabase(
    String userId, String userDisplayName, String userEmail) async {
  String userNodePath = 'users/$userId/user';
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref(userNodePath);

  try {
    await dbRef.set({
      'userDisplayName': userDisplayName,
      'userEmail': userEmail,
    });
  } catch (e) {
    throw Exception('Error al escribir usuario en la base de datos: $e');
  }
}

Future<void> _executeSave() async {
  try {
    String? userId;
    try {
      userId = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    userId ??= getStringPreference('userid');

    if (userId != null && userId.isNotEmpty) {
      final DatabaseReference rootRef =
          FirebaseDatabase.instance.ref('users/$userId');

      // Construir mapa de períodos con clave periodId
      final Map<String, dynamic> periodsMap = {};
      for (var period in allPeriodsData) {
        periodsMap[period.id] = period.toMap();
      }

      final currentActiveId = activePeriod?.id ??
          (allPeriodsData.isNotEmpty ? allPeriodsData.first.id : '');

      await rootRef.update({
        'activePeriodId': currentActiveId,
        'data/periods': periodsMap,
        // Sincronizar data/matters para retrocompatibilidad
        'data/matters': allMattersData.map((m) => m.toMap()).toList(),
      });
    }
  } catch (e) {
    debugPrint('Error al escribir en la base de datos: $e');
  }
}

/// Guarda los datos aplicando un debounce de 500ms para evitar saturación de red
Future<void> saveData() async {
  _saveDebounceTimer?.cancel();
  _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
    _executeSave();
  });
}

/// Guarda los datos inmediatamente sin esperar el temporizador
Future<void> saveDataImmediate() async {
  _saveDebounceTimer?.cancel();
  await _executeSave();
}

/// Cambia el período activo y persiste la preferencia
void setActivePeriod(String periodId) {
  final found = allPeriodsData.firstWhere(
    (p) => p.id == periodId,
    orElse: () => allPeriodsData.first,
  );
  activePeriod = found;
  saveStringPreference('activePeriodId', found.id);
  saveData();
}

/// Agrega un nuevo período y lo establece como activo
void addPeriod(PeriodData newPeriod) {
  final existingIdx = allPeriodsData.indexWhere((p) => p.id == newPeriod.id);
  if (existingIdx == -1) {
    allPeriodsData.insert(0, newPeriod);
  } else {
    allPeriodsData[existingIdx] = newPeriod;
  }
  activePeriod = newPeriod;
  saveStringPreference('activePeriodId', newPeriod.id);
  saveData();
}

/// Actualiza un período existente
void updatePeriod(PeriodData updatedPeriod) {
  final idx = allPeriodsData.indexWhere((p) => p.id == updatedPeriod.id);
  if (idx != -1) {
    allPeriodsData[idx] = updatedPeriod;
    if (activePeriod?.id == updatedPeriod.id) {
      activePeriod = updatedPeriod;
    }
    saveData();
  }
}

/// Elimina un período y actualiza el período activo si correspondía al eliminado
void deletePeriod(String periodId) {
  allPeriodsData.removeWhere((p) => p.id == periodId);
  if (allPeriodsData.isEmpty) {
    final defaultPeriod = PeriodData(
      name: 'Primer Semestre ${DateTime.now().year}',
    );
    allPeriodsData.add(defaultPeriod);
  }
  if (activePeriod?.id == periodId || activePeriod == null) {
    activePeriod = allPeriodsData.first;
  }
  saveStringPreference('activePeriodId', activePeriod!.id);
  saveData();
}

Future<void> getData(String userId, [int periodID = 0]) async {
  if (_activeGetDataFuture != null && _activeGetDataUserId == userId) {
    return _activeGetDataFuture!;
  }

  _activeGetDataUserId = userId;
  _activeGetDataFuture = _fetchUserData(userId, periodID);

  try {
    await _activeGetDataFuture;
  } finally {
    _activeGetDataFuture = null;
    _activeGetDataUserId = null;
  }
}

Future<void> _fetchUserData(String userId, [int periodID = 0]) async {
  final userRef = FirebaseDatabase.instance.ref('users/$userId');

  try {
    await userRef.keepSynced(true);
  } catch (e) {
    debugPrint('Nota: keepSynced no soportado en esta plataforma o entorno de test: $e');
  }

  final userEvent = await userRef.once();
  final userSnapshot = userEvent.snapshot.value;

  String? savedActivePeriodId = getStringPreference('activePeriodId');
  final List<PeriodData> loadedPeriods = [];
  final Set<String> seenPeriodIds = <String>{};

  void addPeriodUnique(PeriodData period) {
    if (seenPeriodIds.add(period.id)) {
      loadedPeriods.add(period);
    }
  }

  if (userSnapshot != null && userSnapshot is Map) {
    final userMap = Map<String, dynamic>.from(userSnapshot);
    final activeFromDb = userMap['activePeriodId']?.toString();
    if (activeFromDb != null && activeFromDb.isNotEmpty) {
      savedActivePeriodId = activeFromDb;
    }

    final dataMap = userMap['data'] != null && userMap['data'] is Map
        ? Map<String, dynamic>.from(userMap['data'] as Map)
        : null;

    if (dataMap != null) {
      // 1. Intentar cargar periods
      final periodsRaw = dataMap['periods'];
      if (periodsRaw != null) {
        if (periodsRaw is Map) {
          for (var entry in periodsRaw.values) {
            if (entry != null) {
              final pMap = Map<String, dynamic>.from(entry as Map);
              addPeriodUnique(PeriodData.fromMap(pMap));
            }
          }
        } else if (periodsRaw is List) {
          for (var entry in periodsRaw) {
            if (entry != null) {
              final pMap = Map<String, dynamic>.from(entry as Map);
              addPeriodUnique(PeriodData.fromMap(pMap));
            }
          }
        }
      }

      // Ordenar períodos por fecha de creación descendente
      loadedPeriods.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 2. Si periods está vacío pero existen materias en data/matters (Migración Legacy)
      if (loadedPeriods.isEmpty && dataMap['matters'] != null) {
        List<MatterData> legacyMatters = [];
        final mattersRaw = dataMap['matters'];
        if (mattersRaw is List) {
          for (var m in mattersRaw) {
            if (m != null) {
              legacyMatters.add(
                  MatterData.fromMap(Map<String, dynamic>.from(m as Map)));
            }
          }
        } else if (mattersRaw is Map) {
          for (var m in mattersRaw.values) {
            if (m != null) {
              legacyMatters.add(
                  MatterData.fromMap(Map<String, dynamic>.from(m as Map)));
            }
          }
        }

        if (legacyMatters.isNotEmpty) {
          final migratedPeriod = PeriodData(
            name: 'Periodo Principal',
            matters: legacyMatters,
          );
          addPeriodUnique(migratedPeriod);
          allPeriodsData.clear();
          allPeriodsData.addAll(loadedPeriods);
          // Persistir estructura migrada
          saveDataImmediate();
        }
      }
    }
  }

  // Si no hay períodos (usuario nuevo o vacío), crear el período inicial por defecto
  if (loadedPeriods.isEmpty) {
    final defaultPeriod = PeriodData(
      name: 'Primer Semestre ${DateTime.now().year}',
    );
    addPeriodUnique(defaultPeriod);
    allPeriodsData.clear();
    allPeriodsData.addAll(loadedPeriods);
    saveDataImmediate();
  } else {
    allPeriodsData.clear();
    allPeriodsData.addAll(loadedPeriods);
  }
  _fallbackMatters.clear();

  // Configurar activePeriod
  if (savedActivePeriodId != null && savedActivePeriodId.isNotEmpty) {
    activePeriod = allPeriodsData.firstWhere(
      (p) => p.id == savedActivePeriodId,
      orElse: () => allPeriodsData.first,
    );
  } else {
    activePeriod = allPeriodsData.first;
  }

  saveStringPreference('activePeriodId', activePeriod!.id);
}
