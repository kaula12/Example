import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/table.dart';

final adminTablesProvider = FutureProvider<List<RestaurantTable>>((ref) async {
  return await ApiService.getTables();
});

class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(adminTablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminTablesProvider),
          ),
        ],
      ),
      body: tablesAsync.when(
        data: (tables) => _buildTablesList(context, ref, tables),
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
                onPressed: () => ref.refresh(adminTablesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTableDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTablesList(BuildContext context, WidgetRef ref, List<RestaurantTable> tables) {
    if (tables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tables found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add tables to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Sort tables by table number
    tables.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));

    return Column(
      children: [
        // Summary card
        _buildSummaryCard(tables),
        
        // Tables grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                return _buildTableCard(context, ref, table);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(List<RestaurantTable> tables) {
    final totalTables = tables.length;
    final availableTables = tables.where((t) => t.status == 'available').length;
    final occupiedTables = tables.where((t) => t.status == 'occupied').length;
    final reservedTables = tables.where((t) => t.status == 'reserved').length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Table Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total', totalTables, Colors.blue),
                _buildSummaryItem('Available', availableTables, Colors.green),
                _buildSummaryItem('Occupied', occupiedTables, Colors.red),
                _buildSummaryItem('Reserved', reservedTables, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(BuildContext context, WidgetRef ref, RestaurantTable table) {
    Color cardColor;
    Color textColor;
    IconData icon;

    switch (table.status) {
      case 'available':
        cardColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'occupied':
        cardColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.people;
        break;
      case 'reserved':
        cardColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.schedule;
        break;
      default:
        cardColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help;
    }

    return Card(
      color: cardColor,
      elevation: 2,
      child: InkWell(
        onTap: () => _showTableOptionsDialog(context, ref, table),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                table.statusDisplayName,
                style: TextStyle(
                  fontSize: 10,
                  color: textColor,
                ),
              ),
              if (table.waiterId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Waiter: ${table.waiterId}',
                  style: TextStyle(
                    fontSize: 8,
                    color: textColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTableDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddTableDialog(
        onAdd: (tableNumber) async {
          try {
            final table = RestaurantTable(
              tableNumber: tableNumber,
              status: 'available',
            );
            await ApiService.createTable(table);
            ref.refresh(adminTablesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Table added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add table: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showTableOptionsDialog(BuildContext context, WidgetRef ref, RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Table ${table.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${table.statusDisplayName}'),
            if (table.waiterId != null)
              Text('Assigned Waiter: ${table.waiterId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (table.status != 'available')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateTableStatus(context, ref, table, 'available');
              },
              child: const Text('Mark Available'),
            ),
          if (table.status != 'occupied')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateTableStatus(context, ref, table, 'occupied');
              },
              child: const Text('Mark Occupied'),
            ),
          if (table.status != 'reserved')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateTableStatus(context, ref, table, 'reserved');
              },
              child: const Text('Mark Reserved'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAssignWaiterDialog(context, ref, table);
            },
            child: const Text('Assign Waiter'),
          ),
        ],
      ),
    );
  }

  void _showAssignWaiterDialog(BuildContext context, WidgetRef ref, RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => _AssignWaiterDialog(
        table: table,
        onAssign: (waiterId) async {
          try {
            await ApiService.assignWaiterToTable(table.tableNumber, waiterId);
            ref.refresh(adminTablesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Waiter assigned successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to assign waiter: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _updateTableStatus(BuildContext context, WidgetRef ref, RestaurantTable table, String newStatus) async {
    try {
      final updatedTable = table.copyWith(status: newStatus);
      await ApiService.updateTable(table.id!, updatedTable);
      ref.refresh(adminTablesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Table ${table.tableNumber} marked as $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update table status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AddTableDialog extends StatefulWidget {
  final Function(int) onAdd;

  const _AddTableDialog({required this.onAdd});

  @override
  State<_AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<_AddTableDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Table'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Table Number',
            hintText: 'Enter table number',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Table number is required';
            if (int.tryParse(value!) == null) return 'Invalid table number';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              widget.onAdd(int.parse(_controller.text));
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add Table'),
        ),
      ],
    );
  }
}

class _AssignWaiterDialog extends StatefulWidget {
  final RestaurantTable table;
  final Function(int) onAssign;

  const _AssignWaiterDialog({required this.table, required this.onAssign});

  @override
  State<_AssignWaiterDialog> createState() => _AssignWaiterDialogState();
}

class _AssignWaiterDialogState extends State<_AssignWaiterDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.table.waiterId != null) {
      _controller.text = widget.table.waiterId.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Waiter to Table ${widget.table.tableNumber}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Waiter ID',
            hintText: 'Enter waiter ID',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Waiter ID is required';
            if (int.tryParse(value!) == null) return 'Invalid waiter ID';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              widget.onAssign(int.parse(_controller.text));
              Navigator.of(context).pop();
            }
          },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

