import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:employee_app/employee_flow/employee_permission_controller.dart';
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
      builder: (controller) => Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF2D3436),
            ),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Mark Attendance',
            style: TextStyle(
              color: Color(0xFF2D3436),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GetBuilder<EmployeeFeatureController>(
                builder: (ctrl) {
                  return IconButton(
                    tooltip: ctrl.canUseFace
                        ? 'Face Recognition'
                        : 'Face Recognition (Not Allowed)',
                    icon: Icon(
                      Icons.face_rounded,
                      color: ctrl.canUseFace
                          ? const Color(0xFF6C5CE7)
                          : Colors.grey.shade400,
                    ),
                    onPressed: ctrl.canUseFace
                        ? () => _openFaceSheet(context, controller)
                        : () {
                            Get.snackbar(
                              'Access Denied',
                              'Face recognition permission not granted by admin',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                  );
                },
              ),
            ),
          ],
        ),
        body: controller.isProcessingQr
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildQrCard(context, controller),
                    const SizedBox(height: 25),
                    _buildHistory(controller),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQrCard(BuildContext context, AttendanceController controller) {
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
            'QR Code Attendance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 30),
          _qrIconArea(controller),
          const SizedBox(height: 30),
          _statusBadge(controller),
          const SizedBox(height: 8),
          _statusText(controller),
          const SizedBox(height: 30),
          _qrButton(context, controller),
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

  Widget _qrIconArea(AttendanceController controller) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (controller.isProcessingQr)
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
          width: 180,
          height: 180,
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
              : controller.isProcessingQr
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                )
              : Icon(
                  controller.isCheckedIn
                      ? Icons.qr_code_scanner_rounded
                      : Icons.qr_code_2_rounded,
                  size: 100,
                  color: controller.isCheckedIn
                      ? const Color(0xFF00B894)
                      : const Color(0xFF74788D),
                ),
        ),
      ],
    );
  }

  Widget _qrButton(BuildContext context, AttendanceController controller) {
    if (controller.isProcessingQr) {
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
          child: const Text('Processing...'),
        ),
      );
    }
    if (controller.isRecognized) return const SizedBox.shrink();

    final isIn = controller.isCheckedIn;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openQrSheet(context, controller),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: Text(
          isIn ? 'Scan QR to Check Out' : 'Scan QR to Check In',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isIn ? Colors.redAccent : const Color(0xFF6C5CE7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _statusBadge(AttendanceController controller) {
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

  Widget _statusText(AttendanceController controller) {
    final title = controller.isRecognized
        ? 'Attendance Marked!'
        : controller.isProcessingQr
        ? 'Processing...'
        : controller.isCheckedIn
        ? 'Checked In'
        : 'Scan QR Code';
    final subtitle = controller.isRecognized
        ? 'Successfully marked at ${controller.markedTime ?? ''}'
        : controller.isProcessingQr
        ? 'Please wait'
        : controller.isCheckedIn
        ? 'Tap below to scan QR and punch out'
        : 'Use QR Scanner to mark Your Attendance';
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

  void _openQrSheet(BuildContext context, AttendanceController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrScannerSheet(controller: controller),
    );
  }

  void _openFaceSheet(BuildContext context, AttendanceController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (_) => _FaceRecognitionSheet(controller: controller),
    );
  }

  Widget _buildHistory(AttendanceController controller) {
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
              final r = controller.historyList[i];
              return _historyItem(
                date: r.displayDate,
                checkIn: controller.formatDateTime(r.loginAt),
                subtitle: r.logoutAt != null
                    ? controller.formatDateTime(r.logoutAt!)
                    : 'Still working',
                hours: r.totalHours != null
                    ? controller.formatWorkHours(r.totalHours!)
                    : '',
                isPresent: r.isPresent,
              );
            },
          ),
      ],
    );
  }

  Widget _historyItem({
    required String date,
    required String checkIn,
    required String subtitle,
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
                Text(
                  isPresent ? '$checkIn – $subtitle' : checkIn,
                  style: TextStyle(
                    fontSize: 13,
                    color: isPresent
                        ? const Color(0xFF74788D)
                        : const Color(0xFFFF7675),
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
  final MobileScannerController _qrCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _qrCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    final qrData = barcode.rawValue!;
    if (!_isValid(qrData)) {
      Get.snackbar('Invalid QR', 'This QR is not for attendance');
      return;
    }
    _scanned = true;
    await _qrCtrl.stop();
    if (mounted) Navigator.pop(context);
    await widget.controller.onQrScanned(qrData);
  }

  bool _isValid(String data) {
    try {
      final d = jsonDecode(data);
      if (d is Map &&
          d['type'] == 'attendance' &&
          d.containsKey('office_id') &&
          d.containsKey('timestamp')) {
        return DateTime.now().millisecondsSinceEpoch - (d['timestamp'] as int) <
            60000;
      }
      return true;
    } catch (_) {
      return false;
    }
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
          _handle(),
          _sheetHeader(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan QR Code',
            onClose: () => Navigator.pop(context),
            iconColor: Colors.white,
            titleColor: Colors.white,
            closeColor: Colors.white70,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  MobileScanner(controller: _qrCtrl, onDetect: _onDetect),
                  Positioned.fill(
                    child: CustomPaint(painter: _OverlayPainter()),
                  ),
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
}

class _FaceRecognitionSheet extends StatefulWidget {
  final AttendanceController controller;
  const _FaceRecognitionSheet({required this.controller});

  @override
  State<_FaceRecognitionSheet> createState() => _FaceRecognitionSheetState();
}

class _FaceRecognitionSheetState extends State<_FaceRecognitionSheet> {
  bool _cameraReady = false;
  bool _processing = false;
  bool _success = false;
  bool _started = false;
  String? _error;
  CameraController? _cam;

  @override
  void initState() {
    super.initState();
    _initAndScan();
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  Future<void> _initAndScan() async {
    if (_started) return;
    _started = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setError('No camera found on this device.');
        return;
      }
      final front =
          cameras.firstWhereOrNull(
            (c) => c.lensDirection == CameraLensDirection.front,
          ) ??
          cameras.first;

      _cam = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cam!.initialize();

      if (!mounted) return;
      setState(() => _cameraReady = true);

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await _capture();
    } on CameraException catch (e) {
      _setError(
        e.description?.contains('permission') == true
            ? 'Camera permission denied. Enable in settings.'
            : 'Camera error: ${e.description}',
      );
    } catch (e) {
      _setError('Camera unavailable. Please try again.');
    }
  }

  Future<void> _capture() async {
    if (_processing || _cam == null || !_cam!.value.isInitialized) {
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final photo = await _cam!.takePicture();
      final tempCam = _cam;
      _cam = null;
      _cameraReady = false;
      if (mounted) {
        setState(() {});
      }
      await tempCam?.dispose();

      final String? failureMessage = widget.controller.isCheckedIn
          ? await widget.controller.markFaceCheckOut(photo.path)
          : await widget.controller.markFaceCheckIn(photo.path);

      if (!mounted) return;

      if (failureMessage != null) {
        _setError(failureMessage);
        return;
      }

      setState(() {
        _processing = false;
        _success = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _setError('Something went wrong. Please try again.');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _error = msg;
      _cameraReady = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _handle(color: Colors.white24),
          _sheetHeader(
            icon: Icons.face_rounded,
            title: widget.controller.isCheckedIn
                ? 'Face Check-Out'
                : 'Face Check-In',
            onClose: _processing
                ? null
                : () {
                    _cam?.dispose();
                    Navigator.pop(context);
                  },
            iconColor: const Color(0xFF6C5CE7),
            titleColor: Colors.white,
            closeColor: Colors.white70,
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraReady &&
                    _cam != null &&
                    _cam!.value.isInitialized &&
                    !_success)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: CameraPreview(_cam!),
                  )
                else
                  Container(color: const Color(0xFF1A1A2E)),
                if (_cameraReady && !_success && !_processing)
                  Positioned.fill(
                    child: CustomPaint(painter: _FaceOverlayPainter()),
                  ),
                if (_success)
                  Container(
                    color: const Color(0xFF00B894).withOpacity(0.85),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 90,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Attendance Marked!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_processing && !_success)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                          SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_cameraReady && !_success && _error == null)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                        SizedBox(height: 16),
                        Text(
                          'Opening camera...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7675).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.face_retouching_off_rounded,
                              color: Color(0xFFFF7675),
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Attendance not marked',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.28,
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _error = null;
                                  _started = false;
                                  _cameraReady = false;
                                  _processing = false;
                                });
                                _initAndScan();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_cameraReady && !_processing && !_success && _error == null)
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
                        child: const Text(
                          'Look at camera — capturing in 2s...',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Shared helpers
Widget _handle({Color color = Colors.black12}) => Container(
  margin: const EdgeInsets.only(top: 12, bottom: 8),
  width: 40,
  height: 4,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(2),
  ),
);

Widget _sheetHeader({
  required IconData icon,
  required String title,
  required VoidCallback? onClose,
  required Color iconColor,
  required Color titleColor,
  required Color closeColor,
}) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  child: Row(
    children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(width: 10),
      Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const Spacer(),
      IconButton(
        icon: Icon(Icons.close, color: closeColor),
        onPressed: onClose,
      ),
    ],
  ),
);

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cut = 250.0, corner = 28.0, thick = 4.0, r = 12.0;
    const color = Color(0xFF6C5CE7);
    final l = (size.width - cut) / 2, t = (size.height - cut) / 2;
    final rect = Rect.fromLTWH(l, t, cut, cut);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(r))),
      ),
      Paint()..color = Colors.black.withOpacity(0.55),
    );
    final p = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(_corner(l, t, r, corner, 0), p)
      ..drawPath(_corner(l + cut, t, r, corner, 1), p)
      ..drawPath(_corner(l, t + cut, r, corner, 2), p)
      ..drawPath(_corner(l + cut, t + cut, r, corner, 3), p);
  }

  Path _corner(double x, double y, double r, double s, int q) {
    final path = Path();
    switch (q) {
      case 0:
        path
          ..moveTo(x, y + s)
          ..lineTo(x, y + r)
          ..arcToPoint(Offset(x + r, y), radius: Radius.circular(r))
          ..lineTo(x + s, y);
        break;
      case 1:
        path
          ..moveTo(x - s, y)
          ..lineTo(x - r, y)
          ..arcToPoint(Offset(x, y + r), radius: Radius.circular(r))
          ..lineTo(x, y + s);
        break;
      case 2:
        path
          ..moveTo(x, y - s)
          ..lineTo(x, y - r)
          ..arcToPoint(
            Offset(x + r, y),
            radius: Radius.circular(r),
            clockwise: false,
          )
          ..lineTo(x + s, y);
        break;
      case 3:
        path
          ..moveTo(x - s, y)
          ..lineTo(x - r, y)
          ..arcToPoint(
            Offset(x, y - r),
            radius: Radius.circular(r),
            clockwise: false,
          )
          ..lineTo(x, y - s);
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 250.0, borderRadius = 20.0;
    final cx = size.width / 2, cy = size.height / 2 - 20;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: boxSize,
      height: boxSize,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(borderRadius),
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(rrect),
      ),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF6C5CE7)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
