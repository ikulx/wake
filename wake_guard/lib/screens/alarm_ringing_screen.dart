import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../widgets/qr_preview_dialog.dart';

class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({super.key});

  static const String routeName = '/alarm';

  static Widget route(BuildContext context) => const AlarmRingingScreen();

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  bool _isDisarmed = false;
  bool _isProcessing = false;
  String? _error;
  QRViewController? _qrController;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'ALARM_QR');

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    setState(() {
      _error = null;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('QR-Code scannen'),
        content: SizedBox(
          width: 280,
          height: 280,
          child: QRView(
            key: _qrKey,
            onQRViewCreated: (QRViewController controller) {
              _qrController = controller;
              controller.scannedDataStream.listen((Barcode data) async {
                controller.pauseCamera();
                final String? expectedCode = StorageService.instance.getQrCode();
                if (data.code == expectedCode) {
                  await _finishAlarm();
                } else {
                  setState(() {
                    _error = 'Falscher QR-Code. Versuche es erneut.';
                  });
                }
                if (mounted) Navigator.of(context).pop();
              });
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              _qrController?.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
    await _qrController?.resumeCamera();
  }

  Future<void> _scanNfc() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 15));
      await FlutterNfcKit.finish();
      final String? expected = StorageService.instance.getNfcIdentifier();
      if (tag.id == expected) {
        await _finishAlarm();
      } else {
        setState(() {
          _error = 'Unbekannter Tag erkannt.';
        });
      }
    } on Exception catch (error) {
      setState(() {
        _error = 'Fehler beim Lesen: ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _finishAlarm() async {
    await AlarmService.instance.cancelAlarm();
    if (!mounted) return;
    setState(() {
      _isDisarmed = true;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final DisarmMethod method = StorageService.instance.getMethod();
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade100,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.alarm, size: 96, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  _isDisarmed ? 'Geschafft!' : 'WakeGuard Alarm',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _isDisarmed
                      ? 'Du hast den Alarm erfolgreich deaktiviert.'
                      : method == DisarmMethod.qr
                          ? 'Scanne den hinterlegten QR-Code, um den Alarm zu stoppen.'
                          : 'Halte das Gerät an den hinterlegten NFC-Tag, um den Alarm zu stoppen.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (!_isDisarmed)
                  Column(
                    children: <Widget>[
                      if (method == DisarmMethod.qr)
                        FilledButton.icon(
                          onPressed: _scanQr,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('QR-Code scannen'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _isProcessing ? null : _scanNfc,
                          icon: const Icon(Icons.nfc),
                          label: Text(
                            _isProcessing ? 'Scannen...' : 'NFC scannen',
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          final String? data = method == DisarmMethod.qr
                              ? StorageService.instance.getQrCode()
                              : StorageService.instance.getNfcIdentifier();
                          if (data == null) return;
                          showDialog<void>(
                            context: context,
                            builder: (_) => QrPreviewDialog(
                              data: data,
                              title: method == DisarmMethod.qr
                                  ? 'Hinterlegter QR-Code'
                                  : 'NFC-Kennung',
                              description: method == DisarmMethod.qr
                                  ? 'Nutze diesen Code als Ausdruck.'
                                  : 'Dies ist die gespeicherte NFC-ID.',
                              showAsQr: method == DisarmMethod.qr,
                            ),
                          );
                        },
                        child: const Text('Details anzeigen'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
