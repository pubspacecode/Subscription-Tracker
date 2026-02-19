import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../core/presentation/widgets/bounceable.dart';
import '../../../../core/services/currency_service.dart';
import '../data/category_model.dart';
import '../../subscriptions/data/subscription_model.dart';
import '../../settings/data/currency_provider.dart';
import '../../settings/data/exchange_rate_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => _showAddEditCategorySheet(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Organize subscriptions by type. Long press and drag to reorder.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: HiveService.categoriesBox.listenable(),
              builder: (context, Box<CategoryModel> box, _) {
                final categories = box.values.toList()..sort((a, b) => a.order.compareTo(b.order));
                final selectedCurrency = ref.watch(currencyProvider);
                final exchangeRatesAsync = ref.watch(exchangeRateProvider);
                final currencyService = ref.watch(currencyServiceProvider);
                final rates = exchangeRatesAsync.value ?? {};

                return ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 40),
                  itemCount: categories.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = categories.removeAt(oldIndex);
                    categories.insert(newIndex, item);
                    _updateCategoryOrder(categories);
                  },
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryGroup(
                      category,
                      key: ValueKey(category.id),
                      selectedCurrency: selectedCurrency,
                      rates: rates,
                      currencyService: currencyService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCategoryOrder(List<CategoryModel> reordered) async {
      for (int i = 0; i < reordered.length; i++) {
          final item = reordered[i];
          final updated = CategoryModel(
              id: item.id, 
              name: item.name, 
              order: i
          );
          await HiveService.categoriesBox.put(item.key, updated);
      }
  }

  Widget _buildCategoryGroup(
    CategoryModel category, {
    required Key key,
    required dynamic selectedCurrency,
    required Map<String, double> rates,
    required CurrencyService currencyService,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                children: [
                  const Icon(Icons.drag_handle, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    category.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                 onPressed: () => _showEditMenu(context, category),
              ),
            ],
          ),
        ),
        // Fetch subscriptions for this category
        ValueListenableBuilder(
          valueListenable: HiveService.subscriptionBox.listenable(),
          builder: (context, Box<Subscription> box, _) {
            final subs = box.values.where((s) => s.category == category.name && s.isActive && !s.isDeleted).toList();
            
            if (subs.isEmpty) {
               return Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('No subscriptions', style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final sub = subs[index];
                  final converted = currencyService.convert(
                    sub.amount, sub.currency, selectedCurrency.code, rates,
                  );
                  return Bounceable(
                    onTap: () => _showMoveToCategorySheet(context, sub),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                           Container(
                             width: 32,
                             height: 32,
                             decoration: BoxDecoration(
                               color: sub.colorValue != null ? Color(sub.colorValue!) : Colors.grey[800],
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: sub.iconCodePoint != null 
                                 ? Icon(IconData(sub.iconCodePoint!, fontFamily: 'MaterialIcons'), color: Colors.white, size: 20)
                                 : Center(child: Text(sub.name[0], style: const TextStyle(color: Colors.white))),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Text(sub.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                           ),
                           Text(
                             NumberFormat.simpleCurrency(name: selectedCurrency.code).format(converted),
                             style: const TextStyle(color: Colors.grey, fontSize: 16),
                           ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showEditMenu(BuildContext context, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text('Rename Category', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEditCategorySheet(context, category: category);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Category', style: TextStyle(color: Colors.red)),
                onTap: () {
                   Navigator.pop(context);
                   _confirmDeleteCategory(context, category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryModel category) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Category?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${category.name}"?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
               category.delete();
               Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddEditCategorySheet(BuildContext context, {CategoryModel? category}) {
    final controller = TextEditingController(text: category?.name);
    final isEditing = category != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
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
              Text(isEditing ? 'Rename Category' : 'New Category', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Category Name (e.g. Education)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    final box = HiveService.categoriesBox;
                    if (isEditing) {
                        final updated = CategoryModel(
                            id: category.id, 
                            name: controller.text, 
                            order: category.order
                        );
                        box.put(category.key, updated);
                    } else {
                        final newCategory = CategoryModel.create(name: controller.text, order: box.length);
                        box.add(newCategory);
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEditing ? 'Save Changes' : 'Create Category', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoveToCategorySheet(BuildContext context, Subscription subscription) {
    // Get all categories
    final box = HiveService.categoriesBox;
    final categories = box.values.toList()..sort((a, b) => a.order.compareTo(b.order));

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Move To',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No categories available. Create one first!', style: TextStyle(color: Colors.grey)),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: categories.map((category) {
                        final isSelected = subscription.category == category.name;
                        return ListTile(
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? Colors.purple : Colors.grey,
                          ),
                          title: Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[400],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () async {
                            // Move logic
                            subscription.category = category.name;
                            await subscription.save();
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
