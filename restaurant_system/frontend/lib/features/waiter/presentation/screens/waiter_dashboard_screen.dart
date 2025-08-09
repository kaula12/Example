import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/models/order.dart';
import '../../../../core/models/table.dart';

final waiterTablesProvider = FutureProvider<List<RestaurantTable>>((ref) async {
  // In a real app, you would filter by waiter ID
  return await ApiService.getTables();
});

final waiterOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return await ApiService.getOrders();
});

final waiterAlertsProvider = FutureProvider<List<dynamic>>((ref) async {
  // In a real app, you would pass the waiter ID
  return await ApiService.getWaiterAlerts();
});

class WaiterDashboardScreen extends ConsumerStatefulWidget {
  const WaiterDashboardScreen({super.key});

  @override
  ConsumerState<WaiterDashboardScreen> createState() => _WaiterDashboardScreenState();
}

class _WaiterDashboardScreenState extends ConsumerState<WaiterDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Register FCM token for waiter
    NotificationService.registerToken('waiter');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiter Dashboard'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.table_restaurant), text: 'Tables'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
            Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTablesTab(),
          _buildOrdersTab(),
          _buildAlertsTab(),
        ],
      ),
    );
  }

  Widget _buildTablesTab() {
    final tablesAsync = ref.watch(waiterTablesProvider);

    return tablesAsync.when(
      data: (tables) => _buildTablesList(tables),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget('Failed to load tables: $error'),
    );
  }

  Widget _buildOrdersTab() {
    final ordersAsync = ref.watch(waiterOrdersProvider);

    return ordersAsync.when(
      data: (orders) => _buildOrdersList(orders),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget('Failed to load orders: $error'),
    );
  }

  Widget _buildAlertsTab() {
    final alertsAsync = ref.watch(waiterAlertsProvider);

    return alertsAsync.when(
      data: (alerts) => _buildAlertsList(alerts),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget('Failed to load alerts: $error'),
    );
  }

  Widget _buildTablesList(List<RestaurantTable> tables) {
    if (tables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tables assigned'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return _buildTableCard(table);
      },
    );
  }

  Widget _buildTableCard(RestaurantTable table) {
    Color statusColor;
    IconData statusIcon;

    switch (table.status) {
      case 'available':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'occupied':
        statusColor = Colors.red;
        statusIcon = Icons.people;
        break;
      case 'reserved':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text('Table ${table.tableNumber}'),
        subtitle: Text('Status: ${table.statusDisplayName}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleTableAction(table, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_orders',
              child: Row(
                children: [
                  Icon(Icons.receipt_long),
                  SizedBox(width: 8),
                  Text('View Orders'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mark_available',
              child: Row(
                children: [
                  Icon(Icons.check_circle),
                  SizedBox(width: 8),
                  Text('Mark Available'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mark_occupied',
              child: Row(
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 8),
                  Text('Mark Occupied'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No orders found'),
          ],
        ),
      );
    }

    // Group orders by status
    final pendingOrders = orders.where((o) => o.status == 'pending' || o.status == 'confirmed').toList();
    final preparingOrders = orders.where((o) => o.status == 'preparing').toList();
    final readyOrders = orders.where((o) => o.status == 'ready').toList();
    final completedOrders = orders.where((o) => o.status == 'served').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (readyOrders.isNotEmpty) ...[
            _buildOrderSection('Ready for Service', readyOrders, Colors.green),
            const SizedBox(height: 16),
          ],
          if (preparingOrders.isNotEmpty) ...[
            _buildOrderSection('Being Prepared', preparingOrders, Colors.orange),
            const SizedBox(height: 16),
          ],
          if (pendingOrders.isNotEmpty) ...[
            _buildOrderSection('Pending Orders', pendingOrders, Colors.blue),
            const SizedBox(height: 16),
          ],
          if (completedOrders.isNotEmpty) ...[
            _buildOrderSection('Completed Orders', completedOrders, Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSection(String title, List<Order> orders, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...orders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(order.tableNumber.toString()),
        ),
        title: Text('Order #${order.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table ${order.tableNumber} • ${order.statusDisplayName}'),
            Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
            if (order.createdAt != null)
              Text('Time: ${_formatTime(order.createdAt!)}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleOrderAction(order, value),
          itemBuilder: (context) => [
            if (order.status == 'ready')
              const PopupMenuItem(
                value: 'mark_served',
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark as Served'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'view_details',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(List<dynamic> alerts) {
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No alerts'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    final tableNumber = alert['table_number'];
    final message = alert['message'];
    final createdAt = DateTime.tryParse(alert['created_at'] ?? '');
    final alertType = alert['alert_type'] ?? 'customer_request';

    IconData icon;
    Color color;

    switch (alertType) {
      case 'customer_request':
        icon = Icons.room_service;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notification_important;
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text('Table $tableNumber'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (createdAt != null)
              Text(
                'Time: ${_formatTime(createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.check),
          onPressed: () => _acknowledgeAlert(alert),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    ref.refresh(waiterTablesProvider);
    ref.refresh(waiterOrdersProvider);
    ref.refresh(waiterAlertsProvider);
  }

  void _handleTableAction(RestaurantTable table, String action) async {
    switch (action) {
      case 'view_orders':
        // Navigate to table orders
        break;
      case 'mark_available':
      case 'mark_occupied':
        // Update table status
        break;
    }
  }

  void _handleOrderAction(Order order, String action) async {
    switch (action) {
      case 'mark_served':
        try {
          await ApiService.updateOrderStatus(order.id!, 'served');
          ref.refresh(waiterOrdersProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order marked as served'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update order: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'view_details':
        // Navigate to order details
        break;
    }
  }

  void _acknowledgeAlert(dynamic alert) {
    // In a real app, you would mark the alert as acknowledged
    ref.refresh(waiterAlertsProvider);
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

