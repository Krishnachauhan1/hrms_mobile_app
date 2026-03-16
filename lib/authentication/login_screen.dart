import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      init: AuthController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildTitle(),
                  const SizedBox(height: 40),
                  _buildForm(controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //  Logo widget
  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF5F4FD1)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.35),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.business_center_rounded,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }

  //  Title
  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back! 👋',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Sign in to your HRMS account',
          style: TextStyle(fontSize: 16, color: Color(0xFF74788D)),
        ),
      ],
    );
  }

  Widget _buildForm(AuthController controller) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Email Address'),
          const SizedBox(height: 10),
          _textField(
            controller: controller.loginEmailController,
            hint: 'Enter your email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          _label('Password'),
          const SizedBox(height: 10),
          _passwordField(
            controller: controller.loginPasswordController,
            hint: 'Enter your password',
            isVisible: controller.isLoginPasswordVisible,
            onToggle: controller.toggleLoginPassword,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isLoginLoading ? null : controller.login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                disabledBackgroundColor: const Color(
                  0xFF6C5CE7,
                ).withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: controller.isLoginLoading
                  ? const SizedBox(
                      // loading spinner
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  //  Reusable small widgets
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF2D3436),
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB2B7C2), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB2B7C2), fontSize: 14),
          prefixIcon: const Icon(
            Icons.lock_rounded,
            color: Color(0xFF6C5CE7),
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: const Color(0xFF74788D),
              size: 22,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
