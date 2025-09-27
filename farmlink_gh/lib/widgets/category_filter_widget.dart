import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class CategoryFilterWidget extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryFilterWidget({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: AppConstants.fontSizeNormal,
            fontWeight: FontWeight.w500,
            color: Color(AppConstants.textColor),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // All Categories Option
              _buildCategoryChip(
                'All',
                null,
                selectedCategory == null,
              ),
              const SizedBox(width: AppConstants.spacingSmall),
              
              // Category Chips
              ...AppConstants.productCategories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppConstants.spacingSmall),
                  child: _buildCategoryChip(
                    category,
                    category,
                    selectedCategory == category,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? value, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Color(AppConstants.textColor),
          fontSize: AppConstants.fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        onCategorySelected(selected ? value : null);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Color(AppConstants.primaryColor),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected 
            ? Color(AppConstants.primaryColor) 
            : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingNormal,
        vertical: AppConstants.spacingSmall,
      ),
    );
  }
}
