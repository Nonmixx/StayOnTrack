import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api/planner_api.dart' show baseUrl;
import 'singup.dart';
import 'forgot_password.dart';
import 'user_session.dart';
import 'routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading       = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _emailController.text.trim().isNotEmpty &&
          _passwordController.text.isNotEmpty;

  Future<void> _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError    = email.isEmpty    ? 'Email cannot be empty'    : null;
      _passwordError = password.isEmpty ? 'Password cannot be empty' : null;
      _generalError  = null;
    });

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        await UserSession.save(
          uid:      body['uid']      as String,
          email:    body['email']    as String,
          username: body['username'] as String? ?? '',
          contact:  body['contact']  as String? ?? '',
          password: password,
          idToken:  body['idToken']  as String,
        );

        final prefs = await SharedPreferences.getInstance();
        UserSession.profileImagePath =
            prefs.getString('session_profile_image_path_${body['uid']}');

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        final body     = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg = body['error'] as String? ??
            'Incorrect email or password. Please try again.';
        setState(() => _generalError = errorMsg);
      }
    } on http.ClientException catch (_) {
      setState(() =>
      _generalError = 'Could not reach the server. Check your connection.');
    } catch (e) {
      setState(() =>
      _generalError = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ───── Top beige section ─────
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F0EB),
              padding: EdgeInsets.only(
                  top: screenHeight * 0.06, // 自适应
                  left: 24,
                  right: 24,
                  bottom: screenHeight * 0.12 // 自适应
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset('assets/images/latest_logo.png',
                    height: screenHeight * 0.12, // 自适应
                    width: screenHeight * 0.12,
                    fit: BoxFit.contain),
              ),
            ),

            // ───── Overlap zone ─────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // ───── Lavender card ─────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8D5F0),
                    borderRadius: BorderRadius.only(
                      topLeft:  Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    28,
                    screenHeight * 0.2, // 顶部自适应
                    28,
                    screenHeight * 0.05, // 底部自适应
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Welcome Back',
                          style: GoogleFonts.allan(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D2D2D))),
                      const SizedBox(height: 28),

                      // ── Email field ──
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _emailError != null
                                    ? Colors.red.shade400
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.arimo(fontSize: 20),
                              enabled: !_isLoading,
                              onChanged: (_) => setState(() {
                                _emailError = _emailController.text.trim().isEmpty
                                    ? 'Email cannot be empty' : null;
                                _generalError = null;
                              }),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: GoogleFonts.arimo(
                                    fontSize: 20, color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.email_outlined,
                                    color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                            ),
                          ),
                          if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 16),
                              child: Text(_emailError!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Password field ──
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _passwordError != null
                                    ? Colors.red.shade400
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.arimo(fontSize: 20),
                              enabled: !_isLoading,
                              onChanged: (_) => setState(() {
                                _passwordError = _passwordController.text.isEmpty
                                    ? 'Password cannot be empty' : null;
                                _generalError = null;
                              }),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: GoogleFonts.arimo(
                                    fontSize: 20, color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.key_outlined,
                                    color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                            ),
                          ),
                          if (_passwordError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 16),
                              child: Text(_passwordError!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ),
                        ],
                      ),

                      // ── General / server error ──
                      if (_generalError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade600, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_generalError!,
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const ResetPasswordPage())),
                          child: Text('Forgot Password?',
                              style: GoogleFonts.arimo(
                                  fontSize: 16,
                                  color: const Color(0xFF2D2D2D))),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Login button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormValid && !_isLoading
                                ? const Color(0xFF9C9EC3)
                                : const Color(0xFF9C9EC3).withOpacity(0.45),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: _isFormValid && !_isLoading ? 2 : 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                              : Text('Login',
                              style: GoogleFonts.arimo(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 25),

                      const Divider(color: Colors.grey, thickness: 0.5),
                      const SizedBox(height: 5),

                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpPage())),
                        child: Text("Don't have an account? Click here",
                            style: GoogleFonts.arimo(
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                                color: const Color(0xFF2D2D2D))),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // ───── Floating image ─────
                Positioned(
                  top: screenHeight * -0.15,
                  child: Image.asset('assets/images/login_image.png',
                      height: screenHeight * 0.3,
                      width: screenHeight * 0.3,
                      fit: BoxFit.contain),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}