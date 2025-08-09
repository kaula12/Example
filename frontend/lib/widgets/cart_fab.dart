import 'package:flutter/material.dart';
import '../core/theme.dart';

class CartFAB extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onPressed;

  const CartFAB({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: Stack(
          children: [
            const Icon(Icons.shopping_cart),
            if (itemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        label: Text(
          'KSh ${total.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

