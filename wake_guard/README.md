# WakeGuard

WakeGuard ist eine Flutter-App für Android und iOS, die einen Wecker bereitstellt, der nur durch das Scannen eines zuvor hinterlegten QR-Codes oder NFC-Tags deaktiviert werden kann. Das Projekt kombiniert lokale Benachrichtigungen, QR-Scanning und NFC-Funktionen, um hartnäckige Alarme für Morgenmuffel zu ermöglichen.

## Features
- Wiederholende oder einmalige Alarme einstellen
- Eigene QR-Codes direkt in der App hinterlegen und anzeigen
- NFC-Tags registrieren, um den Alarm zu stoppen
- Vollbild-Alarmanzeige, die erst nach erfolgreichem Scan beendet werden kann

## Getting Started
1. Installiere die Flutter SDK (3.13 oder höher empfohlen) und führe `flutter pub get` im Projektordner aus.
2. Für Android: Passe die `android/app/src/main/AndroidManifest.xml` an und aktiviere benötigte Berechtigungen.
3. Für iOS: Öffne das Projekt in Xcode und aktiviere NFC-Fähigkeiten.
4. Starte die App mit `flutter run` auf einem angeschlossenen Gerät oder Emulator.

Weitere Details zu Berechtigungen und Konfigurationen findest du in den Kommentaren der jeweiligen Plattform-Dateien.
