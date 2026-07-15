import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:face_time_keeping/data/local/local_service.dart';
import 'package:face_time_keeping/pages/bloc/app_bloc.dart';
import 'package:face_time_keeping/di/injection.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Single-responsibility: show and validate license, with strong guards against
/// duplicate dialogs and multiple pops.
class LicenseKeyPopup {
  static bool _isShowing = false;

  /// Attempts to validate the current license.
  /// If invalid/expired or validation throws, shows the dialog.
  static Future<void> showAndValidate(BuildContext context) async {
    if (_isShowing) return;

    bool needsDialog = false;
    try {
      // If throws or returns "expired", we need the dialog.
      final expired = await getIt<AppBloc>().isExpiredLicenseKey();
      needsDialog = expired == true;
    } catch (_) {
      needsDialog = true;
    }

    if (!needsDialog) return;

    await show(context);
  }

  /// Opens the dialog. Safe against concurrent calls.
  static Future<String?> show(BuildContext context) async {
    if (_isShowing) return null;
    _isShowing = true;

    final controller = TextEditingController();
    final focus = FocusNode();

    String? result;

    try {
      result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) _isShowing = false;
            },
            child: AlertDialog(
              title: const Text('Enter License Key'),
              content: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focus,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onSubmit(ctx, controller.text),
                      decoration: const InputDecoration(
                        hintText: 'License Key',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Scan QR',
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final scanned = await Navigator.of(ctx).push<String>(
                        MaterialPageRoute(
                          builder: (_) => const MobileScannerView(),
                          fullscreenDialog: true,
                        ),
                      );
                      if (scanned != null && scanned.isNotEmpty) {
                        controller.text = scanned.trim();
                        focus.requestFocus();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _isShowing = false;
                    SystemNavigator.pop(); // friendlier than exit(0) on mobile
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => _onSubmit(ctx, controller.text),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
      focus.dispose();
      _isShowing = false;
    }

    return result;
  }

  /// Validates and persists the key, shows feedback, and closes dialog on success.
  static Future<void> _onSubmit(BuildContext context, String raw) async {
    final licenseKey = raw.trim();
    if (licenseKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a license key')),
      );
      return;
    }

    try {
      // AppBloc.isExpiredLicenseKey returns true when INVALID/EXPIRED
      final isInvalid =
          await getIt<AppBloc>().isExpiredLicenseKey(li_Key: licenseKey);

      if (isInvalid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('License key is invalid'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await getIt<LocalService>().saveLicenseKey(licenseKey);

      if (context.mounted) {
        Navigator.of(context).pop(licenseKey);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('License entered successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving license key: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class MobileScannerView extends StatefulWidget {
  const MobileScannerView({super.key});

  @override
  State<MobileScannerView> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<MobileScannerView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _handled = false;

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload behavior
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
    } else if (Platform.isIOS) {
      _controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    // Ensure camera is stopped and controller disposed
    _controller?.stopCamera();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan License QR')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Theme.of(context).colorScheme.primary,
                  borderRadius: 8,
                  borderLength: 24,
                  borderWidth: 6,
                  cutOutSize: MediaQuery.of(context).size.width * 0.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Align the QR code within the frame',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;

    // Optimize: listen once and guard, then stop camera & pop with result.
    controller.scannedDataStream.listen((scanData) async {
      if (_handled) return;
      _handled = true;

      final code = scanData.code?.trim();
      if (code == null || code.isEmpty) {
        _handled = false; // allow next frame if empty read
        return;
      }

      try {
        await _controller?.stopCamera();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pop(code);
    });
  }
}
