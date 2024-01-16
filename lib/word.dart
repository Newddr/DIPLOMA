import 'package:flutter/material.dart';

class Word {
  String text;
  String description;
  bool isPinned;
  Color color;

  Word({
    required this.text,
    required this.description,
    this.isPinned = false,
    this.color = Colors.white,
  });

}