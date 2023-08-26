import 'package:conning_tower/models/data/kcwiki/api/kcwiki_api_ship_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'kcwiki_data.freezed.dart';
part 'kcwiki_data.g.dart';

@freezed
class KcwikiData with _$KcwikiData {
  const factory KcwikiData({
    required List<KcwikiApiShipEntity> ships,
  }) = _KcwikiData;

  factory KcwikiData.fromJson(Map<String, dynamic> json) =>
      _$KcwikiDataFromJson(json);
}