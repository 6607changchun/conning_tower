import 'package:conning_tower/generated/l10n.dart';
import 'package:conning_tower/models/feature/dashboard/kancolle/ship.dart';
import 'package:conning_tower/providers/kancolle_data_provider.dart';
import 'package:conning_tower/widgets/input_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class SquadInfo extends ConsumerStatefulWidget {
  const SquadInfo({super.key});

  @override
  ConsumerState createState() => _SquadInfoState();
}

class _SquadInfoState extends ConsumerState<SquadInfo> {
  int _selectedSegment = 0;

  late int _selectedShip;
  bool _showShipInfo = false;

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(initialPage: _selectedSegment);
    var data = ref.watch(kancolleDataProvider);
    var squads = data.squads;
    Map<int, Widget> segments = {
      0: const Text("1"),
      1: const Text("2"),
      2: const Text("3"),
      3: const Text("4")
    };
    for (var element in squads) {
      segments.update(squads.indexOf(element), (value) => Text(element.name,style: TextStyle(fontSize: 14),));
    }

    Widget body = CupertinoListSection.insetGrouped(
      children: const [
        CupertinoListTile.notched(
          title: Text("N/A"),
        ),
      ],
    );

    List<Widget> pages = <Widget>[body, body, body, body];

    for (int index = 0; index < squads.length; index++) {
      var squad = squads[index];
      if (squad.ships.isNotEmpty) {
        pages[index] = ScrollViewPageWithScrollbar(
          child: CupertinoListSection.insetGrouped(
            children: List.generate(
              squad.ships.length,
              (_index) => CupertinoListTile(
                title: Text(squad.ships[_index].name),
                onTap: () {
                  setState(() {
                    _selectedShip = _index;
                    _showShipInfo = true;
                  });
                },
                additionalInfo: SizedBox(
                  width: 70,
                    child: Text("${squad.ships[_index].nowHP}/${squad.ships[_index].maxHP}", textAlign: TextAlign.end,)),
                subtitle: LinearPercentIndicator(
                  backgroundColor: CupertinoColors.systemGroupedBackground,
                  animation: true,
                  animationDuration: 500,
                  animateFromLastPercent: true,
                  lineHeight: 5.0,
                  percent: squad.ships[_index].nowHP / squad.ships[_index].maxHP,
                  progressColor: squad.ships[_index].damageColor,
                ),
                trailing: CircularPercentIndicator(
                  backgroundColor: CupertinoColors.systemGroupedBackground,
                  reverse: true,
                  radius: 12.0,
                  lineWidth: 5.0,
                  animation: true,
                  animationDuration: 500,
                  animateFromLastPercent: true,
                  percent: squad.ships[_index].condition! / 100,
                  // center: Text('${squad.ships[_index].condition}', style: TextStyle(fontSize: 8),),
                  progressColor: squad.ships[_index].sparkColor,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (_showShipInfo) {
      var ship = squads[_selectedSegment].ships[_selectedShip];
      body = CupertinoListSection.insetGrouped(
        header: CupertinoListSectionDescription(ship.name),
        children: [
          CupertinoListTile(
            title: Text("Lv"),
            additionalInfo: Text('${ship.level}'),
          ),
          CupertinoListTile(
            title: Text("Lv. up EXP"),
            additionalInfo: Text('${ship.exp[1]}'),
          ),
          CupertinoListTile(
            title: Text("疲労度"),
            additionalInfo: Text('${ship.condition}'),
          ),
          CupertinoListTile(
            title: Text("損傷"),
            additionalInfo: Text(ship.damageLevel),
          ),
          CupertinoListTile(
            title: Text("速力"),
            additionalInfo: Text(ship.speedLevel),
          ),
          CupertinoListTile(
            title: Text("火力"),
            additionalInfo: Text('${ship.attack?[0]}/${ship.attack?[1]}'),
          ),
          CupertinoListTile(
            title: Text("雷装"),
            additionalInfo: Text('${ship.attackT?[0]}/${ship.attackT?[1]}'),
          ),
          CupertinoListTile(
            title: Text("対空"),
            additionalInfo: Text('${ship.antiAircraft?[0]}/${ship.antiAircraft?[1]}'),
          ),
          CupertinoListTile(
            title: Text("装甲"),
            additionalInfo: Text('${ship.armor?[0]}/${ship.armor?[1]}'),
          ),
          CupertinoListTile(
            title: Text("回避"),
            additionalInfo: Text('${ship.evasion?[0]}/${ship.evasion?[1]}'),
          ),
          CupertinoListTile(
            title: Text("対潜"),
            additionalInfo: Text('${ship.antiSubmarine?[0]}/${ship.antiSubmarine?[1]}'),
          ),
          CupertinoListTile(
            title: Text("索敵"),
            additionalInfo: Text('${ship.scout?[0]}/${ship.scout?[1]}'),
          ),
          CupertinoListTile(
            title: Text("射程"),
            additionalInfo: Text(ship.attackRangeLevel),
          ),
          CupertinoListTile(
            title: Text("運"),
            additionalInfo: Text('${ship.luck?[0]}/${ship.luck?[1]}'),
          ),
          CupertinoListTile(
            title: Text("ID"),
            additionalInfo: Text('${ship.uid}'),
          ),
          CupertinoListTile(
            leading: Icon(CupertinoIcons.back),
            title: Text(S.of(context).AppBack),
            onTap: () {
              setState(() {
                _showShipInfo = false;
              });
            },
          ),
        ],
      );
    }

    return SafeArea(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          transitionBetweenRoutes: false,
          backgroundColor: Colors.transparent,
          border: null,
          middle: CupertinoSlidingSegmentedControl(
            groupValue: _selectedSegment,
            onValueChanged: (int? value) {
              if (value != null) {
                setState(() {
                  _selectedSegment = value;
                  if (_showShipInfo) {
                    _showShipInfo = false;
                  } else {
                    controller.animateToPage(value,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.ease);
                  }
                });
              }
            },
            children: segments,
          ),
        ),
        child: SafeArea(
          child: _showShipInfo
              ? ScrollViewPageWithScrollbar(child: body)
              : PageView(
                  controller: controller,
                  onPageChanged: (value) {
                    setState(() {
                      _selectedSegment = value;
                    });
                  },
                  children: pages,
                ),
        ),
      ),
    );
  }
}

class ScrollViewPageWithScrollbar extends StatelessWidget {
  const ScrollViewPageWithScrollbar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoScrollbar(
      child: CustomScrollView(slivers: [
        SliverList(
          delegate: SliverChildListDelegate([child]),
        ),
      ]),
    );
  }
}
