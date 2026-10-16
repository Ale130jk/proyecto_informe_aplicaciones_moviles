import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> validateAdminCredentials(String username, String password) async {
    try {
      final docSnapshot = await _firestore.collection('config').doc('admin_access').get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final storedUsername = data?['username'] as String?;
        final storedPassword = data?['password'] as String?;
        return storedUsername == username && storedPassword == password;
      }
      return false;
    } catch (e) {
      throw Exception('Error al conectar con la base de datos: $e');
    }
  }
}