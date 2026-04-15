import 'package:flutter/material.dart';

/// Stateful dialog that owns its [TextEditingController] (safe lifecycle).
class NameInputDialog extends StatefulWidget {
  const NameInputDialog({
    super.key,
    required this.title,
    required this.label,
    this.initialText = '',
  });

  final String title;
  final String label;
  final String initialText;

  @override
  State<NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<NameInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.label),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<String?>(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop<String?>(_controller.text.trim()),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
