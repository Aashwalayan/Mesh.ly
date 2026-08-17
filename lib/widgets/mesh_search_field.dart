import 'package:flutter/material.dart';

/// The rounded search box used on both the Chats and Contacts screens.
class MeshSearchField extends StatelessWidget {
  const MeshSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search people...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}
