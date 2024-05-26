import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddWordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить новое слово'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  labelText: 'Новое слово',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите слово',
                  prefixIcon: Icon(Icons.insert_emoticon, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода слова
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Орфографический словарь',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите значение',
                  fillColor: Colors.grey[200],
                  filled: true,
                  prefixIcon: Icon(Icons.book, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода для орфографического словаря
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Толковый словарь',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите значение',
                  fillColor: Colors.grey[200],
                  filled: true,
                  prefixIcon: Icon(Icons.translate, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода для толкового словаря
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Словарь ударений русского языка',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите значение',
                  fillColor: Colors.grey[200],
                  filled: true,
                  prefixIcon: Icon(Icons.volume_up, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода для словаря ударений
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Словарь имен собственных',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите значение',
                  fillColor: Colors.grey[200],
                  filled: true,
                  prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода для словаря имен собственных
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Словарь синонимов',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите значение',
                  fillColor: Colors.grey[200],
                  filled: true,
                  prefixIcon: Icon(Icons.merge_type_rounded, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода для словаря синонимов
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Словарь методических терминов',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите значение',
                  fillColor: Colors.grey[200],
                  filled: true,
                  prefixIcon: Icon(Icons.school, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода для словаря методических терминов
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Словарь антонимов',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите значение',
                  fillColor: Colors.grey[200],
                  filled: true,
                  prefixIcon: Icon(Icons.swap_horiz, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода для словаря антонимов
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Словарь примеров использования',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  hintText: 'Введите значение',
                  fillColor: Colors.grey[200],
                  filled: true,
                  prefixIcon: Icon(Icons.bookmark, color: Colors.blueAccent),
                ),
                onSubmitted: (value) {
                  // Обработка ввода для словаря примеров использования
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Здесь должна быть логика для сохранения данных
                  Navigator.pop(context);
                },
                child: Text('Добавить'),
                style: ElevatedButton.styleFrom(

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
