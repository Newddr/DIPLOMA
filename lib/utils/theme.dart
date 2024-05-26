

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'constants.dart';

ThemeData appTheme() => ThemeData(
  brightness: Brightness.light,
  primaryColor: kPrimaryColor,
  textTheme: TextTheme(
    titleLarge: TextStyle(
      color: Colors.black
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: kButtonColorSearch
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: kButtonColorSearch
  ),
  iconTheme: IconThemeData(
    color: kButtonColorSearch
  )

);