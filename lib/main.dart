import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slovar/utils/constants.dart';
import 'package:slovar/utils/theme.dart';
import 'package:windows1251/windows1251.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'DB/DBHelper.dart';
import 'Word_screen.dart';
import 'dictionary_class.dart';
import 'dictionary_screen.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:connectivity/connectivity.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:slovar/utils/globals.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  isDartTheme=false;
  setupColors();
  runApp(MyApp());

}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme(),
      title: 'Углубленный словарь',
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
  String userAgreement = '';

  final TextEditingController _searchController = TextEditingController();
  List<String> searchResults = [];
  List<Dictionary> dictionaries = [];
  List<Dictionary> dictionariesList5 = [];
  List<Map<String, dynamic>> recentSearches = [];
  Map<int, String> countOfWords = {};

  @override
  void initState() {
    super.initState();
    _loadUserAgreement();
    _checkFirstLaunch();
    hasInternetConnection();
    _loadDictionaries();
    _loadRecentSearch();
    
  }
  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAgreed = prefs.getBool('isAgreed') ?? false;

    if (!isAgreed) {
      _showAgreementDialog();
    }
  }

  void _showAgreementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Пользовательское Соглашение'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(userAgreement),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Не согласен'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
            TextButton(
              child: Text('Согласен'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isAgreed', true);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUserAgreement() async {
    final agreement = await rootBundle.loadString('assets/user_agreement.txt');
    setState(() {
      userAgreement = agreement;
    });
  }


  Future<List<String>> fetchWordsFromGramota(String query) async {
    final Uri uri =
        Uri.parse('https://gramota.ru/poisk?query=$query*&mode=slovari');
    final response = await http.get(uri);

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

    searchResultsFromDB = await DBHelper.instance.searchWords(query);
    setState(() {
      searchResults = searchResultsFromDB
          .map<String>((result) => result['name'] as String)
          .toList();
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
        if (query.length < 4 && words.isEmpty) {
          words.clear();
          words.add('Введите еще парочку букв');
        } else {
          if (query.length >= 4 && words.isEmpty) {
            words.clear();
            words.add(
                'К сожалению ничего не найдено, но мы обязательно это исправим');
          }
        }

        searchResults = words;
      });
    } catch (e) {
      // Обработка ошибки, если запрос не удался
      // Можно добавить какую-то логику обработки ошибки
    }
  }

  Future<void> _loadRecentSearch() async {
    List<Map<String, dynamic>> recentSearchresult =
        await DBHelper.instance.getWords();

    setState(() {
      recentSearches = recentSearchresult;
    });
    if (recentSearches.length > 6) {
      recentSearches = recentSearches.reversed.toList().sublist(0, 6);
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

  List<Map<String, dynamic>> searchResultsFromDB = [];

  Future<void> _loadDictionaries() async {
    List<Map<String, dynamic>> dictionariesFromDB =
        await DBHelper.instance.getAllDictionaries();

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

      try {
        String count = await getCountofWords(dic.id);
        countOfWords[dic.id] = count;
      } catch (e) {
        countOfWords[dic.id] = 'Ошибка получения количества слов';
      }

    }
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
      // Выполните поиск по словарям в базе данных и фильтруйте результаты
      List<String> matchingDictionaries = [];

      for (var dictionary in dictionaries) {
        if (dictionary.value.toLowerCase().startsWith(query.toLowerCase())) {
          matchingDictionaries.add(dictionary.value);
        }
      }
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
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Важно'),
            content: Text(
                'Без доступа к интернету, вы не сможете искать слова в интернете'),
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
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        _clearSearch();
        _loadDictionaries();
        return false;
      },
      child: Scaffold(
        backgroundColor: kCardColor,
        appBar: AppBar(
          backgroundColor: kButtonColorSearch,
          toolbarHeight: 0.0,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 0.0),
          child: Stack(
            alignment: Alignment.topCenter,
            fit: StackFit.expand,
            children: [
              Card(
                color: kCardColor,
                elevation: 0.0,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      if (_selectedIndex == 1) {
                        hasInternetConnection() != false
                            ? _performSearch(query)
                            : _performSearchFromLocal(query);
                      } else if (_selectedIndex == 2) {
                        _performDictionarySearch(query);
                      }
                    },
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: kBarMenu),
                        hintText:_selectedIndex==1? "Поиск слов":"Поиск словаря",
                        hintStyle: TextStyle(color: kBarMenu),
                        contentPadding: EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: kButtonColorSearch,
                        iconColor: kBarMenu),
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
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: ExpansionTile(
                              title: Text('Пользовательское Соглашение'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(userAgreement),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ), //Настройки
                    Container(
                      color: Colors.white,
                      child: searchResults.isNotEmpty
                          ? ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                bool isClickable = true;
                                if (searchResults[index] ==
                                        "К сожалению ничего не найдено, но мы обязательно это исправим" ||
                                    searchResults[index] ==
                                        "Введите еще парочку букв") {
                                  isClickable = false;
                                }
                                return GestureDetector(
                                  onTap: isClickable
                                      ? () {
                                          _onSearchResultTapped(
                                              searchResults[index]);
                                        }
                                      : null,
                                  child: Card(
                                    color: kCardColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(color: kButtonColorSearch, width: 2.0),
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
                                Container(
                                  color: kCardColor,
                                  padding: EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Последние добавленные слова',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      Padding(
                                          padding:
                                              EdgeInsets.only(bottom: 16.0)
                                      ),

                                      recentSearches.isNotEmpty?Wrap(
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
                                                                word: search),
                                                      ),
                                                    );
                                                  },
                                                  child: FractionallySizedBox(
                                                    widthFactor: 0.45,
                                                    // Задаем ширину как 50% от доступного пространства
                                                    child: Chip(
                                                      backgroundColor:
                                                          kCardColor,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        side: BorderSide(
                                                          color: kButtonColorSearch,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10,
                                                        ),
                                                      ),
                                                      label: Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                vertical: 5.0),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Icon(
                                                              Icons.add_circle_outline,
                                                              color: Colors.grey[500],
                                                              size: 28, // Увеличиваем размер иконки
                                                            ),
                                                            SizedBox(width: 15),
                                                            // Добавляем небольшой отступ между иконкой и текстом
                                                            Expanded(
                                                            child:Text(
                                                              search['name'],
                                                              style: TextStyle(fontSize: 18, color: kPrimaryColor),
                                                              overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ):Center(
                                        child: Text(
                                          'Вы еще не добавили ни одного слова',
                                          style: TextStyle(fontSize: 20, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _onItemTapped(2);
                                  },
                                  child: Container(
                                    color: kCardColor,
                                    padding: EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Cловари',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 16.0)),
                                        Wrap(
                                          spacing: 10.0,
                                          runSpacing: 10.0,
                                          children: dictionariesList5
                                              .map(
                                                (dictionary) => GestureDetector(
                                                  onLongPress: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContextcontext) {
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
                                                    Navigator.push(context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            DictionariesScreen(
                                                          onClosed: () {
                                                            setState(() {});
                                                          },
                                                          updateMainPage:
                                                              updateMainPage,
                                                          id: dictionary.id,
                                                          value:
                                                              dictionary.value,
                                                          dictionaries: '',
                                                        ),
                                                      ),
                                                    );
                                                    updateMainPage();
                                                  },
                                                  child: LayoutBuilder(
                                                    builder:
                                                        (context, constraints) {
                                                      // Проверяем, вмещается ли текст в начальную ширину
                                                      TextPainter textPainter =
                                                          TextPainter(
                                                        text: TextSpan(
                                                          text:
                                                              dictionary.value,
                                                          style: TextStyle(
                                                              fontSize: 18,color: kPrimaryColor),
                                                        ),
                                                        maxLines: 1,
                                                        textDirection:TextDirection.ltr,)..layout(maxWidth: constraints.maxWidth *0.45);

                                                      bool fitsInInitialWidth =!textPainter.didExceedMaxLines;

                                                      if (!fitsInInitialWidth) {
                                                        textPainter.layout(maxWidth: constraints.maxWidth *0.9);
                                                        bool
                                                            fitsInIncreasedWidth =!textPainter.didExceedMaxLines;

                                                        return FractionallySizedBox(
                                                          widthFactor:
                                                              fitsInIncreasedWidth? 0.9: 0.45,
                                                          child: Chip(
                                                            backgroundColor:
                                                                kCardColor,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              side: BorderSide(color: kButtonColorSearch),
                                                              borderRadius:
                                                                  BorderRadius.circular(10),
                                                            ),
                                                            label: Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(vertical:5.0),
                                                              child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment.center,
                                                                children: <Widget>[
                                                                  Icon(
                                                                    Icons.bookmark_border,
                                                                    color: Colors.grey[500],
                                                                    size: 28,
                                                                  ),
                                                                  SizedBox(width:15),
                                                                  Expanded(
                                                                    child: Text(
                                                                      dictionary.value,
                                                                      style:
                                                                          TextStyle(fontSize:18,color: kPrimaryColor),
                                                                      overflow:
                                                                          TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return FractionallySizedBox(
                                                          widthFactor: 0.45,
                                                          child: Chip(
                                                            backgroundColor:
                                                                kCardColor,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              side: BorderSide(
                                                                  color: kButtonColorSearch),
                                                              borderRadius:
                                                                  BorderRadius.circular(10),
                                                            ),
                                                            label: Padding(
                                                              padding: EdgeInsets.symmetric(vertical: 5.0),
                                                              child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment.center,
                                                                children: <Widget>[
                                                                  Icon(
                                                                    Icons.bookmark_border,
                                                                    color: Colors.grey[500],
                                                                    size: 28,
                                                                  ),
                                                                  SizedBox(width:15),
                                                                  Expanded(
                                                                    child: Text(
                                                                      dictionary.value,
                                                                      style:
                                                                          TextStyle(fontSize:18,color: kPrimaryColor),
                                                                      overflow:
                                                                          TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ), //Главная
                    Container(
                      color: kCardColor,
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
// Найдите словарь, соответствующий текущему результату поиска
                          Dictionary currentDictionary =
                              dictionaries.firstWhere(
                            (dictionary) =>
                                dictionary.value == searchResults[index],
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
                                      content: Text(
                                          'Вы уверены, что хотите удалить этот словарь?'),
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
                                            _deleteDictionary(
                                                currentDictionary.id);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onTap: () {
                               Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DictionariesScreen(
                                      onClosed: () {
                                        setState(() {});
                                      },
                                      updateMainPage: updateMainPage,
                                      id: currentDictionary.id,
                                      value: currentDictionary.value,
                                      dictionaries: '',
                                    ),
                                  ),
                                );
                                updateMainPage();
                              },
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: kCardColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currentDictionary.value,
                                              style: TextStyle(
                                                fontSize: 24,

                                                color: kPrimaryColor
                                              ),
                                            ),
                                            Text(
                                              "Cлов в словаре: " +
                                                  countOfWords[
                                                      currentDictionary.id]!,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: kBarMenu,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: kButtonColorSearch),
                                      ),
                                      child: Center(
                                        child: Text(
                                          currentDictionary.value[0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: kBarMenu,
                                          ),
                                        ),
                                      ),
                                    ),
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
                    ),
//Словари
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: kButtonColorSearch,
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
          selectedItemColor: kBarMenu,
          // Установка цвета выбранных элементов
          unselectedItemColor: Colors.grey,
        ),
      ),
    );
  }

  Future<List<String>?> _onSearchResultTapped(String word) async {
// Проверяем, есть ли слово в локальной базе данных
    Map<String, dynamic>? wordInfo =
        (await DBHelper.instance.getWordInfo(word)) as Map<String, dynamic>?;
    if (wordInfo != null) {
// Если слово найдено в базе данных, выводим информацию из базы данных в карточку
// Если слово найдено в базе данных, выводим информацию из базы данных в карточку
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordScreen(word: wordInfo),
        ),
      );
    } else {
      final response = await http.get(
          Uri.parse('http://classic.gramota.ru/slovari/dic/?word=$word&all=x'));
      if (response.statusCode == 200) {
// Декодируем тело ответа в кодировке windows-1251
        final decodedBody = windows1251.decode(response.bodyBytes);
        final document = parse(decodedBody);

        final definitionsBlocks =
            document.querySelectorAll('div[style="padding-left:50px"]');

        final definitionsList = definitionsBlocks.map((block) {
// Инициализируем текст определения
          String definitionsText = block.outerHtml;

// Заменяем теги <span class="accent"> на апостроф, а остальные теги <span> удаляем
          definitionsText = definitionsText.replaceAllMapped(
            RegExp(r'<span class="accent">([^<]+)</span>'),
            (match) => "'${match.group(1)}",
          );
          definitionsText =
              definitionsText.replaceAll(RegExp(r'<span[^>]*>'), '');
          definitionsText = definitionsText.replaceAll(RegExp(r'</span>'), '');

// Преобразуем HTML в текст
          definitionsText = parse(definitionsText).body!.text;
          return definitionsText;
        }).toList();

        final createdAt = DateTime.now().toIso8601String();
        var id = await DBHelper.instance.getLastId();
        id ??= 0;
        final Map<String, dynamic> valuesToInsert = {
          'id_word': (id! + 1),
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

        await DBHelper.instance.addTempWord(valuesToInsert, 0);
// Преобразуем список определений в Map<String, dynamic>
        final definitionsMap = {'$word': definitionsList};

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordScreen(word: valuesToInsert),
          ),
        );
      } else {
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
    var a = await DBHelper.instance.getWordsQuery(id);
    return '${a.length}';
  }

}



class BeautifulSoup {
  final String data;

  BeautifulSoup(this.data);

  Iterable<HtmlTag> find_all(String name,
      {required Map<String, String> attrs}) sync* {
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
      return [
        HtmlTag(match.group(1)!)
      ]; // Используйте !, чтобы убедиться, что строка не null
    }
    return [];
  }
}
