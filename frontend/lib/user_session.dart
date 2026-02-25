import 'package:shared_preferences/shared_preferences.dart';

/// In-memory + SharedPreferences session store.
/// All data is loaded from the backend on login and persisted locally
/// so the app survives restarts without another network call.
class UserSession {
  // ── In-memory fields ──────────────────────────────────────────────────────
  static String? uid;
  static String? email;
  static String? username;
  static String? contact;
  static String? password;
  static String? idToken;
  static String? profileImagePath;

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const _kUid              = 'session_uid';
  static const _kEmail            = 'session_email';
  static const _kUsername         = 'session_username';
  static const _kContact          = 'session_contact';
  static const _kPassword         = 'session_password';
  static const _kIdToken          = 'session_id_token';
  static const _kProfileImagePath = 'session_profile_image_path';

  // ── Save on login ──────────────────────────────────────────────────────────
  static Future<void> save({
    required String uid,
    required String email,
    required String username,
    required String contact,
    required String password,
    required String idToken,
  }) async {
    UserSession.uid      = uid;
    UserSession.email    = email;
    UserSession.username = username;
    UserSession.contact  = contact;
    UserSession.password = password;
    UserSession.idToken  = idToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUid,      uid);
    await prefs.setString(_kEmail,    email);
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kContact,  contact);
    await prefs.setString(_kPassword, password);
    await prefs.setString(_kIdToken,  idToken);
  }

  // ── Restore on app restart ─────────────────────────────────────────────────
  static Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    uid              = prefs.getString(_kUid);
    email            = prefs.getString(_kEmail);
    username         = prefs.getString(_kUsername);
    contact          = prefs.getString(_kContact);
    password         = prefs.getString(_kPassword);
    idToken          = prefs.getString(_kIdToken);
    if (uid != null) {
      profileImagePath =
          prefs.getString('session_profile_image_path_$uid');
    }
    return uid != null;
  }

  // ── Field updaters ─────────────────────────────────────────────────────────
  static Future<void> updateUsername(String value) async {
    username = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsername, value);
  }

  static Future<void> updateContact(String value) async {
    contact = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kContact, value);
  }

  static Future<void> updatePassword(String value) async {
    password = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPassword, value);
  }

  static Future<void> updateProfileImage(String? path) async {
    profileImagePath = path;

    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'session_profile_image_path_$uid';

    if (path == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, path);
    }
  }


  // ── Clear on logout ────────────────────────────────────────────────────────
  static Future<void> clear() async {
    final savedProfileImage = profileImagePath;
    uid              = null;
    email            = null;
    username         = null;
    contact          = null;
    password         = null;
    idToken          = null;
    profileImagePath = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUid);
    await prefs.remove(_kEmail);
    await prefs.remove(_kUsername);
    await prefs.remove(_kContact);
    await prefs.remove(_kPassword);
    await prefs.remove(_kIdToken);
  }
}