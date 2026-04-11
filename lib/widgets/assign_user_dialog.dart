import 'package:flutter/material.dart';

class AssignUserDialog extends StatefulWidget {
  final String? currentAssignedName;

  const AssignUserDialog({
    super.key,
    this.currentAssignedName,
  });

  @override
  State<AssignUserDialog> createState() => _AssignUserDialogState();
}

class _AssignUserDialogState extends State<AssignUserDialog> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.currentAssignedName != null) {
      _nameController.text = widget.currentAssignedName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Назначить ответственного'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Введите имя пользователя, который будет ответственным за эту задачу',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Имя ответственного',
              hintText: 'Введите имя',
              prefixIcon: const Icon(Icons.person, color: Color(0xFF6366F1)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        if (widget.currentAssignedName != null)
          TextButton(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: const Text(
              'Снять ответственного',
              style: TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              Navigator.pop(context, _nameController.text.trim());
            }
          },
          child: const Text('Назначить'),
        ),
      ],
    );
  }
}

Future<String?> showAssignUserDialog(
  BuildContext context, {
  String? currentAssignedName,
}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => AssignUserDialog(
      currentAssignedName: currentAssignedName,
    ),
  );
}
