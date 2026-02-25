import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api/planner_api.dart' show baseUrl;
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController        = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;
  bool _isLoading    = false;

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;
  String? _serverError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _usernameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _validateEmail(_emailController.text.trim()) == null &&
        _validatePassword(_passwordController.text) == null &&
        _passwordController.text == _confirmPasswordController.text &&
        _agreeToTerms;
  }

  String? _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (email.isEmpty) return 'Email cannot be empty';
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Password cannot be empty';
    if (password.length < 8) return 'At least 8 characters required';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Must include an uppercase letter';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Must include a lowercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Must include a number';
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]')))
      return 'Must include a symbol';
    return null;
  }

  Future<void> _validate() async {
    setState(() {
      _serverError = null;
      _usernameError = _usernameController.text.trim().isEmpty
          ? 'Username cannot be empty' : null;
      _emailError = _validateEmail(_emailController.text.trim());
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _confirmPasswordController.text.isEmpty
          ? 'Please confirm your password'
          : _confirmPasswordController.text != _passwordController.text
          ? 'Passwords do not match' : null;
      _termsError = !_agreeToTerms
          ? 'You must agree to the Terms and Privacy Policy' : null;
    });

    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email':    _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      } else {
        final body     = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg = body['error'] as String? ??
            'Registration failed. Please try again.';
        setState(() {
          if (response.statusCode == 409 ||
              errorMsg.toLowerCase().contains('email')) {
            _emailError = errorMsg;
          } else {
            _serverError = errorMsg;
          }
        });
      }
    } on http.ClientException catch (_) {
      setState(() => _serverError =
      'Could not reach the server. Check your connection.');
    } catch (e) {
      setState(() =>
      _serverError = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFF5F0EB),
                padding: EdgeInsets.only(
                    top: screenHeight * 0.015,
                    left: 16,
                    right: 16,
                    bottom: screenHeight * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/images/latest_logo.png',
                        height: screenHeight * 0.12,
                        width: screenHeight * 0.12),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE6CFE6).withOpacity(0.80),
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30))),
                    padding: EdgeInsets.fromLTRB(
                        24, screenHeight * 0.18, 24, screenHeight * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Account',
                            style: GoogleFonts.allan(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D2D4E),
                                letterSpacing: -0.5)),
                        SizedBox(height: screenHeight * 0.025),

                        _buildInputField(
                          controller: _usernameController,
                          hintText: 'Username',
                          iconAsset: 'assets/images/username.png',
                          errorText: _usernameError,
                          onChanged: (_) => setState(() {
                            _usernameError =
                            _usernameController.text.trim().isEmpty
                                ? 'Username cannot be empty' : null;
                          }),
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        _buildInputField(
                          controller: _emailController,
                          hintText: 'Email',
                          iconAsset: 'assets/images/email.png',
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          onChanged: (_) => setState(() {
                            _emailError =
                                _validateEmail(_emailController.text.trim());
                          }),
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        _buildInputField(
                          controller: _passwordController,
                          hintText: 'Password',
                          iconAsset: 'assets/images/password.png',
                          obscureText: true,
                          errorText: _passwordError,
                          onChanged: (_) => setState(() {
                            _passwordError =
                                _validatePassword(_passwordController.text);
                            if (_confirmPasswordController.text.isNotEmpty) {
                              _confirmPasswordError =
                              _confirmPasswordController.text !=
                                  _passwordController.text
                                  ? 'Passwords do not match'
                                  : null;
                            }
                          }),
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        _buildInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          iconAsset: 'assets/images/confirm_password.png',
                          obscureText: true,
                          errorText: _confirmPasswordError,
                          onChanged: (_) => setState(() {
                            _confirmPasswordError =
                            _confirmPasswordController.text.isEmpty
                                ? 'Please confirm your password'
                                : _confirmPasswordController.text !=
                                _passwordController.text
                                ? 'Passwords do not match'
                                : null;
                          }),
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        // Terms checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: _isLoading
                                    ? null
                                    : (v) => setState(() {
                                  _agreeToTerms = v ?? false;
                                  _termsError = !_agreeToTerms
                                      ? 'You must agree to the Terms and Privacy Policy'
                                      : null;
                                }),
                                activeColor: const Color(0xFF9C9EC3),
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                  children: [
                                    TextSpan(
                                        text:
                                        "By signing up, I hereby agree to StayOnTracK AI's "),
                                    TextSpan(
                                        text: 'Terms and condition',
                                        style: TextStyle(
                                            decoration:
                                            TextDecoration.underline,
                                            color: Colors.blue)),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                            decoration:
                                            TextDecoration.underline,
                                            color: Colors.blue)),
                                    TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_termsError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(_termsError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 11)),
                          ),
                        if (_serverError != null) ...[
                          SizedBox(height: screenHeight * 0.015),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border:
                              Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade600, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_serverError!,
                                      style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: screenHeight * 0.045),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _validate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFormValid && !_isLoading
                                  ? const Color(0xFF9C9EC3)
                                  : const Color(0xFF9C9EC3).withOpacity(0.45),
                              foregroundColor: Colors.white,
                              elevation:
                              _isFormValid && !_isLoading ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5),
                            )
                                : const Text('Sign Up',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenHeight * -0.15,
                    child: Image.asset('assets/images/signup_image.png',
                        height: screenHeight * 0.3,
                        width: screenHeight * 0.3,
                        fit: BoxFit.contain),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required String iconAsset,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: errorText != null ? Colors.red.shade400 : Colors.grey.shade300,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Image.asset(iconAsset, height: 22, width: 22, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),
      ],
    );
  }
}