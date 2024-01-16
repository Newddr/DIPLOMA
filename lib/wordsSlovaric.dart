import 'dart:math';

List<String> words1 = generateWords(15);
List<String> dictionaries1=generateWords(5);
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



