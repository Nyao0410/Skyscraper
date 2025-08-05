import 'package:flutter/material.dart';

/// A widget to display an error message.
class ErrorDisplay extends StatelessWidget {
  /// Creates an [ErrorDisplay] widget.
  const ErrorDisplay({required this.message, super.key});
  
  /// The error message to display.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}
