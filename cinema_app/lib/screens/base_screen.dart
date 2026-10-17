import 'package:flutter/material.dart';

abstract class BaseScreen<T> extends StatelessWidget {
  final T data;

  const BaseScreen({
    super.key,
    required this.data,
  });


  Widget buildContent(BuildContext context, T data);

  @override
  Widget build(BuildContext context) {
    // Bố cục chung cho các màn hình
    return SafeArea(
      child: buildContent(context, data),
    );
  }
}