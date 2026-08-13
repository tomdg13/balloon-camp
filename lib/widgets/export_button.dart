import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../utils/web_downloader.dart';

class ExportButton extends StatelessWidget {
  final Dio dio;
  final String from;
  final String to;
  const ExportButton({
    super.key,
    required this.dio,
    required this.from,
    required this.to,
  });

  Future<void> _export(BuildContext context) async {
    try {
      final response = await dio.get(
        '/api/reports/export',
        queryParameters: {'from': from, 'to': to},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data as List<int>;
      final filename = 'report_${from}_to_$to.csv';
      if (kIsWeb) {
        downloadCsv(bytes, filename);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export is only supported on web for now')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _export(context),
      icon: const Icon(Icons.download, size: 18),
      label: const Text('Export CSV'),
    );
  }
}
