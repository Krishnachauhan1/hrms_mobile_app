import 'package:employee_app/app_color.dart';
import 'package:employee_app/employee_flow/breaks/break_time_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BreakTimeScreen extends StatelessWidget {
  const BreakTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BreakTimeController>(
      init: BreakTimeController(),
      builder: (ctrl) => Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Break Time',
            style: TextStyle(
              color: Color(0xFF2D3436),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              onPressed: ctrl.isLoading ? null : ctrl.loadAll,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            ),
          ],
        ),
        body: ctrl.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: ctrl.loadAll,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AttendanceCard(ctrl: ctrl),
                      const SizedBox(height: 20),
                      _BreakCard(ctrl: ctrl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final BreakTimeController ctrl;

  const _AttendanceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final checkedIn = ctrl.isCheckedIn;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: checkedIn
              ? [const Color(0xFF00B894), const Color(0xFF00CEC9)]
              : [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (checkedIn ? const Color(0xFF00B894) : AppColors.primary)
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                checkedIn ? Icons.login_rounded : Icons.logout_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkedIn ? 'Checked In' : 'Not Checked In',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (ctrl.loginAt != null && checkedIn)
                      Text(
                        'Since ${ctrl.formatTime(ctrl.loginAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  checkedIn ? 'ON DUTY' : 'OFF DUTY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Check In',
                  icon: Icons.login,
                  enabled: !checkedIn && !ctrl.isSubmitting,
                  onTap: ctrl.punchIn,
                  filled: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  label: 'Check Out',
                  icon: Icons.logout,
                  enabled: checkedIn && !ctrl.isOnBreak && !ctrl.isSubmitting,
                  onTap: ctrl.punchOut,
                  filled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakCard extends StatelessWidget {
  final BreakTimeController ctrl;

  const _BreakCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.free_breakfast_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Take a Break',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ),
              if (ctrl.isOnBreak)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ON BREAK',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (ctrl.isOnBreak) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctrl.activeBreakTypeName ?? 'Break',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Started ${ctrl.formatTime(ctrl.breakStartAt)}'
                    '${ctrl.breakElapsed != null ? ' · ${ctrl.breakElapsed}' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF74788D),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Break type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF74788D),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<BreakTypeOption>(
            value: ctrl.selectedBreakType,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F9FE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            hint: const Text('Select break type'),
            items: ctrl.breakTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text('${t.name} (${t.durationLabel})'),
                  ),
                )
                .toList(),
            onChanged: ctrl.isCheckedIn && !ctrl.isOnBreak
                ? ctrl.selectBreakType
                : null,
          ),
          if (ctrl.breakTypes.isEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'No break types configured. Ask HR to add lunch, tea, etc.',
              style: TextStyle(fontSize: 12, color: Color(0xFF74788D)),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ctrl.isOnBreak
                ? FilledButton.icon(
                    onPressed: ctrl.isSubmitting || !ctrl.isCheckedIn
                        ? null
                        : ctrl.endBreak,
                    icon: ctrl.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.stop_circle_outlined),
                    label: const Text('End Break'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7675),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed:
                        ctrl.isSubmitting ||
                            !ctrl.isCheckedIn ||
                            ctrl.selectedBreakType == null ||
                            ctrl.breakTypes.isEmpty
                        ? null
                        : ctrl.startBreak,
                    icon: ctrl.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_circle_outline),
                    label: const Text('Start Break'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
          if (!ctrl.isCheckedIn) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF74788D)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Check in first to start a break.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF74788D)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool filled;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled
                    ? (enabled ? AppColors.primary : Colors.grey)
                    : Colors.white.withValues(alpha: enabled ? 1 : 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: filled
                      ? (enabled ? AppColors.primary : Colors.grey)
                      : Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
