#!/usr/bin/env bash
# MediSathi - unified "Add medicine" flow: Manual entry OR Scan prescription
# Run from the PROJECT ROOT (folder with pubspec.yaml):
#   bash add_medication_entry_methods.sh
set -e

[ -f pubspec.yaml ] || { echo "Run this inside the medisathi project folder."; exit 1; }

L=lib
M=$L/features/medications

mkdir -p $M/domain/entities $M/presentation/{bloc,pages,widgets}

# replace the earlier bottom-sheet idea with a proper chooser page
rm -f $M/presentation/widgets/add_medication_method_sheet.dart

# ---------- domain: remember how each medicine was added ----------
cat > $M/domain/entities/medication_source.dart <<'EOF'
/// How a medication entered the app.
enum MedicationSource { manual, scanned }
EOF

# ---------- presentation ----------
touch $M/presentation/pages/add_medication_page.dart      # chooser: [Scan prescription] [Enter manually]
touch $M/presentation/pages/manual_entry_page.dart        # blank form -> save
touch $M/presentation/widgets/entry_method_card.dart      # big tappable card used on the chooser
touch $M/presentation/widgets/medication_form.dart        # SHARED form (name, dosage, times, days, start/end, pills)
touch $M/presentation/bloc/medication_form_{bloc,event,state}.dart  # validation + submit, used by both paths

# ---------- routes ----------
cat > $L/core/router/app_routes.dart <<'EOF'
class AppRoutes {
  static const home = '/';
  static const medications = '/medications';

  // Add medicine: one entry point, two paths
  static const addMedication = '/medications/add';          // chooser
  static const addManual = '/medications/add/manual';       // path 1
  static const scanPrescription = '/medications/add/scan';  // path 2: camera -> OCR
  static const scanReview = '/medications/add/scan/review'; // edit scanned results -> save
}
EOF

# ---------- flow notes for the team ----------
cat > $M/ADD_FLOW.md <<'EOF'
# Add medicine flow

AddMedicationPage (chooser)
 ├─ Enter manually   -> ManualEntryPage -> MedicationForm (empty)  ─┐
 └─ Scan prescription -> ScanPrescriptionPage -> OCR + parse        │
                          -> ScanReviewPage -> MedicationForm       ├─> MedicationFormBloc
                             (prefilled, one per scanned medicine) ─┘     -> AddMedication usecase
                                                                          -> schedule reminders
                                                                          -> init refill count

Rules
- Both paths end in the SAME MedicationForm and the SAME AddMedication use case.
- Scanned items are never saved without the user confirming them in the form.
- Save with source = MedicationSource.manual or .scanned.
- The scan path may produce several medicines; the review page steps through each one.
EOF

echo "Unified add-medicine flow created."