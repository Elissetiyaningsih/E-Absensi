import 'package:absenku/pages/login/login.dart';
import 'package:absenku/services/auth_services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  
  // Simplified - hanya satu animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    
    // Simplified animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();

    // Focus listeners
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _buildSignInPrompt(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20), // Reduced from 60
                  _buildSimpleHeader(),
                  const SizedBox(height: 40), // Reduced from 60
                  _buildCleanForm(),
                  const SizedBox(height: 20), // Reduced from 40
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleHeader() {
    return Column(
      children: [
        // Icon dengan background circle sama seperti login
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_add_outlined,
            size: 60,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Buat Akun',
          style: GoogleFonts.raleway( // Changed to raleway like login
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Daftar untuk mulai menggunakan aplikasi',
          style: GoogleFonts.raleway( // Changed to raleway like login
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCleanForm() {
    return Column(
      children: [
        _buildCleanEmailField(),
        const SizedBox(height: 20),
        _buildCleanPasswordField(),
        const SizedBox(height: 30),
        _buildSimpleButton(),
      ],
    );
  }

  Widget _buildCleanEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Email',
            style: GoogleFonts.raleway(
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
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
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
              hintText: 'Masukkan email anda',
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

  Widget _buildCleanPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Kata Sandi',
            style: GoogleFonts.raleway(
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
            focusNode: _passwordFocusNode,
            obscureText: _obscureText,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              if (value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Masukkan password anda',
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

  Widget _buildSimpleButton() {
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
              await AuthService().signup(
                email: _emailController.text,
                password: _passwordController.text,
                context: context,
              );
            }
          },
          child: Center(
            child: Text(
              'Buat Akun',
              style: GoogleFonts.raleway(
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

  Widget _buildSignInPrompt() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: "Sudah punya akun? ",
              style: GoogleFonts.raleway(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: "Masuk disini",
              style: GoogleFonts.raleway(
                color: const Color(0xFF6366F1),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Login(),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}