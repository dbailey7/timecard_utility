import 'package:flutter/material.dart';

class TimecardResult {
  final String primary;
  final String detail;
  const TimecardResult({required this.primary, required this.detail});
}

class TimecardNotifier extends ChangeNotifier {

  // The TextField widget holds a reference to this controller.
  // appendToInput / backspace manipulate its value directly.
  final TextEditingController controller = TextEditingController();

  TimecardResult? result;
  String? toastMessage;

  // ── Input manipulation ────────────────────────────────────────────────────

  void appendToInput(String ch) {
    final TextEditingValue val = controller.value;
    final TextSelection sel   = val.selection;
    final String text         = val.text;

    final int start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final int end   = sel.isValid ? sel.end.clamp(0, text.length)   : text.length;

    final String newText = text.substring(0, start) + ch + text.substring(end);
    controller.value = TextEditingValue(
      text:      newText,
      selection: TextSelection.collapsed(offset: start + ch.length),
    );
    notifyListeners();
  }

  void backspace() {
    final TextEditingValue val = controller.value;
    final TextSelection sel   = val.selection;
    final String text         = val.text;

    final int start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final int end   = sel.isValid ? sel.end.clamp(0, text.length)   : text.length;

    if (start != end) {
      // Selection present — delete the selected range
      controller.value = TextEditingValue(
        text:      text.substring(0, start) + text.substring(end),
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      // No selection — delete one character to the left
      controller.value = TextEditingValue(
        text:      text.substring(0, start - 1) + text.substring(start),
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }
    notifyListeners();
  }

  void clearAll() {
    controller.value = TextEditingValue.empty;
    result       = null;
    toastMessage = null;
    notifyListeners();
  }

  void clearToast() {
    toastMessage = null;
    notifyListeners();
  }

  // ── Conversion entry point ────────────────────────────────────────────────

  void convert() {
    final String raw = controller.text.trim();
    if (raw.isEmpty) {
      toastMessage = 'Please enter a value or expression';
      notifyListeners();
      return;
    }
    toastMessage = null;
    if (raw.contains(':')) {
      _convertElapsedTime(raw);
    } else {
      _convertDecimalHours(raw);
    }
  }

  // ── Elapsed Time ──────────────────────────────────────────────────────────

  void _convertElapsedTime(String raw) {
    // Accept formats: H:MM[AM|PM] [+] decimal  — space before AM/PM optional,
    // separator between AM/PM and duration may be space, +, or space+plus+space.
    final RegExp pattern = RegExp(
      r'^(\d+:\d+(?::\d+)?)\s*(AM|PM)\s*\+?\s*(\d+\.?\d*)$',
      caseSensitive: false,
    );
    final Match? m = pattern.firstMatch(raw.trim());
    if (m == null) {
      toastMessage = 'Elapsed time format: HH:MM AM 0.5  or  HH:MM:SS PM 1.25';
      notifyListeners();
      return;
    }

    final String timePart     = m.group(1)!;
    final String ampmPart     = m.group(2)!.toUpperCase();
    final String durationPart = m.group(3)!;

    final bool isPm = ampmPart == 'PM';

    final List<String> timeParts = timePart.split(':');
    if (timeParts.length < 2 || timeParts.length > 3) {
      toastMessage = 'Time must be HH:MM or HH:MM:SS';
      notifyListeners();
      return;
    }

    final int? startHour = int.tryParse(timeParts[0]);
    final int? startMin  = int.tryParse(timeParts[1]);
    final int? startSec  = timeParts.length == 3 ? int.tryParse(timeParts[2]) : 0;

    if (startHour == null || startMin == null || startSec == null) {
      toastMessage = 'Invalid time value';
      notifyListeners();
      return;
    }

    if (startHour < 1 || startHour > 12 ||
        startMin  < 0 || startMin  > 59 ||
        startSec  < 0 || startSec  > 59) {
      toastMessage = 'Time out of range — hours 1-12, minutes/seconds 0-59';
      notifyListeners();
      return;
    }

    final double? durationHours = double.tryParse(durationPart);
    if (durationHours == null) {
      toastMessage = 'Invalid duration value: $durationPart';
      notifyListeners();
      return;
    }
    if (durationHours < 0) {
      toastMessage = 'Duration must be a positive value';
      notifyListeners();
      return;
    }

    final int hour24            = (startHour % 12) + (isPm ? 12 : 0);
    final int startTotalSeconds = (hour24 * 3600) + (startMin * 60) + startSec;
    final int durationSeconds   = (durationHours * 3600.0).round();
    final int endTotalSeconds   = (startTotalSeconds + durationSeconds) % 86400;

    final int endHour24   = endTotalSeconds ~/ 3600;
    final int endMin      = (endTotalSeconds % 3600) ~/ 60;
    final int endSec      = endTotalSeconds % 60;
    final bool endIsPm    = endHour24 >= 12;
    final int endHour12   = (endHour24 % 12) == 0 ? 12 : (endHour24 % 12);
    final String endAmPm  = endIsPm ? 'PM' : 'AM';

    final String primary = '$endHour12:'
        '${endMin.toString().padLeft(2, '0')}:'
        '${endSec.toString().padLeft(2, '0')} $endAmPm';

    final String startFormatted = '$startHour:'
        '${startMin.toString().padLeft(2, '0')}:'
        '${startSec.toString().padLeft(2, '0')} $ampmPart';

    final String detail = 'Start time:  $startFormatted\n'
        'Duration:    $durationHours decimal hours\n'
        '             (${_formatHMSCompact(durationSeconds)})\n'
        'End time:    $primary';

    result = TimecardResult(primary: primary, detail: detail);
    notifyListeners();
  }

  String _formatHMSCompact(int totalSeconds) {
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  // ── Decimal Hour Arithmetic ───────────────────────────────────────────────

  void _convertDecimalHours(String raw) {
    // Split on operators that appear between digits (lookbehind/lookahead)
    final List<String> tokens    = raw.split(RegExp(r'(?<=\d)\s*[+\-*/]\s*(?=\d)'));
    final List<String> operators = _extractOperators(raw);

    if (tokens.length == 1) {
      final double? value = raw.trim().toDoubleOrNull();
      if (value == null) {
        toastMessage = 'Invalid input — enter a number or expression';
        notifyListeners();
        return;
      }
      _displayResult(value, raw);
      return;
    }

    if (tokens.length > 5) {
      toastMessage = 'Maximum of 5 operands supported';
      notifyListeners();
      return;
    }

    final List<double> operands = [];
    for (final String token in tokens) {
      final double? v = token.trim().toDoubleOrNull();
      if (v == null) {
        toastMessage = 'Invalid value: ${token.trim()}';
        notifyListeners();
        return;
      }
      operands.add(v);
    }

    double acc = operands[0];
    for (int i = 0; i < operators.length; i++) {
      final double operand = operands[i + 1];
      switch (operators[i]) {
        case '+':
          acc += operand;
        case '-':
          if (operand > acc) {
            toastMessage = 'Subtraction error: subtrahend ($operand) is greater than minuend ($acc)';
            notifyListeners();
            return;
          }
          acc -= operand;
        case '*':
          acc *= operand;
        case '/':
          if (operand == 0.0) {
            toastMessage = 'Division error: divisor cannot be zero';
            notifyListeners();
            return;
          }
          acc /= operand;
      }
    }

    if (acc < 0) {
      toastMessage = 'Result is negative — please check your values';
      notifyListeners();
      return;
    }
    _displayResult(acc, raw);
  }

  // Drops the first character (always a digit), then collects every operator char.
  // Mirrors the Kotlin extractOperators implementation exactly.
  List<String> _extractOperators(String expr) {
    return expr.substring(1)
        .split('')
        .where((c) => '+-*/'.contains(c))
        .toList();
  }

  void _displayResult(double decimalHours, String expression) {
    final int totalSeconds = (decimalHours * 3600.0).round();
    final int hours   = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    String primary;
    String detail;

    // Special case: exactly 1.0 → "60 Minutes and 0 Seconds"
    if (hours > 0 && !(hours == 1 && minutes == 0 && seconds == 0)) {
      primary = _formatHMS(hours, minutes, seconds);
      detail  = _buildDetail(hours, minutes, seconds, decimalHours, totalSeconds, expression);
    } else {
      final int displayMinutes = hours * 60 + minutes;
      primary = _formatMS(displayMinutes, seconds);
      detail  = _buildDetail(0, displayMinutes, seconds, decimalHours, totalSeconds, expression);
    }

    result = TimecardResult(primary: primary, detail: detail);
    notifyListeners();
  }

  String _formatMS(int minutes, int seconds) {
    final String minLabel = minutes == 1 ? 'Minute' : 'Minutes';
    final String secLabel = seconds == 1 ? 'Second' : 'Seconds';
    return '$minutes $minLabel\nand $seconds $secLabel';
  }

  String _formatHMS(int hours, int minutes, int seconds) {
    final String hrLabel  = hours   == 1 ? 'Hour'   : 'Hours';
    final String minLabel = minutes == 1 ? 'Minute' : 'Minutes';
    final String secLabel = seconds == 1 ? 'Second' : 'Seconds';
    return '$hours $hrLabel, $minutes $minLabel\nand $seconds $secLabel';
  }

  String _buildDetail(int hours, int minutes, int seconds,
      double decimalHours, int totalSeconds, String expression) {
    final StringBuffer sb = StringBuffer();
    sb.writeln('Expression: $expression');
    sb.writeln('Result: ${decimalHours.toStringAsFixed(6)} decimal hours');
    sb.writeln('Total seconds: $totalSeconds');
    if (hours > 0) {
      sb.write('${hours}h  ${minutes}m  ${seconds}s');
    } else {
      sb.write('${minutes}m  ${seconds}s');
    }
    return sb.toString();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// ── Dart extension: String.toDoubleOrNull() ───────────────────────────────────
extension _StringParsing on String {
  double? toDoubleOrNull() => double.tryParse(this);
}
