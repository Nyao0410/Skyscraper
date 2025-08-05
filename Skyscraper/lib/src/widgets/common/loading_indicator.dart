import 'package:flutter/material.dart';

/// A widget to display a loading indicator.
class LoadingIndicator extends StatelessWidget {
  /// Creates a [LoadingIndicator] widget.
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}