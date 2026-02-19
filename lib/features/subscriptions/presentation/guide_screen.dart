import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../../../../core/constants/theme.dart';
import '../../../../core/presentation/widgets/bounceable.dart';
import '../application/statement_parser_service.dart';
import 'guide_detail_screen.dart';

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  
  Future<void> _scanDocument() async {
    try {
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

  Future<void> _importFile() async {
    try {
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

  void _navigateToDetail({
    required String title,
    required List<GuideStep> steps,
    required VoidCallback onStart,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GuideDetailScreen(
          title: title,
          steps: steps,
          onStart: () {
            Navigator.pop(context); // Close detail screen
            onStart(); // Execute action
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('How to start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          children: [
            _buildActionRow(
              icon: Icons.list_alt,
              color: Colors.blueAccent,
              title: 'Manual selection of service',
              subtitle: 'Browse our curated list of popular services to quickly add subscriptions with pre-filled details like icons and colors.',
              onTap: () => _navigateToDetail(
                title: 'Manual Selection',
                steps: [
                  GuideStep(
                    description: 'Browse our curated list of popular services. We have hundreds of icons and colors ready for you.',
                    icon: Icons.list_alt,
                    color: Colors.blueAccent,
                  ),
                  GuideStep(
                    description: 'Select your service from the list. It will auto-fill the name, icon, and default color.',
                    icon: Icons.touch_app,
                    color: Colors.blueAccent,
                  ),
                  GuideStep(
                    description: 'Enter the amount and billing cycle, and you are done!',
                    icon: Icons.check_circle,
                    color: Colors.blueAccent,
                  ),
                ],
                onStart: () => context.push('/add'),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionRow(
              icon: Icons.edit_note,
              color: Colors.orangeAccent,
              title: 'Manual entry of service',
              subtitle: 'Create a custom subscription from scratch if you can\'t find your service in the list.',
              onTap: () => _navigateToDetail(
                title: 'Manual Entry',
                steps: [
                  GuideStep(
                    description: 'Can\'t find your service in our list? No problem. Create a custom subscription from scratch.',
                    icon: Icons.edit_note,
                    color: Colors.orangeAccent,
                  ),
                  GuideStep(
                    description: 'Enter the name, amount, and choose a custom icon and color to make it yours.',
                    icon: Icons.palette,
                    color: Colors.orangeAccent,
                  ),
                  GuideStep(
                    description: 'Set the billing cycle and renewal date to keep track specifically for your needs.',
                    icon: Icons.calendar_today,
                    color: Colors.orangeAccent,
                  ),
                ],
                onStart: () => context.push('/add_subscription?t=${DateTime.now().millisecondsSinceEpoch}'),
              ),
            ),
             const SizedBox(height: 16),
            _buildActionRow(
              icon: Icons.camera_alt,
              color: Colors.purpleAccent,
              title: 'Import from photo',
              subtitle: 'Take a photo of a renewal bill or receipt. We\'ll automatically extract the details like amount and date.',
              onTap: () => _navigateToDetail(
                title: 'Import from Photo',
                steps: [
                   GuideStep(
                    description: 'Using generic ML models, we can scan your paper bills or receipts.',
                    icon: Icons.camera_alt,
                    color: Colors.purpleAccent,
                  ),
                  GuideStep(
                    description: 'Take a clear photo of your renewal notice or receipt.',
                    icon: Icons.crop_free,
                    color: Colors.purpleAccent,
                  ),
                  GuideStep(
                    description: 'Our AI will try to detect the Service Name, Amount, and Next Renewal Date for you.',
                    icon: Icons.auto_awesome,
                    color: Colors.purpleAccent,
                  ),
                ],
                onStart: _scanDocument,
              ),
            ),
             const SizedBox(height: 16),
            _buildActionRow(
              icon: Icons.upload_file,
              color: Colors.greenAccent,
              title: 'Import from file',
              subtitle: 'Upload a PDF bank statement or CSV file to analyze and detect recurring payments automatically.',
              onTap: () => _navigateToDetail(
                title: 'Import from File',
                steps: [
                   GuideStep(
                    description: 'Have a bank statement PDF or CSV? We can analyze it to find all your subscriptions at once.',
                    icon: Icons.upload_file,
                    color: Colors.greenAccent,
                  ),
                  GuideStep(
                    description: 'Upload your file. We process it securely on your device—no data leaves your phone.',
                    icon: Icons.shield,
                    color: Colors.greenAccent,
                  ),
                  GuideStep(
                    description: 'Review the detected recurring payments and add them to your tracker in one click.',
                    icon: Icons.playlist_add_check,
                    color: Colors.greenAccent,
                  ),
                ],
                onStart: _importFile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Bounceable(
      onTap: onTap,
      scaleFactor: 0.98,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
