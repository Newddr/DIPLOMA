import 'package:flutter/material.dart';
import 'DB/DBHelper.dart';
import 'Word_screen.dart';
import 'dictionary_class.dart';
import 'dictionary_screen.dart';
import 'words.dart';

void main() {
  runApp(MyApp());
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
    _loadDictionaries();
    _loadRecentSearch();

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
      _loadDictionaries();// Здесь вы можете обновить переменные состояния или выполнить другие действия при необходимости
    });
  }
  List<Map<String, dynamic>> searchResultsFromDB=[];
  void _performSearch(String query) async {
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
                        _performSearch(query);
                      } else if (_selectedIndex == 2) {
                        _performDictionarySearch(query);
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search",
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
                          return GestureDetector(
                            onTap: () {
                              _onSearchResultTapped(searchResults[index]);
                            },
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

                              onTap: () {
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
  void _onSearchResultTapped(String word) {
    // Добавить выбранный запрос в список последних запросов


    // Остальной код не изменяется
    Map<String, dynamic> selectedWord = searchResultsFromDB.firstWhere(
          (result) => result['name'] == word,
      orElse: () => {'name': 'DefaultWordName'},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordScreen(word: selectedWord),
      ),
    );
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




