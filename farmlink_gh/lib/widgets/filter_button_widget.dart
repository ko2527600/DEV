import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class FilterButtonWidget extends StatelessWidget {
  final int filterCount;
  final VoidCallback onTap;
  final bool isExpanded;

  const FilterButtonWidget({
    super.key,
    required this.filterCount,
    required this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingNormal,
          vertical: AppConstants.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: filterCount > 0 
              ? Color(AppConstants.primaryColor)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
          border: Border.all(
            color: filterCount > 0 
                ? Color(AppConstants.primaryColor)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 20,
              color: filterCount > 0 
                  ? Colors.white
                  : Color(AppConstants.textColorLight),
            ),
            const SizedBox(width: AppConstants.spacingSmall),
            Text(
              'Filters',
              style: TextStyle(
                fontSize: AppConstants.fontSizeNormal,
                fontWeight: FontWeight.w500,
                color: filterCount > 0 
                    ? Colors.white
                    : Color(AppConstants.textColor),
              ),
            ),
            if (filterCount > 0) ...[
              const SizedBox(width: AppConstants.spacingSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSmall,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Text(
                  filterCount.toString(),
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSmall,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                  ),
                ),
              ),
            ],
            const SizedBox(width: AppConstants.spacingSmall),
            Icon(
              isExpanded 
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 20,
              color: filterCount > 0 
                  ? Colors.white
                  : Color(AppConstants.textColorLight),
            ),
          ],
        ),
      ),
    );
  }
}
