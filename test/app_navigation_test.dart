import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:medisathi/core/error/failures.dart';
import 'package:medisathi/core/router/app_router.dart';
import 'package:medisathi/core/router/app_routes.dart';
import 'package:medisathi/core/theme/app_theme.dart';
import 'package:medisathi/features/auth/domain/entities/user.dart';
import 'package:medisathi/features/auth/domain/repositories/auth_repository.dart';
import 'package:medisathi/features/auth/domain/usecases/get_current_user.dart';
import 'package:medisathi/features/auth/domain/usecases/sign_in.dart';
import 'package:medisathi/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:medisathi/features/auth/domain/usecases/sign_out.dart';
import 'package:medisathi/features/auth/domain/usecases/sign_up.dart';
import 'package:medisathi/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:medisathi/features/medication/domain/entities/medication.dart';
import 'package:medisathi/features/medication/domain/entities/scanned_medicine.dart';
import 'package:medisathi/features/medication/domain/repositories/medication_repository.dart';
import 'package:medisathi/features/medication/domain/repositories/prescription_scan_repository.dart';
import 'package:medisathi/features/medication/domain/usecases/add_medication.dart';
import 'package:medisathi/features/medication/domain/usecases/delete_medication.dart';
import 'package:medisathi/features/medication/domain/usecases/get_medication_options.dart';
import 'package:medisathi/features/medication/domain/usecases/get_medications.dart';
import 'package:medisathi/features/medication/domain/usecases/scan_prescription.dart';
import 'package:medisathi/features/medication/domain/usecases/set_medication_stopped.dart';
import 'package:medisathi/features/medication/domain/usecases/update_medication.dart';
import 'package:medisathi/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:medisathi/features/medication/presentation/bloc/prescription_scan_bloc.dart';
import 'package:medisathi/features/notification/data/services/push_notification_service.dart';
import 'package:medisathi/features/notification/domain/entities/app_notification.dart';
import 'package:medisathi/features/notification/domain/repositories/notification_repository.dart';
import 'package:medisathi/features/notification/domain/usecases/notification_usecases.dart';
import 'package:medisathi/features/notification/presentation/bloc/notifications_bloc.dart';
import 'package:medisathi/features/reminder/domain/entities/dose.dart';
import 'package:medisathi/features/reminder/domain/repositories/reminder_repository.dart';
import 'package:medisathi/features/reminder/domain/usecases/get_dose_schedule.dart';
import 'package:medisathi/features/reminder/domain/usecases/get_today_doses.dart';
import 'package:medisathi/features/reminder/domain/usecases/log_dose.dart';
import 'package:medisathi/features/reminder/presentation/bloc/dose_history_bloc.dart';
import 'package:medisathi/features/reminder/presentation/bloc/reminder_bloc.dart';

// ---- in-memory fakes for everything behind the blocs ----

class _FakeAuthRepository implements AuthRepository {
  bool signedOut = false;

  @override
  Future<Either<Failure, User?>> getCurrentUser() async => const Right(
      User(id: 'u1', email: 'test@example.com', fullName: 'Test User'));

