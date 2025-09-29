import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../widgets/qr_preview_dialog.dart';
import '../widgets/time_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool _repeat = false;
  DisarmMethod _method = DisarmMethod.qr;
  String? _qrCode;
  String? _nfcIdentifier;

  @override
  void initState() {
    super.initState();
    _loadSavedValues();
  }

  Future<void> _loadSavedValues() async {
    final StorageService storage = StorageService.instance;
    final TimeOfDay? savedTime = storage.getAlarmTime();
    final bool repeat = storage.getRepeat();
    final DisarmMethod method = storage.getMethod();
    setState(() {
      _selectedTime = savedTime ?? _selectedTime;
      _repeat = repeat;
      _method = method;
      _qrCode = storage.getQrCode();
      _nfcIdentifier = storage.getNfcIdentifier();
    });
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
      await StorageService.instance.saveAlarmTime(picked);
    }
  }

  Future<void> _scheduleAlarm() async {
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await StorageService.instance.saveRepeat(_repeat);
    await StorageService.instance.saveMethod(_method);

    await AlarmService.instance.scheduleAlarm(
      scheduledDate: tzDate,
      repeats: _repeat,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alarm auf ${_selectedTime.format(context)} gesetzt (${_repeat ? 'täglich' : 'einmalig'}).',
        ),
      ),
    );
  }

  Future<void> _registerQrCode() async {
    final PermissionStatus status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera-Berechtigung erforderlich.')),
        );
      }
      return;
    }

    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const _QrScannerScreen(),
      ),
    );

    if (result != null) {
      await StorageService.instance.saveQrCode(result);
      setState(() => _qrCode = result);
    }
  }

  Future<void> _registerNfcTag() async {
    final NfcAvailability availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NfcAvailability.available) {
      if (mounted) {
        final String message = switch (availability) {
          NfcAvailability.disabled =>
            'NFC ist deaktiviert. Bitte aktiviere es in den Einstellungen.',
          NfcAvailability.notSupported =>
            'Dieses Gerät unterstützt kein NFC.',
          _ => 'NFC ist aktuell nicht verfügbar.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return;
    }

    if (!mounted) return;
    final String? identifier = await showDialog<String>(
      context: context,
      builder: (_) => const _NfcRegistrationDialog(),
    );

    if (identifier != null) {
      await StorageService.instance.saveNfcIdentifier(identifier);
      setState(() => _nfcIdentifier = identifier);
    }
  }

  void _showQrPreview() {
    if (_qrCode == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => QrPreviewDialog(data: _qrCode!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('WakeGuard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            Text('Alarmzeit', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            TimeSelector(
              time: _selectedTime,
              onTap: () => _pickTime(context),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              title: const Text('Täglich wiederholen'),
              value: _repeat,
              onChanged: (bool value) {
                setState(() => _repeat = value);
                StorageService.instance.saveRepeat(value);
              },
            ),
            const SizedBox(height: 16),
            Text('Entsperr-Methode', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<DisarmMethod>(
              segments: const <ButtonSegment<DisarmMethod>>[
                ButtonSegment<DisarmMethod>(
                  value: DisarmMethod.qr,
                  icon: Icon(Icons.qr_code_2),
                  label: Text('QR-Code'),
                ),
                ButtonSegment<DisarmMethod>(
                  value: DisarmMethod.nfc,
                  icon: Icon(Icons.nfc),
                  label: Text('NFC'),
                ),
              ],
              selected: <DisarmMethod>{_method},
              onSelectionChanged: (Set<DisarmMethod> value) {
                setState(() => _method = value.first);
                StorageService.instance.saveMethod(value.first);
              },
            ),
            const SizedBox(height: 16),
            if (_method == DisarmMethod.qr)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: Text(_qrCode ?? 'Noch kein QR-Code gespeichert'),
                  subtitle: const Text('Scanne einen Code, um ihn als Entsperrung zu nutzen.'),
                  trailing: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: _qrCode == null ? null : _showQrPreview,
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _registerQrCode,
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.nfc),
                  title: Text(
                    _nfcIdentifier ?? 'Noch kein NFC-Tag registriert',
                  ),
                  subtitle: const Text('Halte den gewünschten Tag an das Gerät.'),
                  trailing: IconButton(
                    icon: const Icon(Icons.sensors),
                    onPressed: _registerNfcTag,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _method == DisarmMethod.qr && _qrCode == null
                  ? null
                  : _method == DisarmMethod.nfc && _nfcIdentifier == null
                      ? null
                      : _scheduleAlarm,
              icon: const Icon(Icons.alarm_add),
              label: const Text('Alarm speichern'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen({super.key});

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void reassemble() {
    super.reassemble();
    if (defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_controller.stop());
    }
    unawaited(_controller.start());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR-Code scannen')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      return;
    }

    final Barcode barcode = barcodes.firstWhere(
      (Barcode candidate) =>
          candidate.rawValue != null && candidate.rawValue!.isNotEmpty,
      orElse: () => barcodes.first,
    );

    final String? value = barcode.rawValue;
    if (value == null || !mounted) {
      return;
    }

    await _controller.stop();
    if (mounted) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _NfcRegistrationDialog extends StatefulWidget {
  const _NfcRegistrationDialog();

  @override
  State<_NfcRegistrationDialog> createState() => _NfcRegistrationDialogState();
}

class _NfcRegistrationDialogState extends State<_NfcRegistrationDialog> {
  bool _isScanning = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('NFC-Tag registrieren'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_isScanning)
              const CircularProgressIndicator()
            else
              const Icon(Icons.nfc, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ??
                  (_isScanning
                      ? 'Halte das Gerät an den Tag...'
                      : 'Tippe auf Start, um den Tag anzulernen.'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isScanning ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isScanning ? null : _startScanning,
          child: const Text('Start'),
        ),
      ],
    );
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 10));
      await FlutterNfcKit.finish();
      if (!mounted) return;
      Navigator.of(context).pop(tag.id);
    } on Exception catch (error) {
      setState(() {
        _error = 'Fehler: ${error.toString()}';
        _isScanning = false;
      });
    }
  }
}
