import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/guest_session.dart';
import '../widgets/social_login_section.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _email = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfAlreadySignedIn());
  }

  Future<void> _redirectIfAlreadySignedIn() async {
    if (!mounted) return;
    if (GuestSession.instance.isGuest ||
        FirebaseAuth.instance.currentUser != null) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B4B4B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(
                          label: 'Email',
                          hintText: 'Enter email',
                          obscureText: false,
                          onSaved: (value) => _email = value?.trim() ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Email required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Password',
                          hintText: 'Enter password',
                          obscureText: !_isPasswordVisible,
                          isPassword: true,
                          onSaved: (value) => _password = value ?? '',
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Password required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Register'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/forgot_password'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SocialLoginSection(
                    label: 'Login With',
                    onGuest: _onGuestLogin,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                    ),
                    child: Center(
                      child: _isLoading 
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hintText,
    required bool obscureText,
    bool isPassword = false,
    required FormFieldSetter<String?> onSaved,
    required FormFieldValidator<String?> validator,
  }) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFC107), width: 1.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            style: const TextStyle(color: Colors.white),
            obscureText: obscureText,
            onSaved: onSaved,
            validator: validator,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFF3C3C3C),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onGuestLogin() async {
    await GuestSession.instance.enterGuestMode();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _onLogin() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        await GuestSession.instance.exitGuestMode();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } on FirebaseAuthException catch (e) {
        String msg = 'Terjadi kesalahan.';
        if (e.code == 'user-not-found') {
          msg = 'Email tidak tersimpan dalam sistem.';
        } else if (e.code == 'wrong-password') {
          msg = 'Password salah.';
        } else if (e.code == 'invalid-email') {
          msg = 'Format email tidak valid.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login gagal. Coba lagi nanti.')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
