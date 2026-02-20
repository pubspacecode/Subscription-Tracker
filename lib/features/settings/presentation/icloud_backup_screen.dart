import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/icloud/icloud_backup_service.dart';

class ICloudBackupScreen extends StatefulWidget {
  const ICloudBackupScreen({super.key});

  @override
  State<ICloudBackupScreen> createState() => _ICloudBackupScreenState();
}

class _ICloudBackupScreenState extends State<ICloudBackupScreen> {
  DateTime? _lastBackupDate;
  bool _loadingDate = true;
  bool _backing = false;
  bool _restoring = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final date = await ICloudBackupService().lastBackupDate();
    if (mounted) setState(() { _lastBackupDate = date; _loadingDate = false; });
  }

  // ─── Backup ────────────────────────────────────────────────────────────────

  Future<void> _doBackup() async {
    setState(() { _backing = true; _progress = 0; });
    try {
      final date = await ICloudBackupService().backup(
        onProgress: (p) { if (mounted) setState(() => _progress = p); },
      );
      if (mounted) {
        setState(() { _lastBackupDate = date; _backing = false; });
        _showSnack('Backup complete ✓', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _backing = false);
        _showSnack('Backup failed: $e', isError: true);
      }
    }
  }

  // ─── Restore ───────────────────────────────────────────────────────────────

  Future<void> _doRestore() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Restore from iCloud?'),
        content: const Text(
          'This will replace ALL current data with the iCloud backup. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _restoring = true; _progress = 0; });
    try {
      await ICloudBackupService().restore(
        onProgress: (p) { if (mounted) setState(() => _progress = p); },
      );
      if (mounted) {
        setState(() => _restoring = false);
        _showSnack('Restore complete ✓', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _restoring = false);
        _showSnack('Restore failed: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.red.shade900 : const Color(0xFF1C1C1E),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isError ? Colors.red.withOpacity(0.3) : const Color(0xFF6C63FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      elevation: 0,
    ));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      DateFormat('MMM d, y · h:mm a').format(d.toLocal());

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final busy = _backing || _restoring;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'iCloud Backup',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Status card ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A0533), Color(0xFF0D0221)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF6C63FF).withOpacity(0.4),
                              width: 1),
                        ),
                        child: const Icon(Icons.cloud_done_rounded,
                            color: Color(0xFF6C63FF), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('iCloud Backup',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 3),
                            _loadingDate
                                ? const Text('Checking...',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13))
                                : Text(
                                    _lastBackupDate == null
                                        ? 'No backup found'
                                        : 'Last backup: ${_fmtDate(_lastBackupDate!)}',
                                    style: TextStyle(
                                        color: _lastBackupDate == null
                                            ? Colors.grey
                                            : Colors.greenAccent,
                                        fontSize: 13),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (busy) ...[
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      color: const Color(0xFF6C63FF),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _backing ? 'Backing up…' : 'Restoring…',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Actions ─────────────────────────────────────────────────────
          _ActionTile(
            icon: Icons.cloud_upload_rounded,
            iconColor: const Color(0xFF6C63FF),
            title: 'Back Up Now',
            subtitle: 'Saves all subscriptions to iCloud',
            loading: _backing,
            disabled: busy,
            onTap: _doBackup,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.cloud_download_rounded,
            iconColor: Colors.orangeAccent,
            title: 'Restore from iCloud',
            subtitle: 'Replaces local data with backup',
            loading: _restoring,
            disabled: busy || _lastBackupDate == null,
            onTap: _doRestore,
            destructive: true,
          ),

          const SizedBox(height: 32),

          // ── Info text ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.grey, size: 16),
                    SizedBox(width: 6),
                    Text('How it works',
                        style:
                            TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  'Your data is encrypted and stored privately in your iCloud account.',
                  'Only you can access it — we never see your data.',
                  'Restoring from another device requires signing in to the same Apple ID.',
                  'Back up regularly to ensure your data is always safe.',
                ].map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 13)),
                        Expanded(
                            child: Text(t,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13,
                                    height: 1.4))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable action tile ──────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.disabled,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final titleColor = destructive ? Colors.orangeAccent : Colors.white;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: iconColor.withOpacity(0.25), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6C63FF)))
              else
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
