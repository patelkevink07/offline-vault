import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../application/groups_controller.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final List<TextEditingController> _digitControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _isJoining = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _scannerController?.dispose();
    super.dispose();
  }

  String get _currentCode =>
      _digitControllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handles pasting full or partial code into any box
      _handlePaste(value);
      return;
    }

    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentCode.length == 4) {
          _joinWithCode(_currentCode);
        }
      }
    }
  }

  Future<void> _handlePaste(String text) async {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    final count = digits.length.clamp(0, 4);
    for (var i = 0; i < 4; i++) {
      if (i < count) {
        _digitControllers[i].text = digits[i];
      } else {
        _digitControllers[i].clear();
      }
    }

    if (count == 4) {
      _focusNodes[3].unfocus();
      await _joinWithCode(digits.substring(0, 4));
    } else {
      _focusNodes[count].requestFocus();
    }
  }

  void _startScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _infoMessage = null;
    });
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() => _isScanning = false);
  }

  Future<void> _joinWithCode(String rawCode) async {
    final code = rawCode.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final l10n = AppLocalizations.of(context);

    if (code.length != 4) {
      setState(() {
        _errorMessage = l10n.enter4DigitCode;
        _infoMessage = null;
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final res =
          await ref.read(groupsControllerProvider.notifier).joinGroup(code);

      if (!mounted) return;

      setState(() => _isJoining = false);

      if (res != null) {
        final status = res['status'] as String?;
        final group = res['group'] as Map<String, dynamic>?;
        final groupId = (group?['id'] ?? res['group_id']) as String?;

        if (status == 'pending') {
          setState(() {
            _infoMessage = l10n.requestPendingApproval;
          });
          return;
        }

        if (groupId != null) {
          context.go('/group/$groupId');
        }
      } else {
        setState(() => _errorMessage = l10n.invalidOrExpiredCode);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);

      final err = e.toString().toLowerCase();
      if (err.contains('hour') || err.contains('too many failed attempts')) {
        setState(() => _errorMessage = l10n.tooManyAttempts);
      } else if (err.contains('traffic') || err.contains('paused')) {
        setState(() => _errorMessage = l10n.trafficPaused);
      } else if (err.contains('removed')) {
        setState(() => _errorMessage = l10n.removedFromGroup);
      } else {
        setState(() => _errorMessage = l10n.invalidOrExpiredCode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinVault),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isScanning) ...[
              SizedBox(
                height: 300,
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
                              const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error.errorDetails?.message ??
                                    'Camera error',
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      final val = barcode?.rawValue;
                      if (val != null) {
                        _stopScanner();
                        _handlePaste(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _stopScanner,
                icon: const Icon(Icons.close_rounded),
                label: Text(l10n.stopScanner),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              l10n.enter4DigitCode,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4-box numeric PIN input with paste support
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  width: 58,
                  height: 68,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace &&
                          _digitControllers[index].text.isEmpty &&
                          index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                    child: TextField(
                      controller: _digitControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (val) => _onDigitChanged(index, val),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),

            // Paste button helper
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    await _handlePaste(data!.text!);
                  }
                },
                icon: const Icon(Icons.paste_rounded, size: 18),
                label: Text(l10n.copyCode.replaceAll('Copy', 'Paste')),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightError.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.lightError,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.lightError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Info Message (e.g. pending approval)
            if (_infoMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightAmberContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppColors.lightAmberText,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _infoMessage!,
                        style: const TextStyle(
                          color: AppColors.lightAmberText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            FilledButton(
              onPressed: _isJoining
                  ? null
                  : () => _joinWithCode(_currentCode),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isJoining
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.joinWithCode),
            ),
            const SizedBox(height: AppSpacing.md),

            // Scan QR Button
            if (!_isScanning)
              OutlinedButton.icon(
                onPressed: _startScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(l10n.scanQrCode),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
