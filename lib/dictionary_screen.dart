import 'package:flutter/material.dart';
import 'package:slovar/Word_screen.dart';
import 'package:slovar/addWordScreen.dart';
import 'package:slovar/utils/constants.dart';
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
var types = ['spelling_value', 'sensible_value','accent_value', 'sobstven','synonym_value', 'spavochnic','antonym_value', 'examples_value'];
var types_ru=['Орфографический словарь','Толковый словарь','Словарь ударений русского языка','Словарь имен собственных','Словарь синонимов','Словарь методических терминов','Словарь антонимов','Словарь примеров использования'];

int i=0;
class _DictionariesScreenState extends State<DictionariesScreen> {

  bool isAppBarActionsVisible = false;
  List<int> selectedCardIndices = [];

  List<Map<String, dynamic>> words = [];

  int get id => widget.id;


  void initState() {
    super.initState();
    _loadWordsFromDatabase();
    fetchData();
  }

  Future<void> _recre() async {
    await DBHelper.instance.recreateDatabase();
  }
  late List<Map<String, dynamic>> pinnedWords;
  Map<String, List<int>> colorMap={};


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
    setState(() {
      words = [...pinnedWords, ...unpinnedWords];
    });
  }
  void fetchData() async {
   colorMap = await DBHelper.instance.getColorMap(id);

  }
  Color getColorFromString(int id) {
    var hexColor ="ffffff";
    for (var entry in colorMap.entries) {
      if (entry.value.contains(id)) {
        hexColor =  entry.key;
      }
    }
    try{int value = int.parse(hexColor, radix: 16);
    return Color(value).withAlpha(0xFF);}
        catch(e){
          return Colors.white;
        }
  }
  Color getCompliableColor(int id) {

    String color="ffffffff";
    fetchData();
    for (var entry in colorMap.entries) {
      if (entry.value.contains(id)) {
        color =  entry.key;
      }
    }
      switch(color)
          {
        case "ffff5252":
          return RED;
        case "ff00bcd4":
          return BLUE;
        case "ff009688":
          return GREEN;
        case "ffffab40":
          return kBarMenu;
        case "ff7c4dff":
          return VIOLET;
        case "ffffffff":
          return kBarMenu;
          }


      return Colors.black;

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCardColor,
      appBar: AppBar(
        backgroundColor: kButtonColorSearch,
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
            : [IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            _showAddWordWindow(context);
          },
        )],
      ),
      body: words.isNotEmpty?Container(
        color: kCardColor,
      child:ListView.builder(
        itemCount: words.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCardIndices.contains(index);
          bool isPinned = pinnedWords.contains(words[index]);
          Color colorWord;
          return Card(
            color: kCardColor,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.grey.withOpacity(0.3)
                    : (getColorFromString(words[index]['id_word']) ?? Colors.white).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),

              ),
              padding: EdgeInsets.all(4.0),
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
                      words[index]['spelling_value'].length <= 15
                          ? words[index]['spelling_value']
                          : '${words[index]['spelling_value'].substring(0, 15)}...',
                      style: TextStyle(
                        color: getCompliableColor(words[index]['id_word']),
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, color:getCompliableColor(words[index]['id_word'])),
                onTap: () {
                  if (isAppBarActionsVisible) {
                    _toggleSelection(index);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WordScreen(
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
            ),
          );
        },
      ),): Center(
        child: Text(
          'В словаре еще нет слов',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      ),

    );
  }
  void _showAddWordWindow(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWordScreen(), // Предполагается, что AddWordScreen - это новый экран, который вы создадите
      ),
    );
  }
  Map<String, dynamic> _check(index) {
    return words[index];
  }

  void _toggleSelection(int index) {

    setState(() {
      if (selectedCardIndices.contains(index)) {
        selectedCardIndices.remove(index);
        if(selectedCardIndices.isEmpty){
          _resetSelection();}
      } else {
        selectedCardIndices.add(index);
      }


    });
  }

  void _resetSelection() {
    setState(() {
      if (selectedCardIndices.isEmpty) {
        selectedCardIndices = [];
        isAppBarActionsVisible = false;
      }
    });
  }

  Future<void> _deleteSelectedWords() async {

    for (var index in selectedCardIndices) {
      await DBHelper.instance.deleteFromDictionary(
          widget.id, words[index]['id_word']);
    }

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
      var pinStatusResult = await DBHelper.instance.isPinned(widget.id, words[index]['id_word']);
      var isPinned =pinStatusResult.first['is_pinned']==1?0:1;
      await DBHelper.instance.pinWord(widget.id,words[index]['id_word'],isPinned);

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
    await DBHelper.instance.ChangeColor(id, colorString, widget.id);
    fetchData();
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
