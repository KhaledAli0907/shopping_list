import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/helpers/build_url.dart';
import 'package:shopping_list/models/category.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final response = await http.get(shoppingListUri());
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data. Please try again later.';
      });
      return;
    }
    final dynamic decoded = json.decode(response.body);
    if (decoded == null) {
      if (!mounted) return;
      setState(() {
        _groceryItems = [];
        _isLoading = false;
      });
      return;
    }

    if (decoded is! Map<String, dynamic>) {
      if (!mounted) return;
      setState(() {
        _groceryItems = [];
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData =
        decoded['shopping-list'] is Map<String, dynamic>
        ? decoded['shopping-list'] as Map<String, dynamic>
        : decoded;
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      if (item.value is! Map) {
        continue;
      }

      final itemData = Map<String, dynamic>.from(item.value as Map);
      final categoryName = itemData['category']?.toString();
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.name == categoryName,
            orElse: () =>
                MapEntry(Categories.other, categories[Categories.other]!),
          )
          .value;

      final quantityValue = itemData['quantity'];
      final quantity = quantityValue is int
          ? quantityValue
          : int.tryParse(quantityValue.toString()) ?? 1;
      final name = itemData['name']?.toString();
      if (name == null || name.trim().isEmpty) {
        continue;
      }
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: name,
          quantity: quantity,
          category: category,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) => const NewItemScreen()),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) {
    setState(() {
      _groceryItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) {
          final item = _groceryItems[index];
          return Dismissible(
            confirmDismiss: (direction) async {
              final response = await http.delete(shoppingListItemUri(item.id));
              if (response.statusCode >= 400) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not delete item. Try again.'),
                    ),
                  );
                }
                return false;
              }
              return true;
            },
            onDismissed: (direction) {
              _removeItem(item);
            },
            key: ValueKey(item.id),
            child: ListTile(
              title: Text(item.name),
              leading: Container(
                width: 24,
                height: 24,
                color: item.category.color,
              ),
              trailing: Text(item.quantity.toString()),
            ),
          );
        },
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
