import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../../../core/services/api_service.dart';
import '../../../../core/models/menu_item.dart';
import '../../../../core/models/cart_item.dart';
import '../providers/cart_provider.dart';

final menuProvider = FutureProvider<List<MenuItem>>((ref) async {
  return await ApiService.getMenu();
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  return await ApiService.getMenuCategories();
});

class MenuScreen extends ConsumerStatefulWidget {
  final int tableNumber;

  const MenuScreen({super.key, required this.tableNumber});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Table ${widget.tableNumber} - Menu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/customer/table-selection'),
        ),
        actions: [
          badges.Badge(
            badgeContent: Text(
              cart.length.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            showBadge: cart.isNotEmpty,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => context.go('/customer/cart/${widget.tableNumber}'),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'call_waiter') {
                _callWaiter();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'call_waiter',
                child: Row(
                  children: [
                    Icon(Icons.room_service),
                    SizedBox(width: 8),
                    Text('Call Waiter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories
          categoriesAsync.when(
            data: (categories) => _buildCategoryTabs(categories),
            loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
            error: (error, stack) => const SizedBox(),
          ),
          // Menu Items
          Expanded(
            child: menuAsync.when(
              data: (menuItems) => _buildMenuList(menuItems),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading menu: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(menuProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/customer/cart/${widget.tableNumber}'),
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart (${cart.length})'),
            )
          : null,
    );
  }

  Widget _buildCategoryTabs(List<String> categories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip('All', selectedCategory == null);
          }
          final category = categories[index - 1];
          return _buildCategoryChip(category, selectedCategory == category);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = selected ? (category == 'All' ? null : category) : null;
          });
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMenuList(List<MenuItem> menuItems) {
    final filteredItems = selectedCategory == null
        ? menuItems
        : menuItems.where((item) => item.category == selectedCategory).toList();

    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No items found in this category'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.restaurant,
                      size: 40,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: item.available ? () => _addToCart(item) : null,
                        child: const Text('Add to Cart'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => _AddToCartDialog(
        menuItem: item,
        onAdd: (cartItem) {
          ref.read(cartProvider.notifier).addItem(cartItem);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} added to cart'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _callWaiter() async {
    try {
      await ApiService.sendWaiterAlert(
        widget.tableNumber,
        'Customer at table ${widget.tableNumber} is requesting assistance',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waiter has been notified'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call waiter: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AddToCartDialog extends StatefulWidget {
  final MenuItem menuItem;
  final Function(CartItem) onAdd;

  const _AddToCartDialog({
    required this.menuItem,
    required this.onAdd,
  });

  @override
  State<_AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<_AddToCartDialog> {
  int quantity = 1;
  final TextEditingController instructionsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.menuItem.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.menuItem.description),
          const SizedBox(height: 16),
          Text(
            'Price: \$${widget.menuItem.price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Quantity: '),
              IconButton(
                onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text(quantity.toString()),
              IconButton(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: instructionsController,
            decoration: const InputDecoration(
              labelText: 'Special Instructions (Optional)',
              hintText: 'e.g., No onions, extra spicy',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Total: \$${(widget.menuItem.price * quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final cartItem = CartItem(
              menuItem: widget.menuItem,
              quantity: quantity,
              specialInstructions: instructionsController.text.isEmpty
                  ? null
                  : instructionsController.text,
            );
            widget.onAdd(cartItem);
            Navigator.of(context).pop();
          },
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    instructionsController.dispose();
    super.dispose();
  }
}

