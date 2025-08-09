import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/cart_fab.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final int restaurantId;
  final int tableId;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.tableId,
  });

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider(widget.restaurantId));
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.room_service),
            onPressed: () => _showServiceRequestDialog(context),
          ),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load menu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(menuProvider(widget.restaurantId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (menu) {
          // Update tab controller length
          if (_tabController.length != menu.categories.length) {
            _tabController.dispose();
            _tabController = TabController(
              length: menu.categories.length,
              vsync: this,
            );
          }

          // Filter items based on search and category
          List<MenuItem> filteredItems = menu.items;
          
          if (searchQuery.isNotEmpty) {
            filteredItems = filteredItems.where((item) =>
              item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (item.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
            ).toList();
          }
          
          if (selectedCategory != null) {
            filteredItems = filteredItems.where((item) =>
              item.categoryId == selectedCategory
            ).toList();
          }

          return Column(
            children: [
              // Restaurant Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table ${widget.tableId}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome! Browse our menu and add items to your cart.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Categories
              if (menu.categories.isNotEmpty)
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: menu.categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CategoryChip(
                          label: 'All',
                          isSelected: selectedCategory == null,
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).state = null;
                          },
                        );
                      }
                      
                      final category = menu.categories[index - 1];
                      return CategoryChip(
                        label: category.name,
                        isSelected: selectedCategory == category.id,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state = category.id;
                        },
                      );
                    },
                  ),
                ),

              // Menu Items
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'No items found for "$searchQuery"'
                                  : 'No items available',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return MenuItemCard(
                            item: item,
                            onTap: () {
                              context.go(
                                '/item/${item.id}?restaurantId=${widget.restaurantId}&tableId=${widget.tableId}',
                              );
                            },
                            onAddToCart: () {
                              ref.read(cartProvider.notifier).addItem(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} added to cart'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: cart.isNotEmpty
          ? CartFAB(
              itemCount: ref.read(cartProvider.notifier).itemCount,
              total: ref.read(cartProvider.notifier).total,
              onPressed: () {
                context.go('/cart?restaurantId=${widget.restaurantId}&tableId=${widget.tableId}');
              },
            )
          : null,
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Menu'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search for items...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              ref.read(searchQueryProvider.notifier).state = _searchController.text;
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showServiceRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_drink),
              title: const Text('Water'),
              onTap: () => _requestService('water', 'Please bring water'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Bill'),
              onTap: () => _requestService('bill', 'Please bring the bill'),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Assistance'),
              onTap: () => _requestService('assistance', 'Need assistance'),
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clean Table'),
              onTap: () => _requestService('cleanup', 'Please clean the table'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _requestService(String type, String message) async {
    Navigator.of(context).pop();
    
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.createServiceRequest({
        'table_id': widget.tableId,
        'request_type': type,
        'message': message,
        'priority': 1,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service request sent successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

