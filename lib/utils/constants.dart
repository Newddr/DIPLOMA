import 'dart:ui';
import 'package:slovar/utils/globals.dart';

final Color kPrimaryColorLight = Color(0xFF28292E);
final Color kPrimaryColorDart = Color(0xfff4f3e6);

// Определяем все цвета вне условного блока
final Color kButtonColorSearchLight = Color(0xfff4f3e6);
final Color kBarMenuLight = Color(0xffA09746);
final Color REDLight = Color(0xffA04646);
final Color BLUERight = Color(0xff46A097);
final Color VIOLETLight = Color(0xff4646A0);
final Color GREENLight = Color(0xff46A074);
final Color PINKEight = Color(0xffB07DB4);
final Color kCardColorLight = Color(0xffffffff);
final Color kButtonColorSearchDARK = Color(0xff5a5757); // Темный вариант f4f3e6
final Color kBarMenuDARK = Color(0xff6b6140); // Темный вариант A09746
final Color REDDARK = Color(0xff691717); // Темный вариант A04646
final Color BLUEDARK = Color(0xff1c4069); // Темный вариант 46A097
final Color VIOLETDARK = Color(0xff2d2d60); // Темный вариант 4646A0
final Color GREENDARK = Color(0xff1c6938); // Темный вариант 46A074
final Color PINKEDARK = Color(0xff7d4d94); // Темный вариант B07DB4
final Color kCardColorDARK = Color(0xff333333);

// Теперь выбираем цвета в зависимости от темы
late Color kButtonColorSearch;
late Color kBarMenu;
late Color RED;
late Color BLUE;
late Color VIOLET;
late Color GREEN;
late Color PINK;
late Color kCardColor;
late Color kPrimaryColor;

void setupColors() {
  if (isDartTheme == false) {
    kPrimaryColor=kPrimaryColorLight;
    kButtonColorSearch = kButtonColorSearchLight;
    kBarMenu = kBarMenuLight;
    RED = REDLight;
    BLUE = BLUERight;
    VIOLET = VIOLETLight;
    GREEN = GREENLight;
    PINK = PINKEight;
    kCardColor = kCardColorLight;
  } else {
    kPrimaryColor=kPrimaryColorDart;
    kButtonColorSearch = kButtonColorSearchDARK;
    kBarMenu = kBarMenuDARK;
    RED = REDDARK;
    BLUE = BLUEDARK;
    VIOLET = VIOLETDARK;
    GREEN = GREENDARK;
    PINK = PINKEDARK;
    kCardColor = kCardColorDARK;
  }
}
