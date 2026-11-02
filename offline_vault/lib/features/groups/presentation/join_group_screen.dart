import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_spacing.dart';
import '../application/groups_controller.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() => _isScanning = false);
  }

  Future<void> _joinWithCode(String rawCode) async {
    final code = rawCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim().toUpperCase();
    if (code.length < 6 || code.length > 16) {
      setState(() => _errorMessage = 'Please enter a valid invite code (e.g. XXXX-XXXX)');
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    final res = await ref.read(groupsControllerProvider.notifier).joinGroup(code);

    if (mounted) {
      setState(() => _isJoining = false);
      if (res != null) {
        final group = res['group'] as Map<String, dynamic>;
        context.go('/group/${group['id']}');
      } else {
        setState(() => _errorMessage = 'Invalid, expired, or disabled invite code.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Vault'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isScanning) ...[
              SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: _scannerController,
                    errorBuilder: (context, error, child) {
                      return Container(
                        color: Colors.black87,
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Camera access required to scan QR code.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please enable Camera permission in your phone Settings.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final val = barcode.rawValue;
                        if (val != null && val.isNotEmpty) {
                          _stopScanner();
                          _codeController.text = val;
                          _joinWithCode(val);
                          break;
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _stopScanner,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel QR Scan'),
              ),
            ] else ...[
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.vpn_key_outlined, size: 36, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Enter Vault Code',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the 8-character code shared by the vault owner to join instantly as Viewer.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: AppSpacing.xxl),

              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 6, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'XXXX-XXXX',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _errorMessage,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              FilledButton(
                onPressed: _isJoining ? null : () => _joinWithCode(_codeController.text),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isJoining
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Join Vault'),
              ),
              const SizedBox(height: AppSpacing.md),

              OutlinedButton.icon(
                onPressed: _startScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan QR Code'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
