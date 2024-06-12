import 'package:acorn_client/acorn_client.dart';
import 'package:flutter/material.dart';
import '../serverpod_client.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DataRepository with ChangeNotifier {
  List<Japanese> japaneseList = [];

  Future<void> fetchAllJapaneseNames() async {
    try {
      japaneseList = await client.japanese.getAllJapaneseNames();
    } catch (e) {
      debugPrint('Failed to fetch Japanese names: $e');
    }
    notifyListeners();
  }

  String getJapaneseName(int principalId) {
    var japanese = japaneseList.firstWhere(
          (item) => item.principalId == principalId,
      orElse: () => Japanese(principalId: principalId, japaneseName: 'N/A'),
    );
    return japanese.japaneseName;
  }

  bool isJapaneseLanguage(BuildContext context) {
    var locale = AppLocalizations.of(context);
    if (locale == null) {
      debugPrint('AppLocalizations.of(context) returned null');
      return false;
    }
    return locale.localeName == 'ja';
  }
}
