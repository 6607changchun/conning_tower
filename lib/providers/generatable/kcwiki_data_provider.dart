import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:conning_tower/constants.dart';
import 'package:conning_tower/helper.dart';
import 'package:conning_tower/models/data/kcwiki/kcwiki_data.dart';
import 'package:conning_tower/models/data/kcwiki/ship.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kcwiki_data_provider.g.dart';

@riverpod
class KcwikiDataState extends _$KcwikiDataState {
  Future<File> get _localJsonFile async {
    final path = await localPath;
    return File('$path/providers/kcwiki_data.json');
  }

  @override
  FutureOr<KcwikiData> build() async {
    return _loadData();
  }

  Future<KcwikiData> fetchData() async {
    final json = await http.get(Uri.parse(kKcwikiShipsUrl));
    final shipsJson = jsonDecode(json.body) as List<dynamic>;

    List<Ship> ships = shipsJson.map((json) => Ship.fromJson(json)).toList();
    ships.sort((a, b) => a.id.compareTo(b.id));
    KcwikiData kcwikiData = KcwikiData(ships: ships);
    _saveLocalData(kcwikiData);
    return kcwikiData;
  }

  Future<KcwikiData> _loadData() async {
    try {
      final file = await _localJsonFile;

      String contents = await file.readAsString();

      var json = jsonDecode(contents);

      return KcwikiData.fromJson(json);
    } catch (e) {
      return fetchData();
    }
  }

  Future<void> _saveLocalData(KcwikiData kcwikiData) async {
    final file = await _localJsonFile;

    final directory = file.parent;
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    await file.writeAsString(jsonEncode(kcwikiData.toJson()));
  }

  Future<void> deleteLocalFile() async {
    final file = await _localJsonFile;

    if (file.existsSync()) {
      await file.delete();
    }
  }
}
