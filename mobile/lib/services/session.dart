import 'package:material_ui/material_ui.dart';

import '../models/user.dart';
import 'auth_storage.dart';

/// The logged-in user (with their settings), shared by every screen.
final currentUser = ValueNotifier<User?>(null);

/// 'bs' or 'ad': how dates are shown.
String get calendar => currentUser.value?.calendar ?? 'bs';

/// Shows [user] everywhere and keeps the saved copy up to date.
Future<void> setCurrentUser(User user) async {
  currentUser.value = user;
  await AuthStorage.saveUser(user);
}
