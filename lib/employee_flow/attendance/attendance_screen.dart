import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3436)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Padding(
              padding: const EdgeInsets.only(right: 100),
              child: const Text(
                "Mark Attendance",
                style: TextStyle(
                  color: Color(0xFF2D3436),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  tooltip: 'Scan QR Code',
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF6C5CE7),
                  ),
                  onPressed: controller.isScanning
                      ? null
                      : () => _openQrScannerModal(context, controller),
                ),
              ),
            ],
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

  void _openQrScannerModal(
    BuildContext context,
    AttendanceController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrScannerSheet(controller: controller),
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
          _buildCameraArea(controller),
          const SizedBox(height: 30),
          _buildStatusBadge(controller),
          const SizedBox(height: 8),
          _buildStatusText(controller),
          const SizedBox(height: 30),
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

  Widget _buildCameraArea(AttendanceController controller) {
    return Stack(
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
        SizedBox(
          child: controller.isRecognized
              ? Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00B894),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                )
              : controller.isCameraInitialized &&
                    controller.cameraController != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CameraPreview(controller.cameraController!),
                )
              : controller.isCameraOpen
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                )
              : Icon(
                  controller.isCheckedIn
                      ? Icons.how_to_reg_rounded
                      : Icons.face_rounded,
                  size: 80,
                  color: controller.isCheckedIn
                      ? const Color(0xFF00B894)
                      : const Color(0xFF74788D),
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AttendanceController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: controller.isCheckedIn
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        controller.isCheckedIn ? 'Status: Checked In' : 'Status: Checked Out',
        style: TextStyle(
          color: controller.isCheckedIn ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusText(AttendanceController controller) {
    final title = controller.isRecognized
        ? 'Attendance Marked!'
        : controller.isScanning
        ? 'Scanning...'
        : controller.isCheckedIn
        ? 'Checked In'
        : 'Position your face';

    final subtitle = controller.isRecognized
        ? 'Successfully recognized at ${controller.markedTime ?? ''}'
        : controller.isScanning
        ? 'Please stay still'
        : controller.isCheckedIn
        ? 'Tap below to punch out when done'
        : 'Use Face or QR to mark attendance';

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: controller.isRecognized
                ? const Color(0xFF00B894)
                : const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Color(0xFF74788D)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton(AttendanceController controller) {
    if (controller.isScanning) {
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

    if (controller.isRecognized) return const SizedBox.shrink();

    if (!controller.isCheckedIn) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: controller.startCheckIn,
          icon: const Icon(Icons.face_rounded, color: Colors.white),
          label: const Text(
            'Scan Face to Check In',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.startCheckOut,
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: const Text(
          'Scan Face to Check Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

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
                    checkOut.isNotEmpty ? '$checkIn – $checkOut' : checkIn,
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

class _QrScannerSheet extends StatefulWidget {
  final AttendanceController controller;
  const _QrScannerSheet({required this.controller});

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _scanned = true;
    await _scannerController.stop();

    if (mounted) Navigator.pop(context);
    await widget.controller.onQrScanned(barcode.rawValue!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Scan QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Scanner
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                  // Overlay frame
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF6C5CE7),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Corner accents
                  ..._buildCornerAccents(),
                  // Hint label
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.controller.isCheckedIn
                              ? 'Scan QR to Check Out'
                              : 'Scan QR to Check In',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Decorative corner brackets around the scan area
  List<Widget> _buildCornerAccents() {
    const color = Color(0xFF6C5CE7);
    const size = 24.0;
    const thickness = 4.0;

    Widget corner({
      required AlignmentGeometry alignment,
      required BorderRadius borderRadius,
    }) {
      return Align(
        alignment: alignment,
        child: Container(
          margin: EdgeInsets.only(
            left:
                alignment == Alignment.centerLeft ||
                    alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? (MediaQuery.of(context).size.width - 250) / 2
                : 0,
            right:
                alignment == Alignment.centerRight ||
                    alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? (MediaQuery.of(context).size.width - 250) / 2
                : 0,
          ),
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              top:
                  borderRadius ==
                          BorderRadius.only(topLeft: Radius.circular(8)) ||
                      borderRadius ==
                          BorderRadius.only(topRight: Radius.circular(8))
                  ? const BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              bottom:
                  borderRadius ==
                          BorderRadius.only(bottomLeft: Radius.circular(8)) ||
                      borderRadius ==
                          BorderRadius.only(bottomRight: Radius.circular(8))
                  ? const BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              left:
                  borderRadius ==
                          BorderRadius.only(topLeft: Radius.circular(8)) ||
                      borderRadius ==
                          BorderRadius.only(bottomLeft: Radius.circular(8))
                  ? const BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              right:
                  borderRadius ==
                          BorderRadius.only(topRight: Radius.circular(8)) ||
                      borderRadius ==
                          BorderRadius.only(bottomRight: Radius.circular(8))
                  ? const BorderSide(color: color, width: thickness)
                  : BorderSide.none,
            ),
          ),
        ),
      );
    }

    // Simpler approach — just use a CustomPaint overlay instead
    return [
      Positioned.fill(child: CustomPaint(painter: _ScannerOverlayPainter())),
    ];
  }
}

/// Draws a dimmed overlay with a clear rectangle in the center + corner brackets
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutOutSize = 250.0;
    const cornerSize = 28.0;
    const cornerThickness = 4.0;
    const cornerColor = Color(0xFF6C5CE7);
    const radius = 12.0;

    final left = (size.width - cutOutSize) / 2;
    final top = (size.height - cutOutSize) / 2;
    final rect = Rect.fromLTWH(left, top, cutOutSize, cutOutSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));

    // Dim background
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutPath = Path()..addRRect(rrect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutPath),
      dimPaint,
    );

    // Corner brackets
    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = cornerThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerSize)
        ..lineTo(left, top + radius)
        ..arcToPoint(
          Offset(left + radius, top),
          radius: const Radius.circular(radius),
        )
        ..lineTo(left + cornerSize, top),
      cornerPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(left + cutOutSize - cornerSize, top)
        ..lineTo(left + cutOutSize - radius, top)
        ..arcToPoint(
          Offset(left + cutOutSize, top + radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(left + cutOutSize, top + cornerSize),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cutOutSize - cornerSize)
        ..lineTo(left, top + cutOutSize - radius)
        ..arcToPoint(
          Offset(left + radius, top + cutOutSize),
          radius: const Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(left + cornerSize, top + cutOutSize),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(left + cutOutSize - cornerSize, top + cutOutSize)
        ..lineTo(left + cutOutSize - radius, top + cutOutSize)
        ..arcToPoint(
          Offset(left + cutOutSize, top + cutOutSize - radius),
          radius: const Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(left + cutOutSize, top + cutOutSize - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
