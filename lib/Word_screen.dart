import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:slovar/utils/constants.dart';
import 'dictionary_class.dart';
import 'DB/DBHelper.dart';





class WordScreen extends StatefulWidget {
  final Map<String, dynamic> word;


  WordScreen({required this.word});

  @override
  _WordScreenState createState() => _WordScreenState();


}

class _WordScreenState extends State<WordScreen> {
  bool firstLoad = true;
  var dictionaryesLocal = [];
  var types = ['spelling_value', 'sensible_value','accent_value', 'sobstven','synonym_value', 'spavochnic','antonym_value', 'examples_value'];
  var types_ru=['Орфографический словарь','Толковый словарь','Словарь ударений русского языка','Словарь имен собственных','Словарь синонимов','Словарь методических терминов','Словарь антонимов','Словарь примеров использования'];
  var dictionariesID = [];
  var definitions = [];
  String _newDictionaryName ="";

  @override
  void initState() {
    super.initState();
    _loadDictionaries();
    _loadInfoFromBD();
  }
  late List<Map<String, dynamic>> dictionariesFromDB;
  Future<void> _loadDictionaries() async {
    dictionariesFromDB =
    await DBHelper.instance.getAllDictionaries();
    print('Dics-${dictionariesFromDB}');

    setState(() {
      dictionaryesLocal = dictionariesFromDB
          .map((dictionary) => Dictionary(
        id: dictionary['id'],
        value: dictionary['name'],
      )).toList();
    });
  }

  Future<void> _loadInfoFromBD() async {
    print('ID-${widget.word['id_word']}');
    var indexesFromDB = (await DBHelper.instance.getAllDictionariesContainWord(widget.word['id_word']));
    print('Indexes: ${indexesFromDB}');
    setState(() {
      dictionariesID = indexesFromDB
          .map((map) => map['id'] as int)
          .toList();
    });
    types.forEach((type) {
      String definition = _getValue(type);
      definitions.add(definition);
    });
    print('34234234-${dictionariesID}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kButtonColorSearch,
          title: Text(widget.word['name']),
          actions: [
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: () {
                _addToDictionaryes(context);
              },
            ),
          ]),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: List.generate(types.length, (index) {

            return Card(
              color: kCardColor,
              elevation: 0,
                key: ValueKey(index),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: kButtonColorSearch, // Цвет обводки
                  width: 2, // Ширина обводки
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: InkWell(
                  onLongPress: () {
                    _showEditDefinitionModal(types[index]);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        types_ru[index],
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(padding: EdgeInsets.all(10.0)),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 14.0, color: Colors.black),
                          children: processString(definitions[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  List<TextSpan> processString(String input) {
    final spans = <TextSpan>[];
    bool isNextCharRed = false;

    for (int i = 0; i < input.length; i++) {
      if (input[i] == "'") {
        isNextCharRed = true;
      } else {
        spans.add(TextSpan(
          text: input[i],
          style: TextStyle(color: isNextCharRed ? Colors.red : Colors.black),
        ));
        isNextCharRed = false;
      }
    }

    return spans;
  }
  Future<void> _showEditDefinitionModal(dictionaryType) async {
    print('dictionaryType= $dictionaryType');
    final TextEditingController _textController = TextEditingController(text: _getValue(dictionaryType) ); // добавлен предустановленный текст

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // пользователь должен нажать кнопку, чтобы закрыть модальное окно
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактировать определение'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _textController,
                  maxLines: 8, // позволяет неограниченное количество строк
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Введите новое определение',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Сохранить'),
              onPressed: ()
              async {
                String newDefinition = _textController.text;
                await _updateDefinition(dictionaryType,newDefinition);
                setState(() {
                });
                Navigator.of(context).pop();
            },
            ),
          ],
        );
      },
    );

  }




  String _getValue(String type) {
    return widget.word[type] != null ? widget.word[type] : 'none';
  }

  void _addToDictionaryes(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 4.0, // Толщина линии
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.black, // Цвет линии
                  borderRadius: BorderRadius.circular(2.0), // Скругленные углы
                ),
                margin: EdgeInsets.symmetric(vertical: 10.0),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Выберите словарь для добавления',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child:ListView.builder(
                  itemCount: dictionaryesLocal.length + 1, // добавляем +1 чтобы учесть новый элемент
                  itemBuilder: (context, index) {
                    if (index == 0) { // новый элемент
                      return ListTile(
                        title: Text('Создать словарь'),
                        leading: Icon(Icons.add),
                        onTap: () async {
                          await _createNewDictionary(context);
                          setState(() {});
                        },
                      );
                    } else {
                      index -= 1; // корректируем индекс, чтобы он соответствовал списку словарей
                      return Column(
                        children: [
                          ListTile(
                            title: Text(dictionaryesLocal[index].value),
                            trailing: InkWell(
                              onTap: () async{
                                _changeStateWord(dictionaryesLocal[index].id)?null:await _addToDic(dictionaryesLocal[index].id,widget);
                                setState(() {});
                              },
                              child: _changeStateWord(dictionaryesLocal[index].id)
                                  ? Icon(Icons.check, color: Colors.green) // Иконка галочки
                                  : Icon(Icons.add), // Иконка плюса
                            ),
                          ),
                          if (index < dictionaryesLocal.length - 1)
                            Divider(
                              thickness: 1.0, // толщина линии
                              height: 1.0, // расстояние от линии к тексту
                            ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
        );}
    );
  }

  Future<void> _addToDic(id,word) async {
    var id_word =word.word['id_word'];
    await DBHelper.instance.addToDictionary(id, id_word);
    await DBHelper.instance.addTempWord(word.word,1);
    print("ff- $id_word");
    setState(() {
      dictionariesID.add(id);
    });
  }
  Future<void> _updateDefinition(dictionary,newDefinition) async {
    await DBHelper.instance.updateDefinition(widget.word['id_word'],dictionary, newDefinition);

    setState(() {
      int indDict=types.indexOf(dictionary);
      definitions[indDict]=newDefinition;
    });
    }

  Future<void> _createNewDictionary(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Название словаря',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _newDictionaryName = value;
                          });
                        },
                      ),
                    ),
                    ElevatedButton(
                      child: Text('Создать'),
                      onPressed: () {
                        _addDictionary(_newDictionaryName,widget.word['id_word']);
                        Navigator.of(context).pop(); // закрываем диалоговое окно
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  Future<void> _addDictionary(String name,id_word) async {
    await DBHelper.instance.addDictionaryToDB(name,id_word);
    _loadDictionaries();
    setState(() {

    });

    print("ff- $name");

  }


  bool _changeStateWord(int dictionaryId) {
    print('1------${dictionariesID} ---- 2 -----${dictionaryId}');
    return dictionariesID.contains(dictionaryId);
  }
}



