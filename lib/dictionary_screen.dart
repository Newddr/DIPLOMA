import 'package:flutter/material.dart';
import 'package:slovar/Word_screen.dart';

import 'DB/DBHelper.dart';
import 'main.dart';
import 'package:slovar/main.dart';




class DictionariesScreen extends StatefulWidget {
  final String value;
  final int id;
  final String dictionaries;
  final VoidCallback onClosed;
  final VoidCallback updateMainPage; // Добавьте этот колбэк

  DictionariesScreen({required this.value, required this.id, required this.dictionaries, required this.onClosed, required this.updateMainPage});
  @override
  _DictionariesScreenState createState() => _DictionariesScreenState();
}

int i=0;
class _DictionariesScreenState extends State<DictionariesScreen> {

  bool isAppBarActionsVisible = false;
  List<int> selectedCardIndices = [];

  List<Map<String, dynamic>> words = [];

  int get id => widget.id;


  void initState() {
    super.initState();
    _loadWordsFromDatabase();
  }

  Future<void> _recre() async {
    await DBHelper.instance.recreateDatabase();
  }
  late List<Map<String, dynamic>> pinnedWords;
  late List<Map<String, dynamic>> unpinnedWords;
  Future<void> _loadWordsFromDatabase() async {
    List<Map<String, dynamic>> loadedWords = await DBHelper.instance
        .getPinnedWords(id);
    List<Map<String, dynamic>> loadedWordsUnPinned = await DBHelper.instance
        .getUnPinnedWords(id);

    // Сначала добавляем закрепленные слова
     pinnedWords = loadedWords
        .toList();
     unpinnedWords = loadedWordsUnPinned
        .toList();
    print('pinnedWords= $pinnedWords');
    print('loadedWords= $loadedWords');
    print('loadedWordsUnPinned= $loadedWordsUnPinned');
    print('unpinned= $unpinnedWords');
    setState(() {
      words = [...pinnedWords, ...unpinnedWords];
    });
  }

  Color getColorFromString(String hexColor) {
    // Примеры строк цветов: "red", "blue", "green", и так далее
    try{int value = int.parse(hexColor, radix: 16);
    return Color(value).withAlpha(0xFF);}
        catch(e){
          return Colors.white;
        }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.value),
        actions: isAppBarActionsVisible
            ? [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteSelectedWords();
            },
          ),
          IconButton(
            icon: Icon(Icons.push_pin),
            onPressed: () {
              _pinSelectedWords();
              _resetSelection();
            },
          ),
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: () {
              _showColorPaletteDialog(context);
            },
          ),
        ]
            : [],
      ),
      body: ListView.builder(
        itemCount: words.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCardIndices.contains(index);
          bool isPinned = pinnedWords.contains(words[index]);
          print("isPinned= $isPinned");

          return Card(
            color: isSelected
                ? Colors.grey
                : (getColorFromString(words[index]['color']) ?? Colors.white),
            // Set the color from the list or use transparent if not set

            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        words[index]['name'] as String,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPinned) Icon(Icons.push_pin, color: Colors.orange),
                    ],
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    words[index]['spelling_value'].length <= 17
                        ? words[index]['spelling_value']
                        : '${words[index]['spelling_value'].substring(
                        0, 17)}...',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              onTap: () {
                if (isAppBarActionsVisible) {
                  _toggleSelection(index);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WordScreen(
                            word: _check(index),
                          ),
                    ),
                  );
                }
              },
              onLongPress: () {
                setState(() {
                  isAppBarActionsVisible = !isAppBarActionsVisible;
                  _toggleSelection(index);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _check(index) {
    print('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF-${words[index]}');
    return words[index];
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedCardIndices.contains(index)) {
        selectedCardIndices.remove(index);
      } else {
        selectedCardIndices.add(index);
      }
    });
  }

  void _resetSelection() {
    setState(() {
      if (selectedCardIndices.isNotEmpty) {
        selectedCardIndices = [];
        isAppBarActionsVisible = false;
      }
    });
  }

  Future<void> _deleteSelectedWords() async {
    await DBHelper.instance.deleteFromDictionary(
        widget.id, words[selectedCardIndices[0]]['id_word']);
    setState(() {
      words = List.from(words);
      words.removeWhere((word) =>
      word['id_word'] == words[selectedCardIndices[0]]['id_word']);
      _resetSelection();
    });
    await _loadWordsFromDatabase();
  }


  void _pinSelectedWords() async {
    for (var index in selectedCardIndices) {
      int pinStatus= await DBHelper.instance.isPinned(widget.id,words[index]['id_word'])==1?0:1;
      await DBHelper.instance.pinWord(widget.id,words[index]['id_word'],pinStatus);

    }
    updateList();
  }

  void _showColorPaletteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorButton(Colors.redAccent),
                _buildColorButton(Colors.cyan),
                _buildColorButton(Colors.teal),
                _buildColorButton(Colors.orangeAccent),
                _buildColorButton(Colors.deepPurpleAccent),
                _buildColorButton(Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        _applyColorToSelectedCards(color,words[selectedCardIndices[0]]['id_word']);
        widget.onClosed();
        widget.updateMainPage();
        Navigator.of(context).pop();
      },
      child: Container(
        width: 35,
        height: 35,
        padding: EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2.0),
          // Добавление обводки
          color: color,
        ),
      ),
    );
  }

  Future<void> _applyColorToSelectedCards(Color color,int id) async {
    String colorString = color.value.toRadixString(16);
    await DBHelper.instance.ChangeColor(id, colorString);
    updateList();

  }
  void updateList()
  {
    setState(() {
      _resetSelection();
      _loadWordsFromDatabase();
    });
  }

}
