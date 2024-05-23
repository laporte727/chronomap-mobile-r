import 'package:flutter/material.dart';
import '../timeline/entry.dart';

//このクラスにはデータしかない。表示機能はSectionにある。

class MenuSectionData {
  late String label;
  final Color textColor = Colors.black;
  final Color backgroundColor = Colors.white;
  List<MenuItemData> items = [];
}

/// Data container for all the sub-elements of the [MenuSection].
/// 表示域を選択するTileに表示するもの
class MenuItemData {
  String label = "";
  double start = 0.0;
  double end = 0.0;
  bool pad = false;
  double padTop = 0.0;
  double padBottom = 0.0;

  MenuItemData();

  /// When initializing this object from a [TimelineEntry], fill in the
  /// fields according to the [entry] provided. The entry in fact specifies
  /// a [label], a [start] and [end] times.
  /// Padding is built depending on the type of the [entry] provided.
  MenuItemData.fromEntry(TimelineEntry entry) {
    label = entry.name;

    /// Pad the edges of the screen.
    pad = true;

    if (entry.type == TimelineEntryType.era) {
      start = entry.start;
      end = entry.end;
    }
  }
}

class MenuData {
  List<MenuSectionData> sections = [];

  void initializeWithDefaultData() {
    List<MenuSectionData> menu = [];
    MenuSectionData menuSection = MenuSectionData();

    menuSection.label = " ";

    // Items
    List<MenuItemData> items = [
      MenuItemData()..label = "Whole Period"..start = -5100000000000..end = 800000,
      MenuItemData()..label = "BCE"..start = -366000..end = 0,
      MenuItemData()..label = "CE"..start = 0..end = 700000,
      MenuItemData()..label = "20th Century"..start = 690000..end = 750000,
      MenuItemData()..label = "21th Century"..start = 730000..end = 800000,
    ];

    menuSection.items = items;
    menu.add(menuSection);

    sections = menu;
  }
}