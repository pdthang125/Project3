import 'dart:io';
import 'package:flutter/material.dart';

Widget buildReceiptImage(
  String path, {
  required double width,
  required double height,
  required BoxFit fit,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
