import 'package:employee_app/employee_flow/dashboard/dashboard_controller.dart';
import 'package:employee_app/employee_flow/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileBottomSheet extends StatelessWidget {
  final DashboardController dashboardController;

  const ProfileBottomSheet({
    super.key,
    required this.dashboardController,
  });

  static void show(
    BuildContext context,
    DashboardController dashboardController,
  ) {
    Get.put(ProfileController());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProfileBottomSheet(
        dashboardController: dashboardController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GetBuilder<ProfileController>(
      builder: (profileCtrl) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8F9FF), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _handleBar(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFF636E72),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: profileCtrl.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF6C5CE7),
                              ),
                            )
                          : profileCtrl.errorMessage != null &&
                                profileCtrl.profile == null
                          ? _errorState(profileCtrl)
                          : ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              children: [
                                _profileHeader(profileCtrl),
                                const SizedBox(height: 20),
                                _infoCard(context, profileCtrl),
                                const SizedBox(height: 20),
                                _uploadButton(context, profileCtrl),
                                const SizedBox(height: 16),
                                Divider(
                                  color: Colors.grey.shade200,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 12),
                                _logoutButton(context),
                                const SizedBox(height: 8),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

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

  Widget _errorState(ProfileController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              ctrl.errorMessage ?? 'Unable to load profile',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: ctrl.fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsText(String? initials) {
    return Text(
      initials?.isNotEmpty == true ? initials! : '--',
      style: const TextStyle(
        color: Color(0xFF6C5CE7),
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _profileHeader(ProfileController ctrl) {
    final p = ctrl.profile;
    final imageUrl = ProfileController.resolveImageUrl(p?.profileImage);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      imageUrl,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsText(p?.initials),
                    ),
                  )
                : _initialsText(p?.initials),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          p?.name.isNotEmpty == true ? p!.name : 'Employee',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3436),
          ),
        ),
        if (p?.roleName.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p!.roleName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _joiningDateSubtitle(ProfileController ctrl) {
    switch (ctrl.joiningDateSource) {
      case JoiningDateSource.firstAttendance:
        return 'Based on first attendance';
      case JoiningDateSource.enrollment:
        return 'Based on enrollment date';
      default:
        return null;
    }
  }

  Widget _editableTextRow({
    required BuildContext context,
    required ProfileController ctrl,
    required IconData icon,
    required String label,
    required String value,
    required String fieldTitle,
    required TextInputType keyboardType,
    required Future<bool> Function(String) onSave,
  }) {
    return InkWell(
      onTap: ctrl.isSaving
          ? null
          : () => _showEditFieldDialog(
                context: context,
                ctrl: ctrl,
                title: fieldTitle,
                initialValue: value,
                keyboardType: keyboardType,
                onSave: onSave,
              ),
      borderRadius: BorderRadius.circular(10),
      child: _infoRow(
        icon: icon,
        label: label,
        value: value.isNotEmpty ? value : 'Tap to add',
        trailing: ctrl.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6C5CE7),
                ),
              )
            : const Icon(
                Icons.edit_outlined,
                size: 20,
                color: Color(0xFF6C5CE7),
              ),
        valueColor: value.isNotEmpty
            ? const Color(0xFF2D3436)
            : const Color(0xFF8A8FA3),
      ),
    );
  }

  Future<void> _showEditFieldDialog({
    required BuildContext context,
    required ProfileController ctrl,
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
    required Future<bool> Function(String) onSave,
  }) async {
    final textController = TextEditingController(text: initialValue);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit $title'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: TextField(
            controller: textController,
            keyboardType: keyboardType,
            autofocus: true,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6C5CE7)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await onSave(textController.text);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, ok);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    if (saved == true) {
      _showSnackBar(context, '$title updated');
    } else if (saved == false && ctrl.errorMessage != null) {
      _showSnackBar(context, ctrl.errorMessage!, isError: true);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF6B6B) : const Color(0xFF00B894),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _dateOfBirthRow(BuildContext context, ProfileController ctrl) {
    final hasDob = ProfileController.isValidDateValue(ctrl.profile?.dateOfBirth);
    return InkWell(
      onTap: ctrl.isSaving ? null : () => _pickAndSaveDateOfBirth(context, ctrl),
      borderRadius: BorderRadius.circular(10),
      child: _infoRow(
        icon: Icons.cake_outlined,
        label: 'Date of Birth',
        value: hasDob
            ? ProfileController.formatDate(ctrl.profile!.dateOfBirth)
            : 'Tap to add',
        trailing: ctrl.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6C5CE7),
                ),
              )
            : Icon(
                hasDob ? Icons.edit_outlined : Icons.add_circle_outline,
                size: 20,
                color: const Color(0xFF6C5CE7),
              ),
        valueColor: hasDob ? const Color(0xFF2D3436) : const Color(0xFF8A8FA3),
      ),
    );
  }

  Future<void> _pickAndSaveDateOfBirth(
    BuildContext context,
    ProfileController ctrl,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.dateOfBirthPickerInitial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C5CE7),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3436),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final ok = await ctrl.updateDateOfBirth(picked);
      if (context.mounted) {
        if (ok) {
          _showSnackBar(context, 'Date of birth updated');
        } else if (ctrl.errorMessage != null) {
          _showSnackBar(context, ctrl.errorMessage!, isError: true);
        }
      }
    }
  }

  Widget _infoCard(BuildContext context, ProfileController ctrl) {
    final p = ctrl.profile;
    if (p == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _editableTextRow(
            context: context,
            ctrl: ctrl,
            icon: Icons.person_outline,
            label: 'Name',
            value: p.name,
            fieldTitle: 'Name',
            keyboardType: TextInputType.name,
            onSave: ctrl.updateName,
          ),
          _divider(),
          _infoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: p.email,
          ),
          _divider(),
          _editableTextRow(
            context: context,
            ctrl: ctrl,
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: p.phone,
            fieldTitle: 'Phone',
            keyboardType: TextInputType.phone,
            onSave: ctrl.updatePhone,
          ),
          _divider(),
          _dateOfBirthRow(context, ctrl),
          _divider(),
          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joining Date',
            value: ProfileController.formatDate(ctrl.effectiveJoiningDate),
            subtitle: _joiningDateSubtitle(ctrl),
          ),
          _divider(),
          _infoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: p.roleName.isNotEmpty ? p.roleName : '—',
          ),
          _divider(),
          _infoRow(
            icon: Icons.supervisor_account_outlined,
            label: 'Manager',
            value: p.managerName.isNotEmpty ? p.managerName : '—',
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.grey.shade100, height: 1);
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    Widget? trailing,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6C5CE7)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8FA3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF2D3436),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A8FA3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _uploadButton(BuildContext context, ProfileController ctrl) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.camera_alt_rounded, size: 18),
        label: const Text(
          'Upload Profile Image',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: ctrl.isSaving
            ? null
            : () async {
                final file = await ctrl.pickImageFromCamera();
                if (file != null && context.mounted) {
                  final ok = await ctrl.uploadProfileImage(file);
                  if (!context.mounted) return;
                  _showSnackBar(
                    context,
                    ok
                        ? 'Profile image uploaded'
                        : (ctrl.errorMessage ?? 'Upload failed'),
                    isError: !ok,
                  );
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
    );
  }

  Widget _logoutButton(BuildContext context) {
    return GetBuilder<DashboardController>(
      init: dashboardController,
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
}
