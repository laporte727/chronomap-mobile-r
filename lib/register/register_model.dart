import 'dart:math';
import 'package:acorn_client/acorn_client.dart';
import 'package:chronomap_mobile/register/register_page.dart';
import 'package:flutter/material.dart';
import '../serverpod_client.dart';
import '../utils/countries_list.dart';
import '../utils/period_list.dart';

class RegisterModel extends ChangeNotifier {
  TextEditingController yearController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController dayController = TextEditingController();
  TextEditingController nameController = TextEditingController();


  double log10(num x) => log(x) / ln10;

  var newYearD = 0.0; //変換用の年
  var newYearI = 0; //入力された年
  var newAnnee = ''; //時代を含む年
  var newMonth = 0; //入力された月
  var newDay = 0; //入力された日
  late int newPoint; //時間軸point
  late double newLogarithm; //2100年基点対数
  late double newCoefficient; //座標係数
  var newName = ''; //事象名
  var calendarNo = 0; //時代コード

  List<String> periods = epoch; //時代選択肢

  List<String> options = [];

  RegisterModel() {
    getOptions();
  }

  void getOptions() {
    for (var country in countries) {
      options.add(country['name']);
    }
  }

  String selectedCountry = "";
  double latitude = 0.0;
  double longitude = 0.0;
  double x3d = 0.0;
  double y3d = 0.0;
  double z3d = 0.0;

  void setSelectedCountry(String country) {
    selectedCountry = country;
    var selectedData = countries.firstWhere((item) => item['name'] == country);
    latitude = double.parse(selectedData['lat']);
    longitude = double.parse(selectedData['lon']);
    x3d = double.parse(selectedData['3dx']);
    y3d = double.parse(selectedData['3dy']);
    z3d = double.parse(selectedData['3dz']);

    notifyListeners();
  }

  setNewName(text) {
    newName = text;
    notifyListeners();
  }

  ///DropdownButton
  String selectedCalendar = 'Common-Era';

  void setCalendar(String? value) {
    if (value != null) {
      selectedCalendar = value;
    }
    notifyListeners();
  }

  setNewYearD(value) {
    newYearD = double.parse(value);
    notifyListeners();
  }

  setNewMonth(value) {
    try {
      newMonth = int.parse(value);
    } catch (e) {
      newMonth = 0;
    }
    notifyListeners();
  }

  setNewDay(value) {
    try {
      newDay = int.parse(value);
    } catch (e) {
      newDay = 0;
    }
    notifyListeners();
  }

  void convertPoint() {
    /// convert the years depending on the selected calendar period
    switch (selectedCalendar) {
      case 'Billion Years':
        newYearI = (newYearD * 1000000000).round();
        newYearI = -newYearI.abs();
        break;
      case 'Million Years':
        newYearI = (newYearD * 1000000).round();
        newYearI = -newYearI.abs();
        break;
      case 'Thousand Years':
        newYearI = (newYearD * 1000).round();
        newYearI = -newYearI.abs();
        break;
      case 'Years by Dating Methods':
        newYearI = (2000 - newYearD).round();
        break;
      case 'Before-CommonEra':
        newYearI = (newYearD).round();
        newYearI = -newYearI.abs();
        break;
      case 'Common-Era':
        newYearI = (newYearD).round();
        break;
    }

    ///make data of point
    newPoint =
        (((newYearI - 1) * 366 + (newMonth - 1) * 30.5 + newDay)
            .toDouble())
            .round();

    ///make data of logarithm
    newLogarithm = double.parse(
        (5885.0 - (1000 * (log10((newPoint - 768600).abs()))))
            .toStringAsFixed(4));

    ///make data of reverseLogarithm
    newCoefficient = 6820.0 + newLogarithm;

    switch (selectedCalendar) {
      case 'Billion Years':
        newAnnee = '${newYearD}B years ago';
        break;
      case 'Million Years':
        newAnnee = '${newYearD}M years ago';
        break;
      case 'Thousand Years':
        newAnnee = '${newYearD}K years ago';
        break;
      case 'Years by Dating Methods':
        newAnnee = 'about $newYearD years ago';
        break;
      case 'Before-CommonEra':
        newAnnee = 'BCE ${(newYearD).round()}';
        break;
      case 'Common-Era':
        newAnnee = 'CE ${(newYearD).round()}';
        break;
    }
  }

  Future<int> save() async {
    if (newYearI != 0 && newName != "" && selectedCountry != "") {
      try {
        var principal = Principal(
          period: selectedCalendar,
          annee: newAnnee,
          month: newMonth,
          day: newDay,
          point: newPoint,
          affair: newName,
          location: selectedCountry,
          precise: " ",
        );
        var principalId = await client.principal.addPrincipal(principal);

        //with Map
        var withMap = WithMap(
            principalId: principalId,
            annee: newAnnee,
            affair: newName,
            location: selectedCountry,
            precise: " ",
            latitude: latitude,
            longitude: longitude,
            logarithm: newLogarithm);
        await client.withMap.addWithMap(withMap);

        //with Globe
        var withGlobe = WithGlobe(
            principalId: principalId,
            annee: newAnnee,
            affair: newName,
            location: selectedCountry,
            precise: " ",
            xCoordinate: x3d * newCoefficient,
            yCoordinate: y3d * newCoefficient,
            zCoordinate: z3d * newCoefficient,
            coefficient: newCoefficient);
        await client.withGlobe.addWithGlobe(withGlobe);

        return 0;

      } catch (e) {
        return 1;
      }
    } else {
      return 2;
    }
  }

  void showCustomDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            GestureDetector(
              child: const Text('OK'),
              onTap: () {
                Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                ); // ダイアログを閉じる
              },
            ),
          ],
        );
      },
    );
  }
}