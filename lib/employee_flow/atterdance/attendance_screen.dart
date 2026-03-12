import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'attendance_controller.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AttendanceController>(
      init: AttendanceController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3436)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Mark Attendance',
              style: TextStyle(
                color: Color(0xFF2D3436),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildFaceRecognitionCard(context, controller),
                const SizedBox(height: 25),
                _buildAttendanceHistory(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaceRecognitionCard(
    BuildContext context,
    AttendanceController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Face Recognition Attendance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 30),

          Stack(
            alignment: Alignment.center,
            children: [
              if (controller.isScanning)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.1),
                  duration: const Duration(milliseconds: 900),
                  builder: (_, scale, __) => Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6C5CE7).withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),

              // Content inside ring
              SizedBox(
                child: controller.isRecognized
                    ? const Icon(
                        Icons.check_circle_rounded,
                        size: 80,
                        color: Colors.white,
                      )
                    : controller.isCameraInitialized &&
                          controller.cameraController != null
                    ? ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(14),
                        child: CameraPreview(controller.cameraController!),
                      )
                    : Icon(
                        Icons.face_rounded,
                        size: 80,
                        color: controller.isScanning
                            ? Colors.white
                            : const Color(0xFF74788D),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Status badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: controller.isCheckedIn
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              controller.isCheckedIn
                  ? 'Status: Checked In'
                  : 'Status: Checked Out',
              style: TextStyle(
                color: controller.isCheckedIn ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Status text
          Text(
            controller.isRecognized
                ? 'Attendance Marked!'
                : controller.isScanning
                ? 'Scanning...'
                : controller.isCheckedIn
                ? 'Checked In ✓'
                : 'Position your face',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: controller.isRecognized
                  ? const Color(0xFF00B894)
                  : const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.isRecognized
                ? 'Successfully recognized at ${controller.markedTime ?? ''}'
                : controller.isScanning
                ? 'Please stay still'
                : controller.isCheckedIn
                ? 'Tap below to punch out when done'
                : 'Tap the button to start scanning',
            style: const TextStyle(fontSize: 14, color: Color(0xFF74788D)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // ── Action Buttons ──
          _buildActionButton(controller),

          if (controller.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              controller.errorMessage!,
              style: const TextStyle(color: Color(0xFFFF7675), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Center widget logic:

  Widget _buildCenterWidget(AttendanceController controller) {
    if (controller.isRecognized) {
      return Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF00B894),
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          size: 80,
          color: Colors.white,
        ),
      );
    }

    if (controller.isCameraOpen) {
      if (controller.isCameraInitialized &&
          controller.cameraController != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CameraPreview(controller.cameraController!),
        );
      } else {
        // Camera opening — show spinner
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
        );
      }
    }

    // Default idle state — just face icon
    return Icon(
      controller.isCheckedIn ? Icons.how_to_reg_rounded : Icons.face_rounded,
      size: 80,
      color: controller.isCheckedIn
          ? const Color(0xFF00B894)
          : const Color(0xFF74788D),
    );
  }

  /// Button logic:

  Widget _buildActionButton(AttendanceController controller) {
    if (controller.isScanning) {
      // Scanning in progress — show disabled indicator
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.isRecognized) {
      // After success — nothing, auto-resets
      return const SizedBox.shrink();
    }

    if (!controller.isCheckedIn) {
      // Punch IN button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.startCheckIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Start Scanning',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Punch OUT button — only shown when checked in
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.startCheckOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Logout Attendance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Attendance History
  Widget _buildAttendanceHistory(AttendanceController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 15),

        if (controller.isLoadingHistory)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            ),
          )
        else if (controller.historyList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No attendance records found.',
                style: TextStyle(color: Color(0xFF74788D), fontSize: 14),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.historyList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final record = controller.historyList[i];
              return _buildHistoryItem(
                date: record.displayDate,
                checkIn: record.loginTime ?? 'Absent',
                checkOut: record.logoutTime ?? '',
                hours: record.totalHours ?? '',
                isPresent: record.isPresent,
              );
            },
          ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String date,
    required String checkIn,
    required String checkOut,
    required String hours,
    required bool isPresent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFF00B894)
                  : const Color(0xFFFF7675),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 6),
                if (isPresent)
                  Text(
                    '$checkIn - $checkOut',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF74788D),
                    ),
                  )
                else
                  Text(
                    checkIn,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFF7675),
                    ),
                  ),
              ],
            ),
          ),
          if (isPresent && hours.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hours,
                style: const TextStyle(
                  color: Color(0xFF00B894),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