  @override
  Future<Either<Failure, Unit>> signOut() async {
    signedOut = true;
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMedicationRepository implements MedicationRepository {
  final items = <Medication>[
    const Medication(
      id: 'm1',
      name: 'Paracetamol',
      medicineType: 'tablet',
      dose: '500 mg',
      intakeTiming: 'after_food',
      inventory: MedicationInventory(
        quantity: 4,
        dosesLeft: 4,
        daysLeft: 2,
        lowStock: true,
      ),
    ),
  ];

  @override
  Future<Either<Failure, Medication>> setStopped(String id,
      {required bool stopped}) async {
    final i = items.indexWhere((m) => m.id == id);
    final m = items[i];
    items[i] = Medication(
      id: m.id,
      name: m.name,
      medicineType: m.medicineType,
      dose: m.dose,
      intakeTiming: m.intakeTiming,
      schedule: m.schedule,
      inventory: m.inventory,
      isStopped: stopped,
    );
    return Right(items[i]);
  }

  @override
  Future<Either<Failure, Medication>> updateMedication(
      String id, MedicationInput input) async {
    final i = items.indexWhere((m) => m.id == id);
    items[i] = Medication(
      id: id,
      name: input.name,
      medicineType: input.medicineType,
      dose: input.dose,
      intakeTiming: input.intakeTiming,
      schedule: input.schedule,
      inventory: input.inventory,
    );
    return Right(items[i]);
  }

  @override
  Future<Either<Failure, List<Medication>>> getMedications() async =>
      Right([...items]);

  @override
  Future<Either<Failure, MedicationOptions>> getOptions() async =>
      const Right(MedicationOptions.fallback);

  @override
  Future<Either<Failure, Medication>> addMedication(
      MedicationInput input) async {
    final created = Medication(
      id: 'm${items.length + 1}',
      name: input.name,
      medicineType: input.medicineType,
      dose: input.dose,
      intakeTiming: input.intakeTiming,
      instructions: input.instructions,
      schedule: input.schedule,
      inventory: input.inventory,
    );
    items.insert(0, created);
    return Right(created);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReminderRepository implements ReminderRepository {
  static final _dose = ScheduledDose(
    doseKey: 'm1:1',
    medicationId: 'm1',
    medicationName: 'Paracetamol',
    medicineType: 'tablet',
    dose: '500 mg',
    intakeTiming: 'after_food',
    scheduledFor: DateTime.utc(2026, 11, 17, 2, 15),
    localDate: '2026-11-17',
    localTime: '08:00',
    status: DoseStatus.due,
  );
  static final _schedule = DoseSchedule(
    summary: AdherenceSummary.fromDoses([_dose]),
    doses: [_dose],
  );

  @override
  Future<Either<Failure, DoseSchedule>> getToday() async => Right(_schedule);

  @override
  Future<Either<Failure, DoseSchedule>> getSchedule(
          DateTime startDate, DateTime endDate) async =>
      Right(_schedule);

  @override
  Future<Either<Failure, ScheduledDose>> logDose(
          ScheduledDose dose, DoseStatus status) async =>
      Right(dose.withStatus(status, DateTime.utc(2026, 11, 17, 3)));
}

class _FakeScanRepository implements PrescriptionScanRepository {
  @override
  Future<Either<Failure, List<ScannedMedicine>?>> scan(
          ScanSource source) async =>
      const Right([
        ScannedMedicine(
          name: 'Amoxicillin',
          medicineType: 'capsule',
          dose: '250 mg',
          intakeTiming: 'after_food',
          asNeeded: true,
          sourceText: 'Cap Amoxicillin 250mg SOS after food',
        ),
      ]);
}

class _FakeNotificationRepository implements NotificationRepository {
  var items = [
    AppNotification(
      id: 'n1',
      type: AppNotification.typeRefillReminder,
      title: 'Refill Paracetamol soon',
      body: '4 left - it runs out in 2 days.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      type: AppNotification.typeDoseReminder,
      title: 'Time to take Paracetamol',
      body: '500 mg (tablet) - after food',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ),
  ];

  @override
  Future<Either<Failure, NotificationPage>> getNotifications(
          {required int limit, required int offset}) async =>
      Right(NotificationPage(
        items: items,
        unreadCount: items.where((n) => !n.isRead).length,
        hasMore: false,
      ));

  @override
  Future<Either<Failure, Unit>> markRead(String id) async {
    items = [for (final n in items) n.id == id ? n.asRead() : n];
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() async {
    items = [for (final n in items) n.asRead()];
    return const Right(unit);
  }
}

class _FakePushService implements PushNotificationService {
  @override
  Stream<void> get onReminder => const Stream.empty();
  @override
  Future<void> registerDevice() async {}
  @override
  Future<void> unregisterDevice() async {}
  @override
  Future<Either<Failure, int>> sendTestPush() async => const Right(1);
}

void main() {
  final sl = GetIt.instance;
  late _FakeAuthRepository auth;

  setUp(() async {
    await sl.reset();
    auth = _FakeAuthRepository();
    final meds = _FakeMedicationRepository();
    final reminders = _FakeReminderRepository();

    sl.registerFactory(() => AuthBloc(
          signIn: SignIn(auth),
          signUp: SignUp(auth),
          signInWithGoogle: SignInWithGoogle(auth),
          signOut: SignOut(auth),
          getCurrentUser: GetCurrentUser(auth),
        ));
    sl.registerFactory(() => MedicationBloc(
          getMedications: GetMedications(meds),
          getOptions: GetMedicationOptions(meds),
          addMedication: AddMedication(meds),
          updateMedication: UpdateMedication(meds),
          deleteMedication: DeleteMedication(meds),
          setMedicationStopped: SetMedicationStopped(meds),
        ));
    final notifications = _FakeNotificationRepository();
    sl.registerFactory(() => NotificationsBloc(
          getNotifications: GetNotifications(notifications),
          markNotificationRead: MarkNotificationRead(notifications),
          markAllNotificationsRead: MarkAllNotificationsRead(notifications),
        ));
    sl.registerFactory(() => ReminderBloc(
          getTodayDoses: GetTodayDoses(reminders),
          logDose: LogDose(reminders),
        ));
    sl.registerFactory(
        () => DoseHistoryBloc(getDoseSchedule: GetDoseSchedule(reminders)));
    sl.registerFactory(() => PrescriptionScanBloc(
        scanPrescription: ScanPrescription(_FakeScanRepository())));
    sl.registerLazySingleton<PushNotificationService>(_FakePushService.new);
  });

  testWidgets('tabs, adding a medicine manually and by scanning, sign out',
      (tester) async {
    // A tall phone-like screen so forms fit without scrolling.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = AppRouter.create(initialLocation: AppRoutes.home);
    await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    await tester.pumpAndSettle();

    String location() => router.routerDelegate.currentConfiguration.uri.path;
    Future<void> tapText(String text) async {
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    // ---- Dashboard: today's dose can be marked taken ----
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Good (morning|afternoon|evening), Test User$')),
        findsOneWidget);
    // One medicine, and it is low on stock.
    expect(find.text('Medicine'), findsWidgets);
    expect(find.text('To refill soon'), findsOneWidget);
    expect(find.text('Refill soon'), findsOneWidget);
    expect(find.text('4 left · lasts 2 days'), findsOneWidget);
    expect(find.text('Due now'), findsOneWidget);

    // ---- Notifications: bell badge, list, mark all read ----
    expect(find.descendant(of: find.byType(Badge), matching: find.text('2')),
        findsOneWidget);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.notifications);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Refill Paracetamol soon'), findsOneWidget);
    expect(find.text('Time to take Paracetamol'), findsOneWidget);
    await tapText('Refill Paracetamol soon'); // marks that one read
    await tapText('Mark all read');
    expect(find.text('Mark all read'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.home);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('2')),
        findsNothing);

    await tapText('Take');
    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('1 of 1 doses taken'), findsOneWidget);

    // ---- Medicine tab: add manually ----
    await tapText('Medicine');
    expect(location(), AppRoutes.medications);
    expect(find.text('My medicines'), findsOneWidget);
    expect(find.text('Paracetamol'), findsWidgets);
    expect(find.text('4 left · lasts 2 days · Refill soon'), findsOneWidget);

    // Add stock: 4 + 26 = 30.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tapText('Add stock');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount added'), '26');
    await tapText('Add');
    expect(find.text('30 left'), findsOneWidget);

    // Stop, then resume.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tapText('Stop medicine');
    await tapText('Stop'); // confirm
    expect(find.text('Stopped (1)'), findsOneWidget);
    expect(find.text('Stopped · no doses or reminders'), findsOneWidget);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tapText('Resume medicine');
    expect(find.text('Stopped (1)'), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText('Enter manually');
    expect(location(), AppRoutes.addManual);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Medicine name'), 'Cetirizine');
    await tester.enterText(find.widgetWithText(TextFormField, 'Dose'), '10 mg');
    await tapText('Type');
    await tapText('Tablet');
    await tapText('Before sleep');
    await tapText('Alarm'); // alert style
    await tapText('Take on a schedule'); // off: as needed
    await tapText('Track my stock');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'In stock now'), '12');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add medicine'));
    await tester.pumpAndSettle();

    expect(location(), AppRoutes.medications);
    expect(find.text('Cetirizine'), findsOneWidget);
    expect(find.text('12 left'), findsOneWidget);
    expect(find.text('Medicine added'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // ---- Medicine tab: add by scanning ----
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText('Scan prescription or label');
    expect(location(), AppRoutes.scanPrescription);
    await tapText('Take a photo');
    expect(find.text('Found 1 medicine'), findsOneWidget);

    await tapText('Review & add');
    // The form opens filled in from the scan.
    expect(find.widgetWithText(TextFormField, 'Amoxicillin'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '250 mg'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add medicine'));
    await tester.pumpAndSettle();
    expect(find.text('Added'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.medications);
    expect(find.text('Amoxicillin'), findsOneWidget);

    // ---- History and Profile tabs ----
    await tapText('History');
    expect(location(), AppRoutes.history);
    expect(find.text('Last 7 days'), findsWidgets);

    await tapText('Profile');
    expect(location(), AppRoutes.profile);
    expect(find.text('test@example.com'), findsOneWidget);

    // Back to the dashboard and it still shows the marked dose.
    await tapText('Dashboard');
    expect(location(), AppRoutes.home);

    // ---- Sign out from Profile ----
    await tapText('Profile');
    await tapText('Sign out');
    await tapText('Sign out'); // confirm in the dialog
    expect(auth.signedOut, isTrue);
    expect(location(), AppRoutes.signIn);
  });
}
