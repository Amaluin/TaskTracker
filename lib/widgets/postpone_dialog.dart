import 'package:flutter/material.dart';
import 'ios_time_picker.dart';

class PostponeDialog extends StatelessWidget {
  const PostponeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.schedule, color: Color(0xFF8B5CF6)),
          SizedBox(width: 12),
          Text('Отложить задачу'),
        ],
      ),
      content: const Text(
        'Выберите дату и время, на которое хотите отложить задачу. Вам будет создано напоминание на это время.',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('ru', 'RU'),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF8B5CF6),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Color(0xFF1F2937),
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child!,
                );
              },
            );

            if (date != null && context.mounted) {
              final time = await showIOSTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (time != null && context.mounted) {
                final postponeUntil = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
                Navigator.pop(context, postponeUntil);
              }
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: const Text('Выбрать дату'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }
}

Future<DateTime?> showPostponeDialog(BuildContext context) async {
  return await showDialog<DateTime>(
    context: context,
    builder: (context) => const PostponeDialog(),
  );
}
