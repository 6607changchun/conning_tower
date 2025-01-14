import 'dart:convert';
import 'dart:developer' as dev;

import 'package:conning_tower/generated/l10n.dart';
import 'package:conning_tower/main.dart';
import 'package:conning_tower/models/data/kcwiki/kcwiki_data.dart';
import 'package:conning_tower/models/feature/dashboard/kancolle/data.dart';
import 'package:conning_tower/models/feature/log/kancolle_battle_log.dart';
import 'package:conning_tower/models/feature/log/kancolle_log.dart';
import 'package:conning_tower/objectbox.g.dart';
import 'package:conning_tower/pages/log_pages/log_item.dart';
import 'package:conning_tower/pages/log_viewer.dart';
import 'package:conning_tower/providers/generatable/kcwiki_data_provider.dart';
import 'package:conning_tower/providers/kancolle_data_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class LogDataPage extends ConsumerStatefulWidget {
  final LogType logType;

  LogDataPage.battle({super.key}) : logType = LogType.battle;

  @override
  ConsumerState createState() => _LogDataPageState();
}

class _LogDataPageState extends ConsumerState<LogDataPage> {
  int queryLimit = 20;

  @override
  Widget build(BuildContext context) {
    final runtimeData = ref.watch(kancolleDataProvider);
    final kcWikiData = ref.watch(kcWikiDataStateProvider);


    ScrollController scrollController = ScrollController();

    Box<KancolleLogEntity> dataBox = objectbox.battleLog;

    Query<KancolleLogEntity> query = dataBox
        .query()
        .order(KancolleLogEntity_.id, flags: Order.descending)
        .build();
    query
      ..offset = 0
      ..limit = queryLimit;

    List<KancolleLogEntity> data = query.find();

    debugPrint("num:${data.length}");

    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        bool isTop = scrollController.position.pixels == 0;
        if (isTop) {
          debugPrint('At the top');
        } else {
          setState(() {
            queryLimit += queryLimit;
            data = query.find();
          });
          debugPrint('At the bottom');
        }
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        middle: Text("戦闘"),
        previousPageTitle: S.of(context).KanColleLogbook,
        // trailing: GestureDetector(
        //   onTap: () {
        //
        //   },
        //   child: Icon(
        //     CupertinoIcons.calendar,
        //     color: CupertinoTheme.of(context).textTheme.navActionTextStyle.color,
        //   ),
        // ),
      ),
      child: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            if (runtimeData.dataInfo.mapAreaInfo == null) {
              return kcWikiData.when(data: (kcWikiData) {
                return kcWikiDataBody(scrollController, data, kcWikiData);
              }, error: (error, stackTrace) {
                dev.log(error.toString());
                return runtimeDataBody(scrollController, data, runtimeData);
              }, loading: () => const Center(
                child: CupertinoActivityIndicator(
                  radius: 30,
                ),
              ));
            }

            return runtimeDataBody(scrollController, data, runtimeData);
          }
        ),
      ),
    );
  }

  Widget kcWikiDataBody(ScrollController scrollController, List<KancolleLogEntity> data, KcWikiData kcWikiData) {
    dev.log("use kcwiki data");
    return CupertinoScrollbar(
      controller: scrollController,
      child: ListView(
        controller: scrollController,
        children: [
          if (data.isNotEmpty)
            CupertinoListSection.insetGrouped(
              children: List.generate(data.length, (index) {
                var log = data[index];
                var datetime = tz.TZDateTime.fromMillisecondsSinceEpoch(
                    tz.local, log.timestamp);
                String date = DateFormat.yMMMMd().format(datetime);
                String time = DateFormat('HH:mm:ss').format(datetime);
                final battleData = KancolleBattleLog.fromJson(jsonDecode(log.logStr));
                final map = kcWikiData.maps.firstWhere((element) => element.id == battleData.mapInfo.id);
                String mapName = map.name;
                String mapCode = "${battleData.mapInfo.id ~/ 10}-${battleData.mapInfo.id % 10}";
                return LogItem(
                  log: log,
                  logType: widget.logType,
                  title: Text("$mapCode $mapName"),
                  subtitle: Text('$date $time'),
                  // leading: Text(mapCode),
                  kcWikiData: kcWikiData,
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget runtimeDataBody(ScrollController scrollController, List<KancolleLogEntity> data, KancolleData runtimeData) {
    dev.log("use runtime data");
    return CupertinoScrollbar(
      controller: scrollController,
      child: ListView(
        controller: scrollController,
        children: [
          if (data.isNotEmpty)
            CupertinoListSection.insetGrouped(
              children: List.generate(data.length, (index) {
                var log = data[index];
                var datetime = tz.TZDateTime.fromMillisecondsSinceEpoch(
                    tz.local, log.timestamp);
                String date = DateFormat.yMMMMd().format(datetime);
                String time = DateFormat('HH:mm:ss').format(datetime);
                final battleData = KancolleBattleLog.fromJson(jsonDecode(log.logStr));
                final mapArea = runtimeData.dataInfo.mapAreaInfo?[battleData.mapInfo.id ~/ 10];
                final map = mapArea?.map.firstWhere((element) => element.id == battleData.mapInfo.id);
                String mapName = map?.name ?? '';
                String mapCode = '${map?.areaId}-${map?.num}';


                if (mapName == '') {
                  return LogItem(
                    log: log,
                    logType: widget.logType,
                    title: Text("${battleData.mapInfo.id ~/ 10}-${battleData.mapInfo.id % 10}"),
                    subtitle: Text('$date $time'),
                    onTap: () {
                      Fluttertoast.showToast(msg: "Error: Map not found");
                    },
                  );
                }
                return LogItem(
                  log: log,
                  logType: widget.logType,
                  title: Text("$mapCode $mapName"),
                  subtitle: Text('$date $time'),
                  // leading: Text(mapCode),
                );
              }),
            ),
        ],
      ),
    );
  }
}
