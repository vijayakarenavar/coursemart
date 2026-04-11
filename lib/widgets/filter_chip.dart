/// Filter Chip Widget
///
/// Reusable filter chip for course filtering
/// with selection state and custom styling.
library;

import 'package:flutter/material.dart';

/// Filter option data model
class FilterOption {
  final String label;
  final String value;
  final IconData? icon;

  const FilterOption({required this.label, required this.value, this.icon});
}

/// Course filter chip widget
///
/// Displays a filter chip with selection state
/// Used for filtering courses by status
class CourseFilterChip extends StatelessWidget {
  final FilterOption option;
  final bool isSelected;
  final VoidCallback onSelected;

  const CourseFilterChip({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (option.icon != null) ...[
            Icon(
              option.icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
          ],
          Text(option.label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 1.5,
        ),
      ),
    );
  }
}

/// Filter bar widget
///
/// Horizontal scrollable list of filter chips
class FilterBar extends StatelessWidget {
  final List<FilterOption> options;
  final String selectedValue;
  final ValueChanged<String> onFilterChanged;

  const FilterBar({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onFilterChanged,
  });

  /// Default course filter options
  static const List<FilterOption> courseFilters = [
    FilterOption(label: 'All', value: 'all', icon: Icons.list),
    FilterOption(
      label: 'In Progress',
      value: 'in_progress',
      icon: Icons.play_circle,
    ),
    FilterOption(
      label: 'Completed',
      value: 'completed',
      icon: Icons.check_circle,
    ),
    FilterOption(
      label: 'Not Started',
      value: 'not_started',
      icon: Icons.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CourseFilterChip(
              option: option,
              isSelected: selectedValue == option.value,
              onSelected: () => onFilterChanged(option.value),
            ),
          );
        },
      ),
    );
  }
}
