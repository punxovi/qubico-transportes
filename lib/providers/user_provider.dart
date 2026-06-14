import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/security_service.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  List<User> get users => _users;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> fetchUsers() async {
    final data = await DatabaseService.instance.queryAll('users');
    _users = data.map((map) => User.fromMap(map)).toList();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final db = await DatabaseService.instance.database;
    final encryptedPassword = SecurityService.generateHash(password);
    
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ? AND is_active = 1',
      whereArgs: [email, encryptedPassword],
    );

    if (result.isNotEmpty) {
      _currentUser = User.fromMap(result.first);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> addUser(User user) async {
    await DatabaseService.instance.insert('users', user.toMap());
    await fetchUsers();
  }

  Future<void> toggleUserStatus(String id, bool currentStatus) async {
    await DatabaseService.instance.update('users', {'is_active': currentStatus ? 0 : 1}, 'id', id);
    await fetchUsers();
  }

  Future<void> deleteUser(String id) async {
    await DatabaseService.instance.delete('users', 'id', id);
    await fetchUsers();
  }
}

