import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/theme.dart';
import '../data/service_repository.dart';
import '../application/statement_parser_service.dart';
import '../../../../core/presentation/widgets/bounceable.dart';

class SubscriptionSelectionScreen extends ConsumerStatefulWidget {
  const SubscriptionSelectionScreen({super.key});

  @override
  ConsumerState<SubscriptionSelectionScreen> createState() => _SubscriptionSelectionScreenState();
}

class _SubscriptionSelectionScreenState extends ConsumerState<SubscriptionSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _handleClose() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    final filteredServices = repository.searchServices(_searchQuery);

    return WillPopScope(
      onWillPop: () async {
        _handleClose();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: TextButton(
            onPressed: _handleClose,
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          leadingWidth: 80,
          title: const Text('Add Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: [
                  const SizedBox(height: 20),
                  _buildOptionTile(
                    icon: Icons.photo_library,
                    color: Colors.purpleAccent,
                    title: 'Import from photos',
                    subtitle: 'Receipt, bill or renewal screenshots',
                    isLocked: false,
                    onTap: _scanDocument,
                  ),
                  _buildOptionTile(
                    icon: Icons.description,
                    color: Colors.deepPurpleAccent,
                    title: 'Import a file',
                    subtitle: 'Bank statement or spreadsheet (PDF or CSV)',
                    isLocked: false,
                    onTap: _importFile,
                  ),
                  const Divider(height: 30, color: Colors.white10),
                  _buildOptionTile(
                    icon: Icons.add,
                    color: Colors.deepPurple,
                    title: 'Custom subscription',
                    subtitle: null,
                    onTap: () {
                      context.push('/add_subscription?t=${DateTime.now().millisecondsSinceEpoch}');
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'STREAMING',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...filteredServices.map((service) => Bounceable(
                    onTap: () {
                      context.push(
                        '/add_subscription?t=${DateTime.now().millisecondsSinceEpoch}', 
                        extra: {
                          'name': service.name,
                          'iconCodePoint': service.iconCodePoint,
                          'colorValue': service.colorValue,
                        },
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: service.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(service.icon, color: service.color, size: 24),
                        ),
                        title: Text(service.name, style: AppTheme.subscriptionRowTitle),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    ),
                  )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFile() async {
    try {
      // Show loading
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Processing file...'), duration: Duration(seconds: 1))
         );
      }

      final results = await ref.read(statementParserServiceProvider).pickAndParseFile();

      if (mounted) {
        if (results.isNotEmpty) {
           context.push('/detected_subscriptions', extra: results);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('No recurring subscriptions found.'))
           );
        }
      }
    } catch (e) {
      debugPrint('Error importing file: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Import failed: $e'))
         );
      }
    }
  }

  Future<void> _scanDocument() async {
    try {
      if (Platform.isIOS) {
        // Fallback for iOS since google_mlkit_document_scanner is Android-only
        final ImagePicker picker = ImagePicker();
        final XFile? image = await showModalBottomSheet<XFile?>(
          context: context,
          backgroundColor: const Color(0xFF1C1C1E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Colors.white),
                    title: const Text('Take a photo', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      final file = await picker.pickImage(source: ImageSource.camera);
                      if (context.mounted) Navigator.pop(context, file);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: Colors.white),
                    title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
                    onTap: () async {
                      final file = await picker.pickImage(source: ImageSource.gallery);
                      if (context.mounted) Navigator.pop(context, file);
                    },
                  ),
                ],
              ),
            );
          },
        );

        if (image == null) return;

        if (mounted) {
          context.push(
            '/add_subscription?t=${DateTime.now().millisecondsSinceEpoch}',
            extra: {
              'imagePath': image.path,
              'shouldParse': true,
            },
          );
        }
        return;
      }

      // Android specific scanner
      final options = DocumentScannerOptions(
        mode: ScannerMode.filter, 
        pageLimit: 1,
      );
      
      final scanner = DocumentScanner(options: options);
      final result = await scanner.scanDocument();
      
      if (result.images == null || result.images!.isEmpty) return;
      
      if (mounted) {
        context.push(
          '/add_subscription?t=${DateTime.now().millisecondsSinceEpoch}', 
          extra: {
            'imagePath': result.images!.first,
            'shouldParse': true,
          },
        );
      }
    } catch (e) {
      debugPrint('Error scanning: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Scan failed: $e'))
         );
      }
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    bool isLocked = false,
    VoidCallback? onTap,
  }) {
    return Bounceable(
      onTap: isLocked ? null : onTap,
      scaleFactor: 0.98,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(title, style: AppTheme.subscriptionRowTitle),
          subtitle: subtitle != null
              ? Text(subtitle, style: AppTheme.subscriptionRowSubtitle)
              : null,
          trailing: isLocked
              ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey)
              : const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }
}
