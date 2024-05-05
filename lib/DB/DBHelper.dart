import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
class DBHelper {
  static final String dbName = "Diction";
  static final int dbVersion = 6;

  DBHelper._(); // private constructor to prevent instantiation

  static final DBHelper instance = DBHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), dbName);
    return await openDatabase(path, version: dbVersion, onCreate: _onCreate);
  }


  Future<void> _onCreate(Database db, int version) async {
    try {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS InfoAboutWord (
        id_word INTEGER PRIMARY KEY,
        name TEXT,
        created_at TEXT,
        is_pinned INTEGER,
        color TEXT,
        spelling_value TEXT,
        sensible_value TEXT,
        synonym_value TEXT,
        antonym_value TEXT,
        accent_value TEXT,
        methodical_value TEXT,
        examples_value TEXT,
        translate_value TEXT
      )
    ''');
    await db.execute('''CREATE TABLE IF NOT EXISTS Dictionaryes (
      id INTEGER PRIMARY KEY,
      name TEXT
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS DictionaryesWords (
      id INTEGER,
      id_word INTEGER
    )''');
  }catch (e) {
  print('Error during database creation: $e');
  }
  }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS InfoAboutWord');
    await db.execute('DROP TABLE IF EXISTS Dictionaryes');
    await db.execute('DROP TABLE IF EXISTS DictionaryesWords');
    await _onCreate(db, newVersion);
  }

  // Method to clear the "InfoAboutWord" table
  Future<void> clearInfoAboutWordTable() async {
    final db = await instance.database;
    await db.delete('InfoAboutWord');
  }

  // Method to delete a word from the "InfoAboutWord" table by ID
  Future<void> deleteWordById(int id) async {
    final db = await instance.database;
    await db.delete('InfoAboutWord', where: 'id_word = ?', whereArgs: [id]);
  }

  Future<void> insertDictionary(Map<String, dynamic> dictionaryData) async {
    final db = await instance.database;
    await db.insert('Dictionaryes', dictionaryData, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<void> insertLink(Map<String, dynamic> linkData) async {
    final db = await instance.database;
    await db.insert('DictionaryesWords', linkData, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<void> insertWord(Map<String, dynamic> wordData) async {
    final db = await instance.database;
    await db.insert('InfoAboutWord', wordData, conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<List<Map<String, dynamic>>> getWords() async {
    final db = await instance.database;
    return await db.query('InfoAboutWord');

  }
  Future<List<Map<String, dynamic>>> getAllDictionaries() async {
    print('ffof');
    final db = await instance.database;
    return await db.query('Dictionaryes');

  }

  Future<List<Map<String, dynamic>>> getWordsQuery(int dictionaryId) async {
    final db = await instance.database;
    return await db.rawQuery('''
    SELECT i.*
    FROM InfoAboutWord i
    JOIN DictionaryesWords d ON i.id_word = d.id_word
    WHERE d.id = $dictionaryId
  ''');

  }
  Future<List<Map<String, dynamic>>> searchWords(String query) async {
    final db = await instance.database;
    print("fff");
    var a = await db.query('InfoAboutWord', where: 'name LIKE ?', whereArgs: ['$query%']);
    print('jg-${a}');

    return a;
  }

  Future<List<Map<String, dynamic>>>  searchDictionaries(String query)
    async {
      final db = await instance.database;
      print("query-");
      print(query);
      var a =await db.query('Dictionaryes', where: 'name LIKE ?', whereArgs: ['%$query%']);
      print("a-");
      print(a);

      return a;

    }


  Future<void> recreateDatabase() async {
    final db = await instance.database;

    // Drop existing tables
    await _dropTables(db);

    // Recreate tables
    await _onCreate(db, dbVersion);

  }

  Future<void> _dropTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS InfoAboutWord');
    await db.execute('DROP TABLE IF EXISTS Dictionaryes');
    await db.execute('DROP TABLE IF EXISTS DictionaryesWords');

  }
  Future<List<Map<String, dynamic>>> executeRawQuery(String rawQuery) async {
    final db = await instance.database;
    assert(db != null, "Database is not initialized!");
    return await db!.rawQuery(rawQuery);

  }


  Future<void> DeleteDictionary(int id) async {
    final db = await instance.database;
    print("DELETED");
    print(await db.delete('Dictionaryes', where: 'id = ?', whereArgs: [id]));
    await db.delete('DictionaryesWords', where: 'id = ?', whereArgs: [id]);
  }
  Future<void> ChangeColor(int id, String newColor) async {
    final db = await instance.database;
    print('ID_WORD=${id}');
    print("TRY COLOR ${await db.update(
      'InfoAboutWord',
      {'color': newColor},
      where: 'id_word = ?',
      whereArgs: [id],
    )}");
    print("COLORED to ${newColor}");
  }
  Future<void> pinWord(int idWord,int pinStat) async {
    final db = await instance.database;
    await db.update(
      'InfoAboutWord',
      {'is_pinned': pinStat}, // 1 - значит, что слово закреплено, вы можете использовать любые значения для представления статуса
      where: 'id_word = ?',
      whereArgs: [idWord],
    );
  }


  Future<List<Map<String, Object?>>> getAllDictionariesContainWord(id) async{
    final db = await instance.database;
    var a =await db.rawQuery ('Select id from DictionaryesWords Where id_word = $id');
    print('a---$a');
    return a;
  }
  Future<void> addToDictionary(int id, int idWord) async {
    final db = await instance.database;
  print('id word = $id and idWord = $idWord');
    var a= await db.insert(
      'DictionaryesWords',
      {'id': id, 'id_word': idWord},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('result=$a');
  }
  Future<void> addDictionaryToDB(String name,id_word) async {
    final db = await instance.database;
    var id = DateTime.now().millisecondsSinceEpoch; // генерируем уникальный идентификатор
    print('id=$id');
    var a = await db.insert(
      'Dictionaryes',
      {'id': id, 'name': name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    //addToDictionary(id, id_word);
    print('result=$a');
  }
  Future<void> deleteFromDictionary(int id, int idWord) async {
    final db = await instance.database;

    var a = await db.delete(
      'DictionaryesWords',
      where: 'id = ? AND id_word = ?',
      whereArgs: [id, idWord],
    );
    print('deletStatus=$a');
  }



  Future<Map<String, dynamic>?> getWordInfo(String word) async {
    print('Searching for word: $word');
    final db = await instance.database;
    var resultSet = await db.query('InfoAboutWord', where: 'LOWER(name) = ?', whereArgs: [word.toLowerCase()]);
    if (resultSet.isNotEmpty) {
      return resultSet.first;
    } else {
      return null;
    }
  }
  Future<void> addTempWord(valuesToInsert, addToMain) async {
    final db = await instance.database;
    var table=addToMain==0?'tempWords':'InfoAboutWord';
    await db.execute('''CREATE TABLE IF NOT EXISTS $table (
     id_word INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          created_at TEXT,
          is_pinned INTEGER,
          color TEXT,
          spelling_value TEXT,
          sensible_value TEXT,
          accent_value TEXT,
          sobstven TEXT,
          synonym_value TEXT,
          spavochnic TEXT,
          antonym_value TEXT,
          examples_value TEXT,
          translate_value TEXT
    )''');
    Map<String, dynamic>? wordInfo = await getWordInfo(valuesToInsert['name']);

    // Проверяем, что слово не найдено, прежде чем вставлять его
    if (wordInfo == null) {
     await db.insert(table,
      {'id_word': valuesToInsert['id_word'], 'name': valuesToInsert['name'],'created_at' :valuesToInsert['created_at'] ,
        'is_pinned':valuesToInsert['is_pinned'],
        'color':valuesToInsert['color'],
        'spelling_value':valuesToInsert['spelling_value'],
        'sensible_value':valuesToInsert['sensible_value'],
        'accent_value':valuesToInsert['accent_value'],
        'sobstven':valuesToInsert['sobstven'],
        'synonym_value':valuesToInsert['synonym_value'],
        'spavochnic':valuesToInsert['spavochnic'],
        'antonym_value':valuesToInsert['antonym_value'],
        'examples_value':valuesToInsert['examples_value'],
        'translate_value':valuesToInsert['translate_value']},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );}


  }

  Future<int?> getLastId() async {
    final db = await instance.database;
    var resultSet = await db.rawQuery('SELECT MAX(id_word) AS max_id FROM InfoAboutWord');
    int? id_max=0;
    if (resultSet.isNotEmpty ) {

      id_max = resultSet.first['max_id'] as int?;
    }
    var tableExistsResult = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table" AND name="tempWords"');
    if (tableExistsResult.isNotEmpty) {
      var resultSet1 = await db.rawQuery(
          'SELECT MAX(id_word) AS max_id FROM tempWords');
      print('isnull=$resultSet1');
      if(resultSet1.first['max_id'] != null)
        {
          if(resultSet1.first['max_id'] as int > id_max!){
            id_max=resultSet1.first['max_id'] as int?;
        }

      }
      if(resultSet.isEmpty && resultSet1.isEmpty)
      {
        return 0;
      }
    }
    else{
      if(resultSet.isEmpty)
      {
        return 0;
      }

    }
    return id_max;
  }







// Простой класс для анализа HTML





// String GetWord(index) {
  //   _loadWordsFromDatabase(index);
  //   return words[index]['text'];
  // }

  // Future<void> _loadWordsFromDatabase(int? dictionaryId) async {
  //   List<Map<String, dynamic>> wordRecords = dictionaryId != null
  //       ? await DBHelper.instance.getWordsQuery(dictionaryId)
  //       : await DBHelper.instance.getWords();
  //
  //
  //     words = wordRecords.map((record) {
  //       return {
  //         'text': record['name'],
  //         'description': record['spelling_value'],
  //         'isPinned': record['is_pinned'] == 1,
  //         'color': record['color'],
  //       };
  //     }).toList();
  //
  }

