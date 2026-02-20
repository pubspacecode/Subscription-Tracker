import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../core/presentation/widgets/primary_button.dart';
import '../data/payment_method_model.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: HiveService.paymentMethodsBox.listenable(),
              builder: (context, Box<PaymentMethod> box, _) {
                final methods = box.values.toList(); // No specific sort order for now

                if (methods.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No payment methods added', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          onPressed: _showAddPaymentMethodSheet,
                          text: 'Add New Method',
                          width: 200,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: methods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final method = methods[index];
                    return _buildPaymentMethodCard(method);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PrimaryButton(
              onPressed: _showAddPaymentMethodSheet,
              text: 'Add New Payment Method',
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    IconData iconData = Icons.credit_card;
    Color iconColor = Colors.white;

    if (method.type == 'Visa') {
      iconData = Icons.credit_card; // Replaced with generic if specific icon needed
      iconColor = Colors.blue;
    } else if (method.type == 'MasterCard') {
      iconColor = Colors.orange;
    } else if (method.type == 'PayPal') {
      iconData = Icons.account_balance_wallet;
      iconColor = Colors.blueAccent;
    } else if (method.type == 'Apple Pay') {
        iconData = Icons.apple;
    } else if (method.type == 'Google Pay') {
        iconData = Icons.android; // Placeholder
        iconColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      method.type.toUpperCase(),
                      style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    if (method.last4Digits != null && method.last4Digits!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•••• ${method.last4Digits}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(method),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(PaymentMethod method) {
      showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Payment Method?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${method.name}"?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
               method.delete();
               Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const AddPaymentMethodSheet(),
    );
  }
}

class AddPaymentMethodSheet extends StatefulWidget {
  const AddPaymentMethodSheet({super.key});

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  final _nameController = TextEditingController();
  final _last4Controller = TextEditingController();
  String _selectedType = 'Credit Card';

  final List<String> _types = ['Credit Card', 'Visa', 'MasterCard', 'Amex', 'PayPal', 'Apple Pay', 'Google Pay', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add Payment Method', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          
          DropdownButtonFormField<String>(
            value: _selectedType,
            dropdownColor: const Color(0xFF2C2C2E),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Type',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Name (e.g. Personal Card)',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_selectedType.contains('Card') || _selectedType == 'Visa' || _selectedType == 'MasterCard' || _selectedType == 'Amex')
             TextField(
              controller: _last4Controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Last 4 Digits (Optional)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                counterText: "",
              ),
            ),

          const SizedBox(height: 24),
          PrimaryButton(
            onPressed: _saveMethod,
            text: 'Add Method',
          ),
        ],
      ),
    );
  }

  void _saveMethod() {
    if (_nameController.text.isEmpty) {
        // Maybe default to type if empty?
        _nameController.text = _selectedType;
    }

    final newMethod = PaymentMethod.create(
      name: _nameController.text, 
      type: _selectedType,
      last4Digits: _last4Controller.text.isNotEmpty ? _last4Controller.text : null,
    );

    HiveService.paymentMethodsBox.add(newMethod);
    Navigator.pop(context);
  }
}
