import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const InputField({super.key, required this.controller, required this.onSend});

  @override
  Widget build(BuildContext c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Type a message…'),
              onSubmitted: (_) => onSend(),
            ),
          ),
          TextButton(onPressed: onSend, child: const Text('Send')),
        ],
      ),
    );
  }
}
