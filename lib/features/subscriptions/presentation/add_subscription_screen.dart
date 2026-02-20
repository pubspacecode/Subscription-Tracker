import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../application/subscription_parser_service.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/presentation/widgets/bounceable.dart';
import '../../../core/presentation/widgets/subscription_icon.dart';
import '../../paywall/presentation/paywall_screen.dart';
import '../data/subscription_model.dart';
import '../data/subscription_repository.dart';
import '../../../core/presentation/widgets/primary_button.dart';
import '../../../core/database/hive_service.dart';
import '../../settings/data/subscription_list_model.dart';
import '../../settings/data/category_model.dart';
import '../../settings/data/payment_method_model.dart';
import '../../settings/presentation/lists_screen.dart';
import '../../settings/presentation/categories_screen.dart';
import '../../settings/presentation/payment_methods_screen.dart';
import '../../settings/data/currency_provider.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription? subscription; // For editing in the future
  final String? initialName;
  final int? initialIconCodePoint;
  final int? initialColorValue;
  final String? initialAmount;
  final DateTime? initialNextRenewalDate;
  final String? initialImagePath;
  final bool shouldParse;

  const AddSubscriptionScreen({
    super.key, 
    this.subscription, 
    this.initialName,
    this.initialIconCodePoint,
    this.initialColorValue,
    this.initialAmount,
    this.initialNextRenewalDate,
    this.initialImagePath,
    this.shouldParse = false,
  });

  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  
  BillingCycle _billingCycle = BillingCycle.monthly;
  int _recurrenceFrequency = 1;
  String _recurrencePeriod = 'Month';
  String _category = 'Other'; // Default
  String _currency = 'USD'; // Default
  DateTime _nextRenewalDate = DateTime.now();
  bool _reminderEnabled = true;
  String? _paymentMethod = 'None';
  bool _isFreeTrial = false;
  String _listName = 'Personal'; // Default
  int? _iconCodePoint;
  int? _colorValue;
  XFile? _imageFile;
  bool _isAnalyzing = false;

  final List<String> _notificationOptions = ['Same day', '1 day before', '2 days before', '3 days before', '1 week before'];
  String _selectedNotificationOption = '1 day before';
  
  DateTime? _startDate;
  String _usageNotificationFrequency = 'Every 1 day';
  final List<String> _usageNotificationOptions = ['Every 1 day', 'Every 2 days', 'Every 3 days', 'Every 1 week', 'Every 2 weeks'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subscription?.name ?? widget.initialName);
    _amountController = TextEditingController(text: widget.subscription?.amount.toString());
    _urlController = TextEditingController(text: widget.subscription?.url);
    _notesController = TextEditingController(text: widget.subscription?.notes);
    
    _iconCodePoint = widget.subscription?.iconCodePoint ?? widget.initialIconCodePoint;
    _colorValue = widget.subscription?.colorValue ?? widget.initialColorValue;

    if (widget.subscription?.imagePath != null) {
      _imageFile = XFile(widget.subscription!.imagePath!);
    } else if (widget.initialImagePath != null) {
      _imageFile = XFile(widget.initialImagePath!);
    }

     if (widget.subscription != null) {
      _billingCycle = widget.subscription!.billingCycle;
      _category = widget.subscription!.category;
      _nextRenewalDate = widget.subscription!.nextRenewalDate;
      _reminderEnabled = widget.subscription!.reminderEnabled;
      _paymentMethod = widget.subscription!.paymentMethod ?? 'None';
      _isFreeTrial = widget.subscription!.isFreeTrial;
      _listName = widget.subscription!.listName ?? 'Personal';
      _currency = widget.subscription!.currency;
      _recurrenceFrequency = widget.subscription!.recurrenceFrequency;
      _recurrencePeriod = widget.subscription!.recurrencePeriod;
      _startDate = widget.subscription!.startDate;
      _usageNotificationFrequency = widget.subscription!.usageNotificationFrequency ?? 'Every 1 day';
    } else {
      // Set defaults from Hive if available
      if (HiveService.listsBox.isNotEmpty) {
        _listName = HiveService.listsBox.values.first.name;
      }
      if (HiveService.categoriesBox.isNotEmpty) {
         // Optionally set first category, or keep 'Other'/Default
         // _category = HiveService.categoriesBox.values.first.name; 
      }
      // Set default currency to preferrred currency
      final preferredCurrency = ref.read(currencyProvider);
      _currency = preferredCurrency.code;

      if (widget.initialAmount != null) {
        _amountController.text = widget.initialAmount!;
      }
      if (widget.initialNextRenewalDate != null) {
         _nextRenewalDate = widget.initialNextRenewalDate!;
      }

      if (widget.shouldParse && widget.initialImagePath != null) {
        _isAnalyzing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _analyzeImage(widget.initialImagePath!);
        });
      }
      
      // Set default notification offset if not set
      if (widget.subscription != null) {
        final days = widget.subscription!.renewalReminderDays;
        if (days == 0) _selectedNotificationOption = 'Same day';
        else if (days == 1) _selectedNotificationOption = '1 day before';
        else if (days == 2) _selectedNotificationOption = '2 days before';
        else if (days == 3) _selectedNotificationOption = '3 days before';
        else if (days == 7) _selectedNotificationOption = '1 week before';
      }
    }
  }

  Future<void> _analyzeImage(String imagePath) async {
    try {
      final parser = ref.read(subscriptionParserServiceProvider);
      final data = await parser.parseDocument(imagePath);

      if (mounted) {
        setState(() {
           _isAnalyzing = false;
           
           if (data.detectedSubscriptions != null && data.detectedSubscriptions!.isNotEmpty) {
               context.push('/detected_subscriptions', extra: data.detectedSubscriptions);
               return;
           }
           
           if (data.amount != null) {
             _amountController.text = data.amount!;
           }
           if (data.date != null) {
             _nextRenewalDate = data.date!;
           }
           if (data.name != null) {
             _nameController.text = data.name!;
           }
           if (data.iconCodePoint != null) {
             _iconCodePoint = data.iconCodePoint!;
           }
           if (data.colorValue != null) {
             _colorValue = data.colorValue!;
           }
           if (data.currency != null) {
             _currency = data.currency!;
           }
           if (data.billingCycle != null) {
             _billingCycle = data.billingCycle!;
             // infer period/frequency from billing cycle for backward compatibility
             if (_billingCycle == BillingCycle.weekly) {
               _recurrencePeriod = 'Week';
               _recurrenceFrequency = 1;
             } else if (_billingCycle == BillingCycle.yearly) {
               _recurrencePeriod = 'Year';
               _recurrenceFrequency = 1;
             } else {
               _recurrencePeriod = 'Month';
               _recurrenceFrequency = 1;
             }
           }
        });
      }
    } catch (e) {
      debugPrint('Analysis failed: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextRenewalDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _nextRenewalDate) {
      setState(() {
        _nextRenewalDate = picked;
      });
    }
  }

  // Generic Picker Dialog with Rounded Corners
  void _showPicker({
    required String title,
    required List<String> items,
    required String selectedItem,
    required ValueChanged<String> onSelected,
    VoidCallback? onAddNew,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                   padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), 
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       if (onAddNew != null)
                         GestureDetector(
                           onTap: () {
                             Navigator.pop(context);
                             onAddNew();
                           },
                           child: const Icon(Icons.add, color: Colors.purple),
                         ),
                     ],
                   )
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (ctx, index) => const Divider(height: 1, color: Color(0xFF2C2C2E)),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item == selectedItem;
                      return ListTile(
                        title: Text(
                          item,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        trailing: isSelected 
                            ? const Icon(Icons.check, color: Colors.purple, size: 20)
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        onTap: () {
                          onSelected(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomBillingCyclePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        int tempFrequency = _recurrenceFrequency;
        String tempPeriod = _recurrencePeriod;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 350,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Billing Cycle', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _recurrenceFrequency = tempFrequency;
                            _recurrencePeriod = tempPeriod;
                            
                            // Update legacy billingCycle for backward compatibility
                            if (tempFrequency == 1) {
                              if (tempPeriod == 'Week') _billingCycle = BillingCycle.weekly;
                              else if (tempPeriod == 'Year') _billingCycle = BillingCycle.yearly;
                              else _billingCycle = BillingCycle.monthly;
                            } else {
                              _billingCycle = BillingCycle.monthly; // Default fallback
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Done', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        // Frequency Picker
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 40,
                            perspective: 0.005,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(initialItem: tempFrequency - 1),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempFrequency = index + 1;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 24,
                              builder: (context, index) {
                                return Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: (index + 1) == tempFrequency ? Colors.white : Colors.grey,
                                      fontSize: 20,
                                      fontWeight: (index + 1) == tempFrequency ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Period Picker
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 40,
                            perspective: 0.005,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(initialItem: ['Day', 'Week', 'Month', 'Year'].indexOf(tempPeriod)),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempPeriod = ['Day', 'Week', 'Month', 'Year'][index];
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 4,
                              builder: (context, index) {
                                final item = ['Day', 'Week', 'Month', 'Year'][index];
                                final isSelected = item == tempPeriod;
                                return Center(
                                  child: Text(
                                    isSelected && tempFrequency > 1 ? '${item}s' : item,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey,
                                      fontSize: 20,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
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
        );
      },
    );
  }

  void _showListPicker() {
    final lists = HiveService.listsBox.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    final items = lists.map((e) => e.name).toList();
    
    _showPicker(
      title: 'Select List',
      items: items,
      selectedItem: _listName,
      onSelected: (val) => setState(() => _listName = val),
      onAddNew: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ListsScreen())),
    );
  }

  void _showCategoryPicker() {
    final categories = HiveService.categoriesBox.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    final items = categories.map((e) => e.name).toList();

    _showPicker(
      title: 'Select Category',
      items: items,
      selectedItem: _category,
      onSelected: (val) => setState(() => _category = val),
      onAddNew: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
    );
  }

  void _showPaymentMethodPicker() {
    final methods = HiveService.paymentMethodsBox.values.toList();
    final items = ['None', ...methods.map((e) => e.name)];

    _showPicker(
      title: 'Payment Method',
      items: items,
      selectedItem: _paymentMethod ?? 'None',
      onSelected: (val) => setState(() => _paymentMethod = val),
      onAddNew: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
    );
  }

  void _showNotificationPicker() {
    _showPicker(
      title: 'Notification',
      items: _notificationOptions,
      selectedItem: _selectedNotificationOption,
      onSelected: (val) => setState(() => _selectedNotificationOption = val),
    );
  }

  void _showCurrencyPicker() {
    final codes = supportedCurrencies.map((e) => e.code).toList();
    _showPicker(
      title: 'Currency',
      items: codes,
      selectedItem: _currency,
      onSelected: (val) => setState(() => _currency = val),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _showUsageNotificationPicker() {
    _showPicker(
      title: 'Still using Notification',
      items: _usageNotificationOptions,
      selectedItem: _usageNotificationFrequency,
      onSelected: (val) => setState(() => _usageNotificationFrequency = val),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
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
                  Navigator.pop(context);
                  // Request camera permission on Android
                  final status = await Permission.camera.request();
                  if (status.isGranted) {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      setState(() { _imageFile = image; });
                    }
                  } else if (status.isPermanentlyDenied) {
                    await openAppSettings();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Camera permission is required to take a photo.')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  // Android 13+ uses READ_MEDIA_IMAGES; older uses READ_EXTERNAL_STORAGE
                  final Permission storagePermission =
                      (await Permission.photos.status).isGranted
                          ? Permission.photos
                          : Permission.storage;
                  final status = await storagePermission.request();
                  if (status.isGranted || status.isLimited) {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() { _imageFile = image; });
                    }
                  } else if (status.isPermanentlyDenied) {
                    await openAppSettings();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gallery permission is required to choose a photo.')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void _saveSubscription() {
    if (!_formKey.currentState!.validate()) {
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Missing Information', style: TextStyle(color: Colors.white)),
          content: const Text('Please enter a Name and Amount for the subscription.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.purple)),
            ),
          ],
        )
      );
      return;
    }

    final repository = ref.read(subscriptionRepositoryProvider);
    final name = _nameController.text.trim();

    // 1. Check Free Tier Limit
    final currentCount = repository.getAllSubscriptions().where((s) => s.isActive).length;
    if (widget.subscription == null && currentCount >= 5) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }

    // 2. Check for duplicate name (case-insensitive, exclude self if editing)
    final isDuplicate = repository.getAllSubscriptions().any((s) => 
      s.name.toLowerCase() == name.toLowerCase() && 
      (widget.subscription == null || s.id != widget.subscription!.id)
    );

    if (isDuplicate) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Duplicate Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'A subscription with this name already exists. Save anyway?', 
            style: TextStyle(color: Colors.white70, fontSize: 14)
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _performSave();
              },
              child: const Text('Save Anyway', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      _performSave();
    }
  }

  void _performSave() {
    final repository = ref.read(subscriptionRepositoryProvider);
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    
    // Map offset
    int daysBefore = 1;
    if (_selectedNotificationOption == 'Same day') daysBefore = 0;
    else if (_selectedNotificationOption == '1 day before') daysBefore = 1;
    else if (_selectedNotificationOption == '2 days before') daysBefore = 2;
    else if (_selectedNotificationOption == '3 days before') daysBefore = 3;
    else if (_selectedNotificationOption == '1 week before') daysBefore = 7;

    if (widget.subscription == null || !widget.subscription!.isInBox) {
      // Create new
      final newSubscription = Subscription.create(
        name: name,
        amount: amount,
        currency: _currency,
        billingCycle: _billingCycle,
        nextRenewalDate: _nextRenewalDate,
        category: _category,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        reminderEnabled: _reminderEnabled,
        url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        paymentMethod: _paymentMethod == 'None' ? null : _paymentMethod,
        isFreeTrial: _isFreeTrial,
        listName: _listName,
        iconCodePoint: _iconCodePoint,
        colorValue: _colorValue,
        imagePath: _imageFile?.path,
        recurrenceFrequency: _recurrenceFrequency,
        recurrencePeriod: _recurrencePeriod,
        startDate: _startDate,
        usageNotificationFrequency: _usageNotificationFrequency,
        renewalReminderDays: daysBefore,
      );

      repository.addSubscription(newSubscription);
    } else {
      // Update existing logic
      widget.subscription!.name = name;
      widget.subscription!.amount = amount;
      widget.subscription!.currency = _currency;
      widget.subscription!.billingCycle = _billingCycle;
      widget.subscription!.nextRenewalDate = _nextRenewalDate;
      widget.subscription!.category = _category;
      widget.subscription!.notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
      widget.subscription!.reminderEnabled = _reminderEnabled;
      widget.subscription!.url = _urlController.text.trim().isEmpty ? null : _urlController.text.trim();
      widget.subscription!.paymentMethod = _paymentMethod == 'None' ? null : _paymentMethod;
      widget.subscription!.isFreeTrial = _isFreeTrial;
      widget.subscription!.listName = _listName;
      widget.subscription!.iconCodePoint = _iconCodePoint; 
      widget.subscription!.colorValue = _colorValue;
      widget.subscription!.imagePath = _imageFile?.path;
      widget.subscription!.recurrenceFrequency = _recurrenceFrequency;
      widget.subscription!.recurrencePeriod = _recurrencePeriod;
      widget.subscription!.startDate = _startDate;
      widget.subscription!.usageNotificationFrequency = _usageNotificationFrequency;
      widget.subscription!.renewalReminderDays = daysBefore;
      
      repository.updateSubscription(widget.subscription!);
    }
    
    if (widget.subscription == null || !widget.subscription!.isInBox) {
      // Adding: Go back (returns true to indicate success)
      context.pop(true);
    } else {
      // Editing: Go back to Details
      context.pop();
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), 
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.subscription != null ? 'Edit Subscription' : 'Add Details', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: _isAnalyzing 
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4), 
                child: LinearProgressIndicator(color: Colors.purpleAccent, backgroundColor: Colors.transparent),
              ) 
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: PrimaryButton(
              onPressed: _saveSubscription,
              text: widget.subscription != null ? 'Submit' : 'Save',
              height: 36,
              width: 80,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 0),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          children: [
            // HEADING CARD
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: ListenableBuilder(
                      listenable: _nameController,
                      builder: (context, _) {
                        return SubscriptionIcon(
                          name: _nameController.text,
                          iconCodePoint: _iconCodePoint ?? (_nameController.text.isEmpty && _imageFile == null ? Icons.add.codePoint : null),
                          colorValue: _colorValue,
                          imagePath: _imageFile?.path,
                          size: 50,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Name',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        Row(
                          children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A3A3C),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: GestureDetector(
                                  onTap: _showCurrencyPicker,
                                  child: Text(
                                    supportedCurrencies.firstWhere((c) => c.code == _currency, orElse: () => const Currency('USD', '\$')).symbol, 
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SCHEDULE CARD
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text('SCHEDULE', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                   _buildRowItem(
                    'Start date', 
                    trailing: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('d MMM yyyy').format(_startDate ?? DateTime.now()),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  _buildDivider(),
                  _buildRowItem(
                    'Payment date', 
                    trailing: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('d MMM yyyy').format(_nextRenewalDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  _buildDivider(),
                  _buildRowItem(
                    'Billing Cycle',
                    trailingText: 'Every ${_recurrenceFrequency > 1 ? '$_recurrenceFrequency ' : ''}${_recurrencePeriod.toLowerCase()}${_recurrenceFrequency > 1 ? 's' : ''}',
                    hasArrow: true,
                    onTap: _showCustomBillingCyclePicker,
                  ),
                  _buildDivider(),
                  _buildRowItem(
                    'Free Trial',
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _isFreeTrial,
                        onChanged: (val) => setState(() => _isFreeTrial = val),
                        activeColor: Colors.white,
                        activeTrackColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // DETAILS CARD
            // DETAILS CARD
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text('DETAILS', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildRowItem(
                    'List', 
                    trailingText: _listName, 
                    hasArrow: true,
                    onTap: _showListPicker,
                  ),
                  _buildDivider(),
                  _buildRowItem(
                    'Category', 
                    trailingText: _category,
                    hasArrow: true,
                    onTap: _showCategoryPicker,
                  ),
                  _buildDivider(),
                  _buildRowItem(
                    'Payment Method',
                    trailingText: _paymentMethod,
                    hasArrow: true,
                    onTap: _showPaymentMethodPicker,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // NOTIFICATION CARD
            // NOTIFICATION CARD
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text('NOTIFICATIONS', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                   _buildRowItem(
                    'Renewal Notification', 
                    trailingText: _selectedNotificationOption,
                    hasArrow: true,
                    onTap: _showNotificationPicker,
                  ),
                  _buildDivider(),
                  _buildRowItem(
                    'Still using Notification', 
                    trailingText: _usageNotificationFrequency,
                    hasArrow: true,
                    onTap: _showUsageNotificationPicker,
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),

            // URL & NOTES
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text('MORE DETAILS', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Website', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  TextFormField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'www.websitename.com',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFF2C2C2E)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Notes', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  TextFormField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Add notes...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String title, {String? trailingText, Widget? trailing, bool hasArrow = false, VoidCallback? onTap}) {
    return Bounceable(
      onTap: onTap,
      scaleFactor: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Row(
              children: [
                if (trailingText != null)
                  Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                if (trailing != null)
                  trailing,
                if (hasArrow)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFF2C2C2E), indent: 16, endIndent: 16);
  }
}
