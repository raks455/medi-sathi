import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../domain/health_record.dart';
import '../cubit/health_records_cubit.dart';
import '../widgets/record_opener.dart';
import '../widgets/record_sheets.dart';

/// A personal drive with two folders: Prescriptions and Health records
/// (lab reports, scans and other documents).
class HealthRecordsPage extends StatefulWidget {
  /// Which folder to show first.
  final RecordFolder initialFolder;
  const HealthRecordsPage(
      {super.key, this.initialFolder = RecordFolder.prescriptions});

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialFolder.index,
  )..addListener(() => setState(() {}));

  RecordFolder get _folder => RecordFolder.values[_tabs.index];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final cubit = context.read<HealthRecordsCubit>();
    final folder = _folder;
    final file = await pickRecordFile(context);
    if (file == null || !mounted) return;

    final dot = file.name.lastIndexOf('.');
    final suggested = folder == RecordFolder.prescriptions
        ? 'Prescription ${DateFormat.yMMMd().format(DateTime.now())}'
        : (dot > 0 ? file.name.substring(0, dot) : file.name);
    final details = await showRecordDetailsSheet(context,
        folder: folder, suggestedTitle: suggested, actionLabel: 'Upload');
    if (details == null || !mounted) return;

    final error = await cubit.upload(
      file: file,
      folder: folder,
      category: details.category,
      title: details.title,
      notes: details.notes,
      documentDate: details.documentDate,
    );
    if (!mounted) return;
    showInfoSnack(context, error ?? 'Saved to ${_folderName(folder)}',
        error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Prescriptions'),
            Tab(icon: Icon(Icons.folder_shared_outlined), text: 'Health records'),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<HealthRecordsCubit, HealthRecordsState>(
        buildWhen: (p, c) => p.uploading != c.uploading,
        builder: (context, state) => FloatingActionButton.extended(
          onPressed: state.uploading ? null : _upload,
          icon: state.uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : const Icon(Icons.upload_file_rounded),
          label: Text(state.uploading ? 'Uploading…' : 'Upload'),
        ),
      ),
      body: BlocBuilder<HealthRecordsCubit, HealthRecordsState>(
        builder: (context, state) {
          if (state.status == RecordsStatus.loading && state.records.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == RecordsStatus.failure && state.records.isEmpty) {
            return _Message(
              icon: Icons.cloud_off_rounded,
              text: state.message ?? 'Could not load your records',
              action: TextButton(
                onPressed: context.read<HealthRecordsCubit>().load,
                child: const Text('Try again'),
              ),
            );
          }
          return TabBarView(
            controller: _tabs,
            children: [
              for (final folder in RecordFolder.values)
                _FolderView(folder: folder, state: state),
            ],
          );
        },
      ),
    );
  }
}

String _folderName(RecordFolder f) =>
    f == RecordFolder.prescriptions ? 'Prescriptions' : 'Health records';

class _FolderView extends StatefulWidget {
  final RecordFolder folder;
  final HealthRecordsState state;
  const _FolderView({required this.folder, required this.state});

  @override
  State<_FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<_FolderView>
    with AutomaticKeepAliveClientMixin {
  RecordCategory? _filter;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final all = widget.state.inFolder(widget.folder);
    final records =
        _filter == null ? all : all.where((r) => r.category == _filter).toList();
    final isDocs = widget.folder == RecordFolder.healthRecords;
    final usage = widget.state.usage;

    return RefreshIndicator(
      onRefresh: context.read<HealthRecordsCubit>().load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (usage != null) _UsageBar(usage: usage),
          if (isDocs && all.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip(null, 'All'),
                  for (final c in RecordCategory.documentTypes)
                    if (all.any((r) => r.category == c))
                      _filterChip(c, c.label),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (records.isEmpty)
            _Message(
              icon: isDocs
                  ? Icons.folder_open_rounded
                  : Icons.receipt_long_rounded,
              text: isDocs
                  ? 'Keep lab reports, scan reports, discharge summaries and '
                      'other documents here.'
                  : 'Keep your prescriptions here. Upload a photo or PDF, or '
                      'save one after scanning it in the Medicine tab.',
            )
          else
            for (final r in records)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecordTile(record: r),
              ),
        ],
      ),
    );
  }

  Widget _filterChip(RecordCategory? c, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == c,
          showCheckmark: false,
          onSelected: (_) => setState(() => _filter = c),
        ),
      );
}

class _UsageBar extends StatelessWidget {
  final StorageUsage usage;
  const _UsageBar({required this.usage});

  @override
  Widget build(BuildContext context) {
    final nearlyFull = usage.fraction > 0.9;
    return Row(
      children: [
        Icon(Icons.cloud_outlined, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usage.fraction.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.tertiary,
              color: nearlyFull ? AppColors.error : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${formatBytes(usage.usedBytes)} of ${formatBytes(usage.quotaBytes)}',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final HealthRecord record;
  const _RecordTile({required this.record});

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<HealthRecordsCubit>();
    final details = await showRecordDetailsSheet(context,
        folder: record.folder, existing: record);
    if (details == null) return;
    final error = await cubit.updateDetails(record,
        title: details.title,
        category: details.category,
        notes: details.notes,
        documentDate: details.documentDate);
    if (error != null && context.mounted) {
      showInfoSnack(context, error, error: true);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<HealthRecordsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete this file?'),
        content: Text('"${record.title}" will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await cubit.delete(record);
    if (context.mounted) {
      showInfoSnack(context, error ?? 'Deleted', error: error != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = record;
    final subtitle = [
      if (r.folder == RecordFolder.healthRecords) r.category.label,
      DateFormat.yMMMd().format(r.displayDate),
      formatBytes(r.sizeBytes),
    ].join(' · ');
    final accent = r.isPdf ? AppColors.error : AppColors.primary;

    return InfoCard(children: [
      ListTile(
        onTap: () => openRecord(
            context, context.read<HealthRecordsCubit>().repository, r),
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            r.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
            color: accent,
          ),
        ),
        title: Text(r.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        subtitle: Text(
          r.notes == null ? subtitle : '$subtitle\n${r.notes}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (v) => v == 'edit' ? _edit(context) : _delete(context),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit details')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    ]);
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 56, color: AppColors.secondary),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.45, color: AppColors.textSecondary)),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}
