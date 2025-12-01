import 'package:flutter/material.dart';

class LegalResourcesPanel extends StatelessWidget {
  final Function(String) onResourceSelected;

  const LegalResourcesPanel({
    super.key,
    required this.onResourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quick Legal Help',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildResourceChip('Contract Review', Icons.description, context),
              _buildResourceChip('Rental Issues', Icons.home, context),
              _buildResourceChip('Employment Law', Icons.work, context),
              _buildResourceChip('Family Law', Icons.family_restroom, context),
              _buildResourceChip('Consumer Rights', Icons.shopping_cart, context),
              _buildResourceChip('Criminal Law', Icons.gavel, context),
              _buildResourceChip('Property Disputes', Icons.real_estate_agent, context),
              _buildResourceChip('Legal Documents', Icons.article, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChip(String title, IconData icon, BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(title),
      onPressed: () => onResourceSelected(title),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}