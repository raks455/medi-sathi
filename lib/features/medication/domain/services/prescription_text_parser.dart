import '../entities/scanned_medicine.dart';

/// Finds medicines in the text lines read from a prescription or label.
///
/// This is pattern matching, not understanding: a line counts as a medicine
/// when it has a form word (Tab, Cap, Syp ...) or a strength (500 mg, 5 ml).
/// Frequency, food timing and duration are read from that line and from the
/// lines right after it. Results are suggestions for the user to review.
class PrescriptionTextParser {
  const PrescriptionTextParser();

  static final _strength = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(mcg|mg|gm|g|ml|iu|units?|%)(?![a-z])',
    caseSensitive: false,
  );

  /// Form words and the API medicine type they mean.
  static final _form = RegExp(
    r'\b(tablets?|tabs?|capsules?|caps?|syrup|syp|syr|suspension|susp|'
    r'injection|inj|cream|ointment|oint|gel|drops?|inhaler|spray|powder|'
    r'sachet|patch|suppository|supp)\b\.?',
    caseSensitive: false,
  );

  static String _typeOf(String formWord) {
    final w = formWord.toLowerCase().replaceAll('.', '');
    if (w.startsWith('tab')) return 'tablet';
    if (w.startsWith('cap')) return 'capsule';
    if (w.startsWith('sy') || w.startsWith('susp')) return 'syrup';
    if (w.startsWith('inj')) return 'injection';
    if (w.startsWith('oint')) return 'ointment';
    if (w.startsWith('drop')) return 'drops';
    if (w.startsWith('supp')) return 'suppository';
    if (w == 'sachet') return 'powder';
    return w; // cream, gel, inhaler, spray, powder, patch
  }

  // Frequency: "1-0-1" style (morning-afternoon-night, optional 4th slot).
  static final _slots = RegExp(
      r'(?<![\d-])([0-3½])\s*[-+–]\s*([0-3½])\s*[-+–]\s*([0-3½])'
      r'(?:\s*[-+–]\s*([0-3½]))?(?![\d-])');
  static const _threeSlotTimes = ['08:00', '14:00', '20:00'];
  static const _fourSlotTimes = ['08:00', '13:00', '18:00', '22:00'];

  // Frequency words, checked in this order (text is lower-case, dots removed).
  static final _frequencies = <(RegExp, List<String>)>[
    (RegExp(r'\b(qid|qds|four times|4 times)\b'),
        ['08:00', '12:00', '16:00', '20:00']),
    (RegExp(r'\b(tds|tid|thrice|three times|3 times)\b'),
        ['08:00', '14:00', '20:00']),
    (RegExp(r'\b(bd|bid|twice|two times|2 times)\b'), ['08:00', '20:00']),
    (RegExp(r'\b(hs|at bed ?time|at night)\b'), ['21:00']),
    (RegExp(r'\b(od|qd|once|daily)\b'), ['08:00']),
  ];
  static final _asNeeded = RegExp(r'\b(sos|prn|as needed|when required)\b');

  static final _timings = <(RegExp, String)>[
    (RegExp(r'\b(before (food|meals?)|ac)\b'), 'before_food'),
    (RegExp(r'\b(after (food|meals?)|pc)\b'), 'after_food'),
    (RegExp(r'\bwith (food|meals?)\b'), 'with_food'),
    (RegExp(r'\bempty stomach\b'), 'empty_stomach'),
    (RegExp(r'\b(bed ?time|before sleep)\b'), 'before_sleep'),
  ];

  static final _duration =
      RegExp(r'(?:\bx|\bfor|[×*])\s*(\d{1,3})\s*(days?|weeks?)\b');

  /// How many following lines may add details to a medicine line.
  static const _lookahead = 2;

  List<ScannedMedicine> parse(List<String> lines) {
    final clean =
        lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final result = <ScannedMedicine>[];

    for (var i = 0; i < clean.length; i++) {
      final line = clean[i];
      if (!_isMedicineLine(line)) continue;
      final name = _nameOf(line);
      if (name == null) continue;

      // Details may continue on the next lines, until another medicine starts.
      final source = [line];
      for (var j = i + 1; j < clean.length && j <= i + _lookahead; j++) {
        if (_isMedicineLine(clean[j])) break;
        source.add(clean[j]);
      }
      final details = source.join(' ').toLowerCase().replaceAll('.', '');

      final form = _form.firstMatch(line);
      final strength = _strength.firstMatch(line);
      final asNeeded = _asNeeded.hasMatch(details);
      result.add(ScannedMedicine(
        name: name,
        medicineType: form == null ? null : _typeOf(form.group(1)!),
        dose: strength == null
            ? null
            : '${strength.group(1)!.replaceAll(',', '.')} '
                '${strength.group(2)!.toLowerCase()}',
        intakeTiming: _timingOf(details),
        reminderTimes: asNeeded ? const [] : _timesOf(details),
        asNeeded: asNeeded,
        durationDays: _durationOf(details),
        sourceText: source.join('\n'),
      ));
    }
    return result;
  }

  static bool _isMedicineLine(String line) =>
      _form.hasMatch(line) || _strength.hasMatch(line);

  /// The medicine name: the text before the strength, without the form word,
  /// list numbering or frequency codes. Null if nothing name-like is left.
  static String? _nameOf(String line) {
    final strength = _strength.firstMatch(line);
    var text = strength == null ? line : line.substring(0, strength.start);
    // Strength first ("500 mg Paracetamol"): use what follows it instead.
    if (strength != null && !RegExp(r'[A-Za-z]{3,}').hasMatch(text)) {
      text = line.substring(strength.end);
    }
    text = text
        .replaceAll(_form, ' ')
        .replaceAll(_slots, ' ')
        .replaceFirst(RegExp(r'^\s*(rx\b|\d{1,2}\s*[.)]|[-•*#])+\s*',
            caseSensitive: false), '')
        // Keep the first run of name-like words.
        .replaceAll(RegExp(r"[^A-Za-z0-9\s'+-]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (!RegExp(r'[A-Za-z]{3,}').hasMatch(text)) return null;
    return text
        .split(' ')
        .map((w) => w.length > 1 && w == w.toUpperCase()
            ? w[0] + w.substring(1).toLowerCase() // PARACETAMOL -> Paracetamol
            : w)
        .join(' ');
  }

  static List<String> _timesOf(String details) {
    final slots = _slots.firstMatch(details);
    if (slots != null) {
      final four = slots.group(4) != null;
      final names = four ? _fourSlotTimes : _threeSlotTimes;
      return [
        for (var k = 0; k < names.length; k++)
          if (slots.group(k + 1) != '0') names[k],
      ];
    }
    for (final (pattern, times) in _frequencies) {
      if (pattern.hasMatch(details)) return times;
    }
    return const [];
  }

  static String? _timingOf(String details) {
    for (final (pattern, timing) in _timings) {
      if (pattern.hasMatch(details)) return timing;
    }
    return null;
  }

  static int? _durationOf(String details) {
    final m = _duration.firstMatch(details);
    if (m == null) return null;
    final n = int.parse(m.group(1)!);
    final days = m.group(2)!.startsWith('week') ? n * 7 : n;
    return days >= 1 && days <= 365 ? days : null;
  }
}
