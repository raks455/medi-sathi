import 'package:flutter_test/flutter_test.dart';
import 'package:medisathi/features/medication/domain/services/prescription_text_parser.dart';

void main() {
  const parser = PrescriptionTextParser();

  test('reads a typical prescription', () {
    final meds = parser.parse([
      'Dr. Sharma Clinic',
      'Patient: Ram Bahadur   Age: 45',
      'Rx',
      '1. Tab. PARACETAMOL 500 mg  1-0-1',
      'after food x 5 days',
      '2) Cap Amoxicillin 250mg TDS for 1 week',
      'Syp. Cetirizine 5 ml HS',
      'Tab Pantoprazole 40 mg OD before food',
      'Inj. Diclofenac 75 mg SOS',
      'Review after 7 days',
    ]);

    expect(meds.map((m) => m.name), [
      'Paracetamol',
      'Amoxicillin',
      'Cetirizine',
      'Pantoprazole',
      'Diclofenac',
    ]);

    final para = meds[0];
    expect(para.medicineType, 'tablet');
    expect(para.dose, '500 mg');
    expect(para.reminderTimes, ['08:00', '20:00']);
    expect(para.intakeTiming, 'after_food');
    expect(para.durationDays, 5);

    final amox = meds[1];
    expect(amox.medicineType, 'capsule');
    expect(amox.dose, '250 mg');
    expect(amox.reminderTimes, ['08:00', '14:00', '20:00']);
    expect(amox.durationDays, 7);

    expect(meds[2].medicineType, 'syrup');
    expect(meds[2].dose, '5 ml');
    expect(meds[2].reminderTimes, ['21:00']);

    expect(meds[3].reminderTimes, ['08:00']);
    expect(meds[3].intakeTiming, 'before_food');

    expect(meds[4].medicineType, 'injection');
    expect(meds[4].asNeeded, isTrue);
    expect(meds[4].reminderTimes, isEmpty);
  });

  test('leaves unknown details empty', () {
    final meds = parser.parse(['Metformin 500 mg']);
    expect(meds, hasLength(1));
    expect(meds.single.name, 'Metformin');
    expect(meds.single.medicineType, isNull);
    expect(meds.single.intakeTiming, isNull);
    expect(meds.single.reminderTimes, isEmpty);
    expect(meds.single.asNeeded, isFalse);
  });

  test('ignores text without medicines', () {
    expect(parser.parse(['City Hospital', 'Date: 12/11/2026', '']), isEmpty);
  });
}
