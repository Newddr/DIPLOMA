import 'dart:convert';
import 'package:windows1251/windows1251.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'DB/DBHelper.dart';
import 'Word_screen.dart';
import 'dictionary_class.dart';
import 'dictionary_screen.dart';
import 'words.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:connectivity/connectivity.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}
void _requestStoragePermission(BuildContext context) async {
  PermissionStatus status = await Permission.storage.status;
  if (!status.isGranted) {
    PermissionStatus result = await Permission.storage.request();
    if (result.isGranted) {
      print('Разрешение выдано');
    } else {
      print('Разрешение не выдано');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Важно'),
            content: Text('Без доступа к файлам, вы не сможете сохранять слова в личный словарь.'),
            actions: [
              TextButton(
                child: Text('Понял'),
                onPressed: () {
                  Navigator.of(context).pop(); // Закрыть диалоговое окно
                },
              ),
            ],
          );
        },
      );
    }
  } else {
    print('Разрешение выдано');
  }
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  List<String> searchResults = [];
  List<Dictionary> dictionaries = [];
  List<Dictionary> dictionariesList5=[];
  List<Map<String, dynamic>> recentSearches = [];
  Map<int, String> countOfWords = {};

  @override
  void initState() {
    super.initState();
    _requestStoragePermission(context);
    _loadDictionaries();
    _loadRecentSearch();

  }
  Future<List<String>> fetchWordsFromGramota(String query) async {
    final Uri uri = Uri.parse('https://gramota.ru/poisk?query=$query*&mode=slovari');
    print("URI= ,$uri");
    final response = await http.get(uri);
    print("response= ,$response");

    if (response.statusCode == 200) {
      // Парсинг HTML
      dom.Document document = parser.parse(response.body);
      List<String> words = [];
      // Находим все элементы <a> с классом "item"
      List<dom.Element> items = document.querySelectorAll('div.item > a');
      // Берем первые 5 слов
      for (int i = 0; i < items.length && i < 5; i++) {
        words.add(items[i].text);
      }
      print("words= ,$words");
      // Возвращаем список слов и вызываем setState
      return words;
    } else {
      throw Exception('Failed to load words from Gramota');
    }
  }
  void _performSearchFromLocal(String query) async {
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    searchResultsFromDB =
    await DBHelper.instance.searchWords(query);
    setState(() {
      searchResults =
          searchResultsFromDB.map<String>((result) => result['name'] as String).toList();
    });
  }
  void _performSearch(String query) async {
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    try {
      // Вызываем функцию fetchWordsFromGramota
      List<String> words = await fetchWordsFromGramota(query);
      // Обновляем состояние виджета
      setState(() {
        if(query.length<4 && words.isEmpty)
          {
            words.clear();
            words.add('Введите еще парочку букв') ;
          }
        else{
          if(query.length>=4 && words.isEmpty){
            words.clear();
            words.add('К сожалению ничего не найдено, но мы обязательно это исправим') ;

          }
        }

          searchResults = words;


      });
    } catch (e) {
      print('Error fetching words: $e');
      // Обработка ошибки, если запрос не удался
      // Можно добавить какую-то логику обработки ошибки
    }
  }
  Future<void> _loadRecentSearch()
  async {
    List<Map<String, dynamic>> recentSearchresult =
    await DBHelper.instance.getWords();
    print('Dics-${recentSearchresult}');

    setState(() {
      recentSearches = recentSearchresult;
    });
    if (recentSearches.length > 10) {
      // Получите последние 5 словарей с конца
      recentSearches = recentSearches.reversed.toList().sublist(0, 10);
    } else {
      recentSearches = recentSearches;
    }
  }
  void updateMainPage() {
    setState(() {
      _loadDictionaries();
      _loadRecentSearch();
    });
  }
  List<Map<String, dynamic>> searchResultsFromDB=[];

  Future<void> _loadDictionaries() async {
    List<Map<String, dynamic>> dictionariesFromDB =
    await DBHelper.instance.getAllDictionaries();
    print('Dics-${dictionariesFromDB}');

    setState(() {
      dictionaries = dictionariesFromDB
          .map((dictionary) => Dictionary(
        id: dictionary['id'],
        value: dictionary['name'],
      ))
          .toList();
    });

    if (dictionaries.length > 5) {
      // Получите последние 5 словарей с конца
      dictionariesList5 = dictionaries.reversed.toList().sublist(0, 5);
    } else {
      dictionariesList5 = dictionaries;
    }
    for (var dic in dictionaries) {
      print('dic1 id=${dic.id}');

      try {
        String count = await getCountofWords(dic.id);
        countOfWords[dic.id]=count;
      } catch (e) {
        print('Error fetching count of words for dictionary with id=${dic.id}: $e');
        countOfWords[dic.id]='Ошибка получения количества слов';
      }

      print('dic id=${dic.id}');
    }
    print(countOfWords);
  }

  void _onItemTapped(int index) {
    updateMainPage();
    setState(() {

      _selectedIndex = index;
      if (_selectedIndex == 1) {
        _clearSearch();
      } else if (_selectedIndex == 2) {
        _performDictionarySearch(_searchController.text);
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchResults = [];
    });
  }

  void _performDictionarySearch(String query) async {
    if (query.isEmpty) {
      // Если запрос пуст, отобразите все словари
      setState(() {
        searchResults = dictionaries.map((d) => d.value).toList();
      });
    } else {
      print("QQ-${query}");
      // Выполните поиск по словарям в базе данных и фильтруйте результаты
      List<String> matchingDictionaries = [];

      for (var dictionary in dictionaries) {
        if (dictionary.value.toLowerCase().startsWith(query.toLowerCase())) {
          matchingDictionaries.add(dictionary.value);
        }
      }
      print("MD-${matchingDictionaries}");
      setState(() {
        searchResults = matchingDictionaries;
      });
    }
    await _loadDictionaries();
  }
  Future<bool> hasInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        _clearSearch();
        _loadDictionaries();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0.0,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 0.0),
          child: Stack(
            alignment: Alignment.topCenter,
            fit: StackFit.expand,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0.0,
                color: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      if (_selectedIndex == 1) {
                        hasInternetConnection()!=false? _performSearch(query): _performSearchFromLocal(query);
                      } else if (_selectedIndex == 2) {
                        _performDictionarySearch(query);
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Поиск",
                      contentPadding: EdgeInsets.all(20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.blue[50],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                bottom: 0,
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: Text('Настройки'),
                      ),
                    ), //Настройки
                    Container(
                      color: Colors.white,
                      child: searchResults.isNotEmpty
                          ? ListView.builder(
                        itemCount: searchResults.length ,
                        itemBuilder: (context, index) {
                          bool isClickable = true;
                          if (searchResults[index] == "К сожалению ничего не найдено, но мы обязательно это исправим" || searchResults[index] == "Введите еще парочку букв") {
                            isClickable = false;
                          }
                          print("searchResults[index] = ${searchResults[index]}");
                          return GestureDetector(
                            onTap: isClickable
                                ? () {
                              _onSearchResultTapped(searchResults[index]);
                            }: null,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: ListTile(
                                title: Text(searchResults[index]),
                              ),
                            ),
                          );
                        },
                      )
                          : ListView(
                        children: <Widget>[
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Последние добавленные слова',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 10.0,
                                    runSpacing: 10.0,
                                    children: recentSearches
                                        .map((search) => GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WordScreen(
                                                  word: search,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Chip(label: Text(search['name'])),
                                    ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _onItemTapped(2);
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Словари',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 10.0,
                                      runSpacing: 10.0,
                                      children: dictionariesList5
                                          .map(
                                            (dictionary) => GestureDetector(
                                              onLongPress: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text('Удалить словарь'),
                                                      content: Text('Вы уверены, что хотите удалить этот словарь?'),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          child: Text('Отмена'),
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                        ),
                                                        TextButton(
                                                          child: Text('Удалить'),
                                                          onPressed: () {
                                                            _deleteDictionary(dictionary.id);
                                                            Navigator.of(context).pop();
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                          onTap: () {
                                            print(
                                                'Pressed on chip with ID: ${dictionary.id}');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DictionariesScreen(
                                                      onClosed: () {
                                                        // Колбэк вызывается при закрытии экрана со словарями
                                                        setState(() {
                                                          // Здесь вы можете обновить переменные состояния или выполнить другие действия
                                                        });
                                                      },updateMainPage: updateMainPage,
                                                      id: dictionary.id,
                                                      value: dictionary.value,
                                                      dictionaries: '',
                                                    ),
                                              ),
                                            );
                                            updateMainPage();
                                          },
                                          child: Chip(
                                            label: Text(dictionary.value),
                                          ),
                                        ),
                                      )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ), //Главная
                    Container(
                      color: Colors.white,
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          // Найдите словарь, соответствующий текущему результату поиска
                          Dictionary currentDictionary = dictionaries.firstWhere(
                                (dictionary) => dictionary.value == searchResults[index],
                            orElse: () => new Dictionary(id: 0, value: 'value'),
                          );

                          if (currentDictionary != null) {
                            return GestureDetector(
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Удалить словарь'),
                                      content: Text('Вы уверены, что хотите удалить этот словарь?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Отмена'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Удалить'),
                                          onPressed: () {
                                            _deleteDictionary(currentDictionary.id);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },

                              onTap:() {
                                print('Pressed on chip with ID: ${currentDictionary.id}');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DictionariesScreen(
                                      onClosed: () {
                                        // Колбэк вызывается при закрытии экрана со словарями
                                        setState(() {
                                          // Здесь вы можете обновить переменные состояния или выполнить другие действия
                                        });
                                      },updateMainPage: updateMainPage,
                                      id: currentDictionary.id,
                                      value: currentDictionary.value,
                                      dictionaries: '',
                                    ),
                                  ),
                                );      updateMainPage();
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        bottom: 5,
                                        top: 5,
                                      ),
                                      child: CircleAvatar(
                                        radius: 30,
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            currentDictionary.value[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          currentDictionary.value,
                                          style: TextStyle(
                                            fontSize: 24,
                                          ),
                                        ),
                                        Text(
                                            countOfWords[currentDictionary.id]!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Spacer(),
                                    Icon(Icons.arrow_forward_ios),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Обработка ситуации, когда словарь не найден
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    ),  //Словари
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Настройки',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Главная страница',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Словари',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Future<List<String>?> _onSearchResultTapped(String word) async {
    // Проверяем, есть ли слово в локальной базе данных
    Map<String, dynamic>? wordInfo = (await DBHelper.instance.getWordInfo(word)) as Map<String, dynamic>?;
print("Нашли ? = $wordInfo");
    if (wordInfo != null) {
      // Если слово найдено в базе данных, выводим информацию из базы данных в карточку
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordScreen(word: wordInfo),
        ),
      );
    } else {
      print('Пока что пусто, но будет парсер!');
      final response = await http.get(Uri.parse('http://classic.gramota.ru/slovari/dic/?word=$word&all=x'));
      print('responce= ${response.statusCode}');
      if (response.statusCode == 200) {
        // Декодируем тело ответа в кодировке windows-1251
        final decodedBody = windows1251.decode(response.bodyBytes);
        final document = parse(decodedBody);

        final definitionsBlocks = document.querySelectorAll('div[style="padding-left:50px"]');
        final definitionsList = definitionsBlocks.map((block) {
          // Инициализируем текст определения
          String definitionsText = block.text;

          // Находим все теги <span class="accent"> внутри тега <b>
          final accentTags = block.querySelectorAll('b > span.accent');
          for (final accentTag in accentTags) {
            // Заменяем текст внутри тега <span class="accent"> на текст с ударением
            definitionsText = definitionsText.replaceFirst(accentTag.text,  "'"+accentTag.text);
          }

          return definitionsText;
        }).toList();

        final createdAt = DateTime.now().toIso8601String();
        var id=await DBHelper.instance.getLastId();
        print(id);
        id ??= 0;
        final Map<String, dynamic> valuesToInsert = {
          'id_word': (id!+1),
          'name': word,
          'created_at': createdAt,
          'is_pinned': 0,
          'color': 'ffffffff',
          'spelling_value': definitionsList[0],
          'sensible_value': definitionsList[1],
          'accent_value': definitionsList[2],
          'sobstven': definitionsList[3],
          'synonym_value': definitionsList[4],
          'spavochnic': definitionsList[5],
          'antonym_value': definitionsList[6],
          'examples_value': definitionsList[7],
          'translate_value': definitionsList[8]
        };

        await DBHelper.instance.addTempWord(valuesToInsert,0);
        // Преобразуем список определений в Map<String, dynamic>
        final definitionsMap = {'$word': definitionsList};
        print('valuesToInsert= $valuesToInsert');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordScreen(word: valuesToInsert),
          ),
        );
        print('definitionsMap: $definitionsMap');
      } else {
        print('Ошибка: Не удалось получить доступ к странице для слова "$word"');
      }





    }

  }

  Future<void> _deleteDictionary(int id) async {
    await DBHelper.instance.DeleteDictionary(id);

    // После удаления словаря, загрузите обновленный список словарей
    await _loadDictionaries();

    // Очистите результаты поиска, чтобы отобразить обновленный список
    _performDictionarySearch('');

    // Вызовите setState для перерисовки виджета
    setState(() {
      // Проверьте, если у вас есть результаты поиска, замените значения в searchResults
      if (searchResults.isNotEmpty) {
        searchResults = dictionaries
            .map((dictionary) => dictionary.value)
            .where((value) => value.isNotEmpty)
            .toList();
      }
    });
  }
  Future<String> getCountofWords(int id) async {
    var a =await DBHelper.instance.getWordsQuery(id);
    var lastDigit = a.length % 10;
if  (lastDigit>=5)return '${a.length} слов';
else if(lastDigit==1)return '${a.length} слово';
    return '${a.length} слова';
  }
}

class BeautifulSoup {
  final String data;

  BeautifulSoup(this.data);

  Iterable<HtmlTag> find_all(String name, {required Map<String, String> attrs}) sync* {
    var regExp = RegExp('<$name.*?>(.*?)</$name>', dotAll: true);
    var matches = regExp.allMatches(data);
    for (var match in matches) {
      var group = match.group(0);
      if (group != null) {
        yield HtmlTag(group);
      }
    }
  }
}
class HtmlTag {
  final String data;

  HtmlTag(this.data);

  String? operator [](String key) {
    var regExp = RegExp('$key="([^"]+)"');
    var match = regExp.firstMatch(data);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  String? get name {
    var regExp = RegExp('<([^\\s>/]+)');
    var match = regExp.firstMatch(data);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  String? get text {
    var regExp = RegExp(r'>([^<>]*)<');
    var match = regExp.firstMatch(data);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  List<HtmlTag> get children {
    var regExp = RegExp(r'>([^<>]*)</');
    var match = regExp.firstMatch(data);
    if (match != null) {
      return [HtmlTag(match.group(1)!)]; // Используйте !, чтобы убедиться, что строка не null
    }
    return [];
  }
}





