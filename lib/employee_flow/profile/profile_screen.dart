import 'dart:io';
import 'package:employee_app/employee_flow/dashboard/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileBottomSheet extends StatelessWidget {
  final DashboardController controller;

  const ProfileBottomSheet({super.key, required this.controller});

  static void show(BuildContext context, DashboardController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProfileBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F9FF), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handleBar(),
          const SizedBox(height: 20),

          _avatar(),
          const SizedBox(height: 12),

          _name(),
          const SizedBox(height: 4),

          const Text(
            'Employee Account',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8A8FA3),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          _uploadSection(),

          const SizedBox(height: 22),
          Divider(color: Colors.grey.shade200, thickness: 1),
          const SizedBox(height: 16),

          _logoutButton(context),
          const SizedBox(height: 10),
          _cancelButton(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ───────── HANDLE ─────────
  Widget _handleBar() {
    return Container(
      width: 45,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }

  // ───────── AVATAR ─────────
  Widget _avatar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 38,
        backgroundColor: Colors.white,
        child: Text(
          controller.employeeInitials.isEmpty
              ? '--'
              : controller.employeeInitials,
          style: const TextStyle(
            color: Color(0xFF6C5CE7),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ───────── UPLOAD + PROGRESS ─────────
  Widget _uploadSection() {
    return GetBuilder<DashboardController>(
      builder: (ctrl) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                icon: ctrl.isUploadingProfileImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6C5CE7),
                        ),
                      )
                    : const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(
                  ctrl.isUploadingProfileImage
                      ? 'Processing...'
                      : 'Upload Profile Image',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: ctrl.isUploadingProfileImage
                    ? null
                    : () async {
                        final File? file = await ctrl.pickImageFromCamera();
                        if (file != null) {
                          await ctrl.uploadProfileImage(file);
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C5CE7),
                  side: const BorderSide(color: Color(0xFF6C5CE7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (ctrl.isUploadingProfileImage) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ctrl.uploadProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8E4FF),
                  color: const Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ctrl.uploadStatusMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF636E72),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(ctrl.uploadProgress.clamp(0.0, 1.0) * 100).round()}%',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
              ),
            ],
          ],
        );
      },
    );
  }

  // ───────── NAME ─────────
  Widget _name() {
    return Text(
      controller.employeeName.isEmpty ? 'Employee' : controller.employeeName,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2D3436),
      ),
    );
  }

  // ───────── LOGOUT ─────────
  Widget _logoutButton(BuildContext context) {
    return GetBuilder<DashboardController>(
      builder: (ctrl) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: ctrl.isLoggingOut
                ? null
                : () {
                    Navigator.pop(context);
                    ctrl.logout();
                  },
            icon: ctrl.isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(
              ctrl.isLoggingOut ? 'Logging out...' : 'Logout',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        );
      },
    );
  }

  // ───────── CANCEL ─────────
  Widget _cancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF636E72),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
