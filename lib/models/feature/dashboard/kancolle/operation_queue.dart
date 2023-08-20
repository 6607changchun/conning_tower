import 'package:conning_tower/constants.dart';
import 'package:conning_tower/models/feature/task.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'operation_queue.freezed.dart';


@unfreezed
class OperationQueue with _$OperationQueue {
  const OperationQueue._();

  factory OperationQueue({required Map<int, Operation> map}) =
      _OperationQueue;

  void executeOperation(int squad, Operation operation) {
    map[squad] = operation;
  }

  void executeTask(int squad, Task task) {
    String timeString = task.time;
    if (timeString == kZeroTime) return;

    List<String> parts = timeString.split(':');
    Duration duration = Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
    map[squad] = Operation(
        id: 100,
        title: task.title,
        endTime: DateTime.now().add(duration));
  }
}

@freezed
class Operation with _$Operation {
  @Assert('title.length <= 20', 'title must have a maximum length of 20')
  factory Operation(
      {required int id,
      required String title,
      required DateTime endTime}) = _Operation;
}
