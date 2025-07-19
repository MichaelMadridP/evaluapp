import 'package:evaluapp/data_model/model.dart';
import 'package:evaluapp/data_model/preferences.dart';
import 'package:firebase_database/firebase_database.dart';

// Base de los datos del programa
List<MatterData> allMattersData = [];

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

Future<void> saveData() async {
  final Map<String, dynamic> allMapData = <String, dynamic>{};
  final userId = getStringPreference('userid');

  if (userId != null) {
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('users/$userId/data/');
    allMapData['matters'] = allMattersData.map((m) => m.toMap()).toList();
    try {
      await dbRef.set(allMapData);
    } catch (e) {
      throw Exception('Error al escribir en la base de datos: $e');
    }
  }
}

Future<void> getData(String userId, int periodID) async {
  final databaseRef =
      FirebaseDatabase.instance.ref('users/$userId/data/matters');

  // Borro la lista de materias anterior en caso de un error de base
  // para evitar que se queden los datos de otros usuarios
  allMattersData.clear();

  final databaseEvent = await databaseRef.once();

  if (databaseEvent.snapshot.value != null) {
    final List<dynamic> allMapData =
        databaseEvent.snapshot.value as List<dynamic>;

    if (allMapData.isNotEmpty) {
      for (var matterData in allMapData) {
        if (matterData != null) {
          final matterMap = Map<String, dynamic>.from(matterData as Map);
          MatterData matter = MatterData.fromMap(matterMap);
          allMattersData.add(matter);
        }
      }
    }
  }
}
