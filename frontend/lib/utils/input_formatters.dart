import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return next.copyWith(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buf.write(':');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return next.copyWith(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

DateTime? parseData(String s) {
  try {
    final p = s.split('/');
    if (p.length != 3) return null;
    final d = int.parse(p[0]), m = int.parse(p[1]), y = int.parse(p[2]);
    if (d < 1 || d > 31 || m < 1 || m > 12 || y < 2024) return null;
    return DateTime(y, m, d);
  } catch (_) {
    return null;
  }
}

TimeOfDay? parseHora(String s) {
  try {
    final p = s.split(':');
    if (p.length != 2) return null;
    final h = int.parse(p[0]), min = int.parse(p[1]);
    if (h < 0 || h > 23 || min < 0 || min > 59) return null;
    return TimeOfDay(hour: h, minute: min);
  } catch (_) {
    return null;
  }
}

String isoParaDisplay(String iso) {
  try {
    final p = iso.substring(0, 10).split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  } catch (_) {
    return iso;
  }
}

String? displayParaIso(String display) {
  try {
    final p = display.split('/');
    if (p.length != 3 || p[2].length != 4) return null;
    return '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}';
  } catch (_) {
    return null;
  }
}
