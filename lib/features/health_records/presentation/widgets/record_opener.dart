import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/widgets/info_widgets.dart';
import '../../domain/health_record.dart';
import '../../domain/health_records_repository.dart';

/// Downloads a record if needed, then shows an image in the app or opens a
/// PDF in the phone's PDF viewer.
Future<void> openRecord(BuildContext context, HealthRecordsRepository repo,
    HealthRecord record) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var closed = false;
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  ).then((_) => closed = true);

  final result = await repo.fileOnDevice(record);
  if (!closed) navigator.pop();
  if (!context.mounted) return;

  await result.fold(
    (f) async => showInfoSnack(context, f.message, error: true),
    (path) async {
      if (record.isImage && !path.toLowerCase().endsWith('.heic')) {
        await navigator.push(MaterialPageRoute(
          builder: (_) => _ImageViewer(title: record.title, path: path),
        ));
        return;
      }
      final opened = await OpenFilex.open(path);
      if (opened.type != ResultType.done && context.mounted) {
        showInfoSnack(context, 'No app found to open this file.', error: true);
      }
    },
  );
}

class _ImageViewer extends StatelessWidget {
  final String title;
  final String path;
  const _ImageViewer({required this.title, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Open in another app',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => OpenFilex.open(path),
          ),
        ],
      ),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(child: Image.file(File(path))),
      ),
    );
  }
}
