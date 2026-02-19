import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../core/services/export_service.dart';
import 'icloud_backup_screen.dart';

class DataSettingsScreen extends ConsumerStatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  ConsumerState<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends ConsumerState<DataSettingsScreen> {
  bool _isExporting = false;

  Future<void> _handleExport(Future<void> Function() exportFn, String label) async {
    if (_isExporting) return;
    
    setState(() => _isExporting = true);
    try {
      await exportFn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting $label: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Data', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── Export section ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_download, color: Colors.blue),
                      title: const Text('Export as CSV',
                          style: TextStyle(color: Colors.white)),
                      onTap: () => _handleExport(() => ExportService().exportToCSV(), 'CSV'),
                    ),
                    const Divider(
                        height: 1, color: Color(0xFF2C2C2E), indent: 56),
                    ListTile(
                      leading:
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: const Text('Export as PDF',
                          style: TextStyle(color: Colors.white)),
                      onTap: () => _handleExport(() => ExportService().exportToPDF(), 'PDF'),
                    ),
                  ],
                ),
              ),

              // ── Delete all ─────────────────────────────────────────────────
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete All Data',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This action cannot be undone. All your subscriptions and settings will be permanently deleted.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (_isExporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title:
            const Text('Delete All Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete all your data? This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              await HiveService.subscriptionBox.clear();
              await HiveService.listsBox.clear();
              await HiveService.categoriesBox.clear();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data deleted successfully')),
                );
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
