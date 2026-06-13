import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _email = '';

  Future<void> _onSendResetLink() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    form.save();
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Link reset password telah dikirim. Periksa inbox email kamu.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String msg = 'Terjadi kesalahan.';
      if (e.code == 'invalid-email') {
        msg = 'Format email tidak valid.';
      } else if (e.code == 'user-not-found') {
        msg = 'Email tidak terdaftar.';
      } else if (e.code == 'too-many-requests') {
        msg = 'Terlalu banyak percobaan. Coba lagi nanti.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim link reset. Coba lagi nanti.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFFFFC107),
                          size: 18,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Forgot Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan email akun kamu. Firebase akan mengirim link '
                    'reset password ke email tersebut.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: _buildField(
                      label: 'Email',
                      hintText: 'Enter email',
                      onSaved: (value) => _email = value?.trim() ?? '',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email required';
                        }
                        final email = value.trim();
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onSendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      disabledBackgroundColor: const Color(0xFFFFC107).withValues(
                        alpha: 0.6,
                      ),
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
                              child: CircularProgressIndicator(
                                color: Colors.black87,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Kirim Link Reset',
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
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onSaved: onSaved,
            validator: validator,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
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
}
