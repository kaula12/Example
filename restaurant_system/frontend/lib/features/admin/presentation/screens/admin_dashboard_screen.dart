import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';

final dailySalesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiService.getDailySales();
});

final popularItemsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiService.getPopularItems();
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Register FCM token for admin
    NotificationService.registerToken('admin');
  }

  @override
  Widget build(BuildContext context) {
    final dailySalesAsync = ref.watch(dailySalesProvider);
    final popularItemsAsync = ref.watch(popularItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 24),
            
            // Daily Sales Summary
            const Text(
              'Today\'s Sales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            dailySalesAsync.when(
              data: (data) => _buildSalesCard(data),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => _buildErrorCard('Failed to load sales data'),
            ),
            const SizedBox(height: 24),
            
            // Popular Items
            const Text(
              'Popular Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            popularItemsAsync.when(
              data: (data) => _buildPopularItemsCard(data),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => _buildErrorCard('Failed to load popular items'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildActionButton(
                  'Menu Management',
                  Icons.restaurant_menu,
                  Colors.blue,
                  () => context.go('/admin/menu-management'),
                ),
                _buildActionButton(
                  'Table Management',
                  Icons.table_restaurant,
                  Colors.green,
                  () => context.go('/admin/table-management'),
                ),
                _buildActionButton(
                  'Analytics',
                  Icons.analytics,
                  Colors.purple,
                  () => context.go('/admin/analytics'),
                ),
                _buildActionButton(
                  'Kitchen View',
                  Icons.kitchen,
                  Colors.orange,
                  () => context.go('/kitchen/dashboard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesCard(Map<String, dynamic> data) {
    final totalSales = data['total_sales']?.toDouble() ?? 0.0;
    final totalOrders = data['total_orders'] ?? 0;
    final averageOrderValue = data['average_order_value']?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSalesMetric(
                  'Total Sales',
                  '\$${totalSales.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildSalesMetric(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
                _buildSalesMetric(
                  'Avg Order',
                  '\$${averageOrderValue.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPopularItemsCard(Map<String, dynamic> data) {
    final popularItems = data['popular_items'] as List<dynamic>? ?? [];

    if (popularItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No popular items data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...popularItems.take(5).map((item) => _buildPopularItemRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItemRow(dynamic item) {
    final name = item['name'] ?? 'Unknown Item';
    final quantity = item['total_quantity'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _refreshData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshData() {
    ref.refresh(dailySalesProvider);
    ref.refresh(popularItemsProvider);
  }
}

