import 'package:flutter/material.dart';

Future<T> showAlertDialog<T>(
  BuildContext context, {
  String? title,
  required String content,
}) async {
  return await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}
