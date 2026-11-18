import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/medication.dart';
import '../../../reminder/presentation/bloc/reminder_bloc.dart';
import '../bloc/medication_bloc.dart';
import '../utils/medication_format.dart';
import '../widgets/add_medicine_sheet.dart';
import '../widgets/medication_card.dart';
import '../widgets/medicine_details_sheet.dart';
import '../widgets/medicine_export.dart';

class MedicationsPage extends StatelessWidget {
  const MedicationsPage({super.key});

  Future<void> _refresh(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<MedicationBloc>()
      ..add(const MedicationsRequested());
    final result = await bloc.stream
        .firstWhere((s) => s.status != MedicationStatus.loading);
    // The old list stays on screen, so say why it did not update.
    if (result.status == MedicationStatus.failure) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(result.message ?? 'Could not refresh'.tr),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  /// Asks before a change; true if the user confirmed.
  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(foregroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmDelete(BuildContext context, Medication m) async {
    final bloc = context.read<MedicationBloc>();
    final ok = await _confirm(
      context,
      title: 'Delete medicine?'.tr,
      message: '"{name}", its reminders and its dose history will be '
              'removed. This cannot be undone.\n\n'
              'To keep the history, stop the medicine instead.'
          .trArgs({'name': m.name}),
      action: 'Delete'.tr,
      destructive: true,
    );
    if (ok) bloc.add(MedicationDeleted(m.id));
  }

  Future<void> _toggleStopped(BuildContext context, Medication m) async {
    final bloc = context.read<MedicationBloc>();
    if (m.isStopped) {
      // Resuming is harmless, so no confirmation.
      bloc.add(MedicationStopToggled(id: m.id, stopped: false));
      return;
    }
    final ok = await _confirm(
      context,
      title: 'Stop this medicine?'.tr,
      message: 'You will get no more doses or reminders for "{name}". '
              'Its history is kept and you can resume it any time.'
          .trArgs({'name': m.name}),
      action: 'Stop'.tr,
    );
    if (ok) bloc.add(MedicationStopToggled(id: m.id, stopped: true));
  }

  /// Asks how much was bought and adds it to the stock.
  Future<void> _addStock(BuildContext context, Medication m) async {
    final inventory = m.inventory;
    if (inventory == null) return;
    final bloc = context.read<MedicationBloc>();
    final added = await showDialog<double>(
      context: context,
      builder: (_) => _AddStockDialog(medication: m),
    );
    if (added == null) return;
    bloc.add(MedicationUpdated(
      id: m.id,
      input: m.toInput(
          inventory: inventory.withQuantity(inventory.quantity + added)),
    ));
  }

  void _onActionResult(BuildContext context, MedicationState state) {
    String? text;
    var isError = false;
    if (state.actionStatus == ActionStatus.success) {
      text = switch (state.action) {
        MedicationAction.add => 'Medicine added'.tr,
        MedicationAction.update => 'Medicine updated'.tr,
        MedicationAction.delete => 'Medicine deleted'.tr,
        MedicationAction.stop => 'Medicine stopped'.tr,
        MedicationAction.resume => 'Medicine resumed'.tr,
        MedicationAction.none => null,
      };
    } else if (state.actionStatus == ActionStatus.failure &&
        state.action != MedicationAction.add) {
      // A failed add is shown by the form itself. A failed update may come
      // from the form or from "Add stock" here; the form is on top when it
      // is the source, and shows its own message first.
      text = state.actionMessage ?? 'Something went wrong'.tr;
      isError = true;
    }
    if (text == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicationBloc, MedicationState>(
      listenWhen: (p, c) => p.actionStatus != c.actionStatus,
      listener: _onActionResult,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('My medicines'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              if (state.medications.isNotEmpty)
                IconButton(
                  tooltip: 'Save my medicine list as a PDF'.tr,
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () =>
                      exportMedicines(context, state.medications),
                ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              // Shown while a change from this page (stop, delete, add
              // stock ...) is being saved.
              child: state.isBusy
                  ? LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: AppColors.tertiary,
                    )
                  : const SizedBox(height: 3),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showAddMedicineSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: Text('Add medicine'.tr),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MedicationState state) {
    final items = state.medications;

    if (items.isEmpty) {
      switch (state.status) {
        case MedicationStatus.initial:
        case MedicationStatus.loading:
          return const Center(child: CircularProgressIndicator());
        case MedicationStatus.failure:
          return _Message(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your medicines'.tr,
            subtitle: state.message ?? 'Something went wrong.'.tr,
            actionLabel: 'Try again'.tr,
            onAction: () => context
                .read<MedicationBloc>()
                .add(const MedicationsRequested()),
          );
        case MedicationStatus.success:
          return _Message(
            icon: Icons.medication_outlined,
            title: 'No medicines yet'.tr,
            subtitle:
                'Add your first medicine to start getting reminders on time.'
                    .tr,
            actionLabel: 'Add medicine'.tr,
            onAction: () => showAddMedicineSheet(context),
          );
      }
    }

    final active = items.where((m) => !m.isStopped).toList();
    final stopped = items.where((m) => m.isStopped).toList();

    Widget card(Medication m) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BlocBuilder<ReminderBloc, ReminderState>(
            buildWhen: (p, c) => p.today != c.today,
            builder: (context, reminders) => MedicationCard(
              key: ValueKey(m.id),
              medication: m,
              todayDoses: reminders.today?.doses
                  .where((d) => d.medicationId == m.id)
                  .toList(),
              onOpen: () => showMedicineDetails(context, m.id),
              onEdit: () => context.go(AppRoutes.editMedication(m.id)),
              onDelete: () => _confirmDelete(context, m),
              onToggleStopped: () => _toggleStopped(context, m),
              onRefill: () => _addStock(context, m),
            ),
          ),
        );

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom space keeps the last card clear of the FAB.
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          ...active.map(card),
          if (stopped.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(top: active.isEmpty ? 0 : 8, bottom: 12),
              child: Text(
                'Stopped ({n})'.trArgs({'n': stopped.length}),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ...stopped.map(card),
          ],
        ],
      ),
    );
  }
}

/// Asks how many units were bought; pops with that amount.
class _AddStockDialog extends StatefulWidget {
  final Medication medication;
  const _AddStockDialog({required this.medication});

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(double.parse(_amount.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.medication;
    return AlertDialog(
      backgroundColor: AppColors.scaffold,
      title: Text('Add stock'.tr),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '{name}: {amount} in stock now.'.trArgs({
                'name': m.name,
                'amount': MedicationFormat.amount(m.inventory!.quantity),
              }),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) {
                  return 'Enter how much you added'.tr;
                }
                if (m.inventory!.quantity + n > 100000) return 'Too many'.tr;
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Amount added'.tr,
                hintText: 'e.g. 30'.tr,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'.tr),
        ),
        TextButton(onPressed: _submit, child: Text('Add'.tr)),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.tertiaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
