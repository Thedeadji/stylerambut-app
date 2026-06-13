import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/guest_session.dart';
import '../widgets/social_login_section.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B4B4B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.undo, color: Color(0xFFFFC107), size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(
                        label: 'Email',
                        hintText: '',
                        obscureText: false,
                        onSaved: (value) => _email = value?.trim() ?? '',
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Email required'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        label: 'Username',
                        hintText: '',
                        obscureText: false,
                        onSaved: (value) {},
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Username required'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        label: 'Password',
                        hintText: '',
                        obscureText: !_isPasswordVisible,
                        isPassword: true,
                        isConfirm: false,
                        onSaved: (value) => _password = value ?? '',
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Password required'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        label: 'Confirm Password',
                        hintText: '',
                        obscureText: !_isConfirmPasswordVisible,
                        isPassword: true,
                        isConfirm: true,
                        onSaved: (value) => _confirmPassword = value ?? '',
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Confirm Password required'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SocialLoginSection(
                  label: 'Daftar dengan',
                  onGuest: _onGuestRegister,
                ),
                const SizedBox(height: 40),
                // Register Button
                ElevatedButton(
                  onPressed: _onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
                const SizedBox(height: 20),
              ],
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
    bool isConfirm = false,
    required FormFieldSetter<String?> onSaved,
    required FormFieldValidator<String?> validator,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10), // Space for the overlapping label
          decoration: BoxDecoration(
            color: const Color(0xFF333333), // Darker inner background like screenshot
            border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            style: const TextStyle(color: Colors.white),
            obscureText: obscureText,
            onSaved: onSaved,
            validator: validator,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 24), // Taller fields
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              // Optionally add a visibility toggle. The design doesn't show it but good to have
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isConfirm) {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          } else {
                            _isPasswordVisible = !_isPasswordVisible;
                          }
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        // Floating Label (centered at the top border)
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onGuestRegister() async {
    await GuestSession.instance.enterGuestMode();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _onRegister() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      
      if (_password != _confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password dan Confirm Password harus sama')));
        return;
      }

      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        await GuestSession.instance.exitGuestMode();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } on FirebaseAuthException catch (e) {
        String msg = 'Terjadi kesalahan.';
        if (e.code == 'weak-password') {
          msg = 'Password terlalu lemah.';
        } else if (e.code == 'email-already-in-use') {
          msg = 'Email ini sudah terdaftar.';
        } else if (e.code == 'invalid-email') {
          msg = 'Format email tidak valid.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendaftar. Coba lagi nanti.')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
