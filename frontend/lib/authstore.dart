/// In-memory auth + profile store shared across all pages.
/// In a real app, replace with a backend / local database.
class AuthStore {
  AuthStore._();

  // ── User registry: email → UserProfile ─────────────────────────────────
  static final Map<String, UserProfile> _users = {};

  // ── Currently logged-in email ───────────────────────────────────────────
  static String? _currentEmail;

  // ── Registration ────────────────────────────────────────────────────────
  static void register(String email, String password, String username) {
    final key = email.trim().toLowerCase();
    _users[key] = UserProfile(
      email: email.trim(),
      password: password,
      username: username,
    );
  }

  // ── Login — returns true and sets current user on success ────────────────
  static bool login(String email, String password) {
    final key = email.trim().toLowerCase();
    final profile = _users[key];
    if (profile != null && profile.password == password) {
      _currentEmail = key;
      return true;
    }
    return false;
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  static void logout() => _currentEmail = null;

  // ── Current user helpers ─────────────────────────────────────────────────
  static UserProfile? get currentUser =>
      _currentEmail != null ? _users[_currentEmail!] : null;

  // ── Profile update helpers (mutate in place) ─────────────────────────────
  static void updateUsername(String username) {
    currentUser?.username = username;
  }

  static void updateContact(String contact) {
    currentUser?.contact = contact;
  }

  /// Updates password both in the profile and the credential store.
  static void updatePassword(String newPassword) {
    if (currentUser != null) {
      currentUser!.password = newPassword;
    }
  }

  static void updateProfileImage(String? imagePath) {
    currentUser?.profileImagePath = imagePath;
  }

  // ── Email-exists check (for signup) ─────────────────────────────────────
  static bool emailExists(String email) =>
      _users.containsKey(email.trim().toLowerCase());
}

/// Mutable profile model for one registered user.
class UserProfile {
  final String email; // immutable — used as the account key
  String password;
  String username;
  String contact;
  String? profileImagePath;

  UserProfile({
    required this.email,
    required this.password,
    required this.username,
    this.contact = '',
    this.profileImagePath,
  });
}