import 'dart:convert';
import 'dart:io';
import 'dart:math';


import 'package:flutter/foundation.dart';


List<String> words = generateWords(15);
List<String> words2 = generateWords2(15);
List<String> dictionaries=generateWords(5);
List<String> generateWords(int count) {
  Random random = Random();
  List<String> generatedWords = List.generate(count, (_) {
    int length = random.nextInt(12) + 3; // random length from 1 to 5
    String word = String.fromCharCodes(List.generate(length, (_) {
      int charCode = random.nextInt(26) + 97; // random char from a to z
      return charCode;
    }));
    return word;
  });

  return generatedWords;
}
List<String> generateWords2(int count) {
  Random random = Random();
  List<String> generatedWords = List.generate(count, (_) {
    int length = random.nextInt(60) + 3; // random length from 1 to 5
    String word = String.fromCharCodes(List.generate(length, (_) {
      int charCode = random.nextInt(26) + 97; // random char from a to z
      return charCode;
    }));
    return word;

  });
  return generatedWords;
}







