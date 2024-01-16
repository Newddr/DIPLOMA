import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
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
  var types_ru=['Офрфографический словарь','Толковый словарь','Словарь ударений русского языка','Словарь имен собственных','Словарь синонимов','Словарь методических терминов','Словарь антонимов','Словарь примеров использования'];
  var dictionariesID = [];
  String _newDictionaryName ="";

  @override
  void initState() {
    super.initState();
    _loadDictionaries();
    _loadInfoFromBD();
  }

  Future<void> _loadDictionaries() async {
    List<Map<String, dynamic>> dictionariesFromDB =
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
    print('34234234-${dictionariesID}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.0),
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
                    Text(
                      _getValue(types[index]),
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
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
                                _changeStateWord(dictionaryesLocal[index].id)?null:await _addToDic(dictionaryesLocal[index].id,widget.word['id_word']);
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

  Future<void> _addToDic(id,id_word) async {
    await DBHelper.instance.addToDictionary(id, id_word);
    print("ff- $id_word");
    setState(() {
      dictionariesID.add(id);
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



