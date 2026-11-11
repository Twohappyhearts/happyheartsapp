import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class SearchBarInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBarInputWidget({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
        decoration: const InputDecoration(
          hintText: 'Search lessons, topics...',
          hintStyle: TextStyle(fontSize: 14, color: AppTheme.textLight),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppTheme.textLight,
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
          filled: false,
        ),
      ),
    );
  }
}
