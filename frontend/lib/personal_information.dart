import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api/planner_api.dart' show baseUrl;
import 'user_session.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _contactController;
  late final TextEditingController _passwordController;
  late final TextEditingController _emailController;

  bool _obscurePassword = true;

  bool _usernameEditable = false;
  bool _contactEditable  = false;
  bool _passwordEditable = false;

  // Snapshots so cancel can restore the old value
  String _savedUsername = '';
  String _savedContact  = '';
  String _savedPassword = '';

  String? _passwordError;
  bool _isUpdating = false;


  final ImagePicker _picker = ImagePicker();

  TextStyle _arimo(double size,
      {Color color = Colors.black, FontWeight weight = FontWeight.normal}) =>
      GoogleFonts.arimo(fontSize: size, color: color, fontWeight: weight);

  @override
  void initState() {
    super.initState();
    // ✅ All fields populated from UserSession (filled at login)
    _usernameController = TextEditingController(text: UserSession.username ?? '');
    _contactController  = TextEditingController(text: UserSession.contact  ?? '');
    _emailController    = TextEditingController(text: UserSession.email    ?? '');
    // ✅ Password captured at login and stored in UserSession
    _passwordController = TextEditingController(text: UserSession.password ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text('Take a photo', style: _arimo(16)),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? picked = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 85);
                if (picked != null && mounted) {
                  await UserSession.updateProfileImage(picked.path);
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('Choose from gallery', style: _arimo(16)),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? picked = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 85);
                if (picked != null && mounted) {
                  await UserSession.updateProfileImage(picked.path);
                  setState(() {});
                }
              },
            ),
            if (UserSession.profileImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Remove photo',
                    style: _arimo(16, color: Colors.red)),
                onTap: () async {
                  await UserSession.updateProfileImage(null);
                  Navigator.pop(ctx);
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Password validation ───────────────────────────────────────────────────
  String? _validatePassword(String pw) {
    if (pw.isEmpty) return 'Password cannot be empty';
    if (pw.length < 8) return 'At least 8 characters required';
    if (!pw.contains(RegExp(r'[A-Z]'))) return 'Must include an uppercase letter';
    if (!pw.contains(RegExp(r'[a-z]'))) return 'Must include a lowercase letter';
    if (!pw.contains(RegExp(r'[0-9]'))) return 'Must include a number';
    if (!pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]')))
      return 'Must include a symbol';
    return null;
  }

  // ── Save to backend + local session ──────────────────────────────────────
  Future<void> _updateProfile() async {
    if (_passwordEditable) {
      final err = _validatePassword(_passwordController.text);
      if (err != null) {
        setState(() => _passwordError = err);
        return;
      }
    }

    setState(() => _isUpdating = true);

    try {
      final Map<String, dynamic> body = {
        'uid':      UserSession.uid,
        'username': _usernameController.text.trim(),
        'contact':  _contactController.text.trim(),
      };
      // Only send password to backend if user is changing it
      if (_passwordEditable) {
        body['password'] = _passwordController.text;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/api/user/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserSession.idToken}',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // ✅ Update local UserSession to stay in sync
        await UserSession.updateUsername(_usernameController.text.trim());
        await UserSession.updateContact(_contactController.text.trim());
        if (_passwordEditable) {
          // ✅ Save new password so the field shows the updated value next time
          await UserSession.updatePassword(_passwordController.text);
        }

        setState(() {
          _usernameEditable = false;
          _contactEditable  = false;
          _passwordEditable = false;
          _obscurePassword  = true;
          _passwordError    = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile updated successfully!',
              style: _arimo(14, color: Colors.white)),
          backgroundColor: const Color(0xFF9C9EC3),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        _showError(
            decoded['error'] as String? ?? 'Update failed. Please try again.');
      }
    } on http.ClientException catch (_) {
      _showError('Could not reach the server. Check your connection.');
    } catch (_) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: _arimo(14, color: Colors.white)),
      backgroundColor: Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Generic field builder ─────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String suffixAsset,
    bool readOnly       = false,
    bool obscureText    = false,
    Widget? suffixWidget,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.arimo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D2D2D))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFD8C8E8) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: errorText != null
                ? Border.all(color: Colors.red.shade400, width: 1.5)
                : null,
          ),
          child: TextField(
            controller:   controller,
            readOnly:     readOnly,
            obscureText:  obscureText,
            keyboardType: keyboardType,
            onChanged:    onChanged,
            style: GoogleFonts.arimo(
                fontSize: 16, color: const Color(0xFF2D2D2D)),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              suffixIcon: suffixWidget ??
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/images/$suffixAsset',
                      width: 22, height: 22,
                      color: readOnly
                          ? Colors.grey[500]
                          : const Color(0xFF9C9EC3),
                    ),
                  ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(errorText,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileImagePath = UserSession.profileImagePath;
    final screenHeight     = MediaQuery.of(context).size.height;
    final safePadding      = MediaQuery.of(context).padding;
    final topSectionHeight = screenHeight * 0.42;
    final cardHeight       = screenHeight - topSectionHeight + safePadding.top;

    const cream    = Color(0xFFF5F0EB);
    const lavender = Color(0xFFE8D5F0);

    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Personal Information',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor:    Colors.purple,
        unselectedItemColor:  Colors.grey,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:   _arimo(12),
        unselectedLabelStyle: _arimo(12),
        onTap: (i) {
          switch (i) {
            case 0: Navigator.pushReplacementNamed(context, '/home');    break;
            case 1: Navigator.pushReplacementNamed(context, '/planner'); break;
            case 2: Navigator.pushReplacementNamed(context, '/group');   break;
            case 3: Navigator.pop(context);                              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Planner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined), label: 'Group'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),

      body: Stack(
        children: [
          // ── Lavender card ─────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(color: lavender.withOpacity(0.80)),
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Username ──────────────────────────────────────────
                    _buildField(
                      label: 'Username', controller: _usernameController,
                      suffixAsset: 'edit.png', readOnly: !_usernameEditable,
                      suffixWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_usernameEditable)
                            GestureDetector(
                              onTap: () => setState(() {
                                _usernameController.text = _savedUsername;
                                _usernameEditable = false;
                              }),
                              child: const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.close,
                                    color: Colors.redAccent, size: 20),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => setState(() {
                              if (!_usernameEditable) {
                                _savedUsername = _usernameController.text;
                              }
                              _usernameEditable = !_usernameEditable;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset('assets/images/edit.png',
                                  width: 22, height: 22,
                                  color: _usernameEditable
                                      ? const Color(0xFF9C9EC3)
                                      : Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Email (always read-only) ──────────────────────────
                    _buildField(
                      label: 'Email', controller: _emailController,
                      suffixAsset: 'email.png', readOnly: true,
                    ),

                    // ── Contact No ────────────────────────────────────────
                    _buildField(
                      label: 'Contact No', controller: _contactController,
                      suffixAsset: 'edit.png',
                      keyboardType: TextInputType.phone,
                      readOnly: !_contactEditable,
                      suffixWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_contactEditable)
                            GestureDetector(
                              onTap: () => setState(() {
                                _contactController.text = _savedContact;
                                _contactEditable = false;
                              }),
                              child: const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.close,
                                    color: Colors.redAccent, size: 20),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => setState(() {
                              if (!_contactEditable) {
                                _savedContact = _contactController.text;
                              }
                              _contactEditable = !_contactEditable;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset('assets/images/edit.png',
                                  width: 22, height: 22,
                                  color: _contactEditable
                                      ? const Color(0xFF9C9EC3)
                                      : Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Password ──────────────────────────────────────────
                    _buildField(
                      label: 'Password', controller: _passwordController,
                      suffixAsset: 'change.png',
                      readOnly:    !_passwordEditable,
                      obscureText: _obscurePassword,
                      errorText:   _passwordError,
                      onChanged: _passwordEditable
                          ? (v) => setState(
                              () => _passwordError = _validatePassword(v))
                          : null,
                      suffixWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Cancel: restore old password and exit edit mode
                          if (_passwordEditable)
                            GestureDetector(
                              onTap: () => setState(() {
                                _passwordController.text = _savedPassword;
                                _passwordEditable = false;
                                _obscurePassword  = true;
                                _passwordError    = null;
                              }),
                              child: const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.close,
                                    color: Colors.redAccent, size: 20),
                              ),
                            ),
                          // Eye toggle — always visible so user can peek
                          // at current password before changing it
                          GestureDetector(
                            onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF9C9EC3),
                                size: 22,
                              ),
                            ),
                          ),
                          // Change button
                          GestureDetector(
                            onTap: () => setState(() {
                              if (!_passwordEditable) {
                                _savedPassword    = _passwordController.text;
                                _passwordEditable = true;
                              }
                            }),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset('assets/images/change.png',
                                  width: 22, height: 22,
                                  color: _passwordEditable
                                      ? const Color(0xFF9C9EC3)
                                      : Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Update Profile button ─────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C9EC3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : Text('Update Profile',
                            style: GoogleFonts.arimo(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ── Avatar ───────────────────────────────────────────────────────
          Positioned(
            top: topSectionHeight - 300,
            left: 0, right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImagePath != null
                          ? FileImage(File(profileImagePath)) : null,
                      child: profileImagePath == null
                          ? const Icon(Icons.person,
                          size: 56, color: Colors.grey)
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset('assets/images/camera_icon.png',
                          fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}