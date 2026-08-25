import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:firebase_database/firebase_database.dart';

// Base de los datos del programa
List<MatterData> allMattersData = [];

Timer? _saveDebounceTimer;

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
  final userId = getStringPreference('userid');

  if (userId != null && userId.isNotEmpty) {
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('users/$userId/data/matters');
    final mattersPayload = allMattersData.map((m) => m.toMap()).toList();
    try {
      await dbRef.set(mattersPayload);
    } catch (e) {
      debugPrint('Error al escribir en la base de datos: $e');
    }
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

Future<void> getData(String userId, int periodID) async {
  final databaseRef =
      FirebaseDatabase.instance.ref('users/$userId/data/matters');

  // Borro la lista de materias anterior en caso de un error de base
  // para evitar que se queden los datos de otros usuarios
  allMattersData.clear();

  final databaseEvent = await databaseRef.once();

  final snapshotValue = databaseEvent.snapshot.value;

  if (snapshotValue != null) {
    if (snapshotValue is List) {
      for (var matterData in snapshotValue) {
        if (matterData != null) {
          final matterMap = Map<String, dynamic>.from(matterData as Map);
          MatterData matter = MatterData.fromMap(matterMap);
          allMattersData.add(matter);
        }
      }
    } else if (snapshotValue is Map) {
      for (var entry in snapshotValue.values) {
        if (entry != null) {
          final matterMap = Map<String, dynamic>.from(entry as Map);
          MatterData matter = MatterData.fromMap(matterMap);
          allMattersData.add(matter);
        }
      }
    }
  }
}
