import 'package:flutter/material.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.header,
    required this.body,
    this.reserveBottomNavSpace = true,
    this.bodyPadding,
  });

  final Widget header;
  final Widget body;
  final bool reserveBottomNavSpace;
  final EdgeInsetsGeometry? bodyPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          header,
          Expanded(
            child: SingleChildScrollView(
              padding: bodyPadding ??
                  EdgeInsets.only(bottom: reserveBottomNavSpace ? 96 : 16),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
