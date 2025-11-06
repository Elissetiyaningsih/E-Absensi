import 'package:absenku/pages/forgot_pass/forgot_password.dart';
import 'package:absenku/pages/signup/signup.dart';
import 'package:absenku/services/auth_services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _signup(context),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Reduced vertical padding from 40
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20), // Reduced from 60
                
                // Icon dengan background circle
                Container(
                  width: 100, // Reduced from 120
                  height: 100, // Reduced from 120
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 50, // Reduced from 60
                    color: const Color(0xFF6366F1),
                  ),
                ),
                
                const SizedBox(height: 24), // Reduced from 40
                
                Text(
                  'Masuk Akun',
                  style: GoogleFonts.poppins( // Changed from raleway to poppins
                    fontSize: 28, // Reduced from 32
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk melanjutkan menggunakan aplikasi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins( // Changed from raleway to poppins
                    fontSize: 14, // Reduced from 16
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 40), // Reduced from 60

                // Form Fields
                _emailAddress(),
                const SizedBox(height: 16), // Reduced from 20
                _password(),
                
                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPassword(),
                        ),
                      );
                    },
                    child: Text(
                      'Lupa Kata Sandi?',
                      style: GoogleFonts.poppins( // Changed from raleway to poppins
                        fontSize: 14,
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24), // Reduced from 30
                _signin(context),
                const SizedBox(height: 20), // Reduced from 40
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Email',
            style: GoogleFonts.poppins( // Changed from raleway to poppins
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!isValidEmail(value)) {
                return 'Format email tidak valid';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Masukkan email Anda',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Colors.grey[500],
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _password() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Kata Sandi',
            style: GoogleFonts.poppins( // Changed from raleway to poppins
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kata sandi tidak boleh kosong';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Masukkan kata sandi Anda',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey[500],
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey[500],
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _signin(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [const Color(0xFF6366F1), Color(0xFF4285F4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (_formKey.currentState!.validate()) {
              await AuthService().signin(
                email: _emailController.text,
                password: _passwordController.text,
                context: context,
              );
            }
          },
          child: Center(
            child: Text(
              'Masuk Akun',
              style: GoogleFonts.poppins( // Changed from raleway to poppins
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: "Belum punya akun? ",
              style: GoogleFonts.poppins( // Changed from raleway to poppins
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: "Daftar disini",
              style: GoogleFonts.poppins( // Changed from raleway to poppins
                color: const Color(0xFF6366F1),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Signup()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}