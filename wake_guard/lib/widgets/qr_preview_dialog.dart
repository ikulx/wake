import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPreviewDialog extends StatelessWidget {
  const QrPreviewDialog({
    super.key,
    required this.data,
    this.title,
    this.description,
    this.showAsQr = true,
  });

  final String data;
  final String? title;
  final String? description;
  final bool showAsQr;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'QR-Code Vorschau'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showAsQr)
            QrImageView(
              data: data,
              size: 220,
            )
          else
            SelectableText(
              data,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          if (description != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              description!,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}
