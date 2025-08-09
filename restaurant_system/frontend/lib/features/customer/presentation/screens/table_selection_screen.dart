import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/table.dart';
import '../../../../core/services/notification_service.dart';

final tablesProvider = FutureProvider<List<RestaurantTable>>((ref) async {
  return await ApiService.getTables();
});

class TableSelectionScreen extends ConsumerStatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  ConsumerState<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends ConsumerState<TableSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Register FCM token for customer
    NotificationService.registerToken('customer');
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Table'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: tablesAsync.when(
        data: (tables) => _buildTableGrid(context, tables),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading tables: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(tablesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableGrid(BuildContext context, List<RestaurantTable> tables) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your table number:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return _buildTableCard(context, table);
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, RestaurantTable table) {
    Color cardColor;
    Color textColor;
    IconData icon;
    bool isSelectable;

    switch (table.status) {
      case 'available':
        cardColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        isSelectable = true;
        break;
      case 'occupied':
        cardColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        isSelectable = false;
        break;
      case 'reserved':
        cardColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.schedule;
        isSelectable = false;
        break;
      default:
        cardColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help;
        isSelectable = false;
    }

    return Card(
      color: cardColor,
      elevation: isSelectable ? 4 : 2,
      child: InkWell(
        onTap: isSelectable
            ? () => _selectTable(context, table.tableNumber)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: textColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Table ${table.tableNumber}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                table.statusDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legend:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              Colors.green.shade100,
              Colors.green.shade800,
              Icons.check_circle,
              'Available',
            ),
            _buildLegendItem(
              Colors.red.shade100,
              Colors.red.shade800,
              Icons.cancel,
              'Occupied',
            ),
            _buildLegendItem(
              Colors.orange.shade100,
              Colors.orange.shade800,
              Icons.schedule,
              'Reserved',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color bgColor, Color textColor, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: textColor, size: 16),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _selectTable(BuildContext context, int tableNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Table $tableNumber'),
        content: Text('You have selected Table $tableNumber. Would you like to view the menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/customer/menu/$tableNumber');
            },
            child: const Text('View Menu'),
          ),
        ],
      ),
    );
  }
}

