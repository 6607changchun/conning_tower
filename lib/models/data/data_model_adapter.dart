
import 'kcsapi/kcsapi.dart';

class DataModelAdapter {
  final Map<String, Function(Map<String, dynamic>)> modelMap;

  DataModelAdapter()
      : modelMap = {
          GetMemberMissionEntity.source: (json) =>
              GetMemberMissionEntity.fromJson(json),
          ReqMissionStartEntity.source: (json) =>
              ReqMissionStartEntity.fromJson(json),
          GetMemberDeckEntity.source: (json) =>
              GetMemberDeckEntity.fromJson(json),
          PortEntity.source: (json) => PortEntity.fromJson(json)
        };

  dynamic parseData(String source, Map<String, dynamic> json) {
    if (modelMap.containsKey(source)) {
      return modelMap[source]!(json);
    }
    return null;
  }
}
