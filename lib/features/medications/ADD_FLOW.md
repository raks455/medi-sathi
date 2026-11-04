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
