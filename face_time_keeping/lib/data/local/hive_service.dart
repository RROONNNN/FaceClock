import 'package:face_time_keeping/common/utils/log_util.dart';
import 'package:face_time_keeping/entities/person.dart';
import 'package:hive/hive.dart';
import 'package:face_time_keeping/entities/check_in_out.dart';
import 'package:injectable/injectable.dart';

abstract class HiveService {
  // Future<DateTime?> isCheckedIn(String pin);
  // // Future<bool> isCheckOut(int employeeId);
  Future<int> saveCheckInOut(CheckInOut checkInOut);
  Future<List<CheckInOut>> getAllCheckInOuts();
  Future<List<CheckInOut>> getCheckInOutsOnOrAfter(DateTime? date);
  Future<CheckInOut?> getCheckInOut(int id);
  Future<void> deleteCheckInOut(int id);
  Future<void> updateCheckInOut(CheckInOut checkInOut);
  Future<void> dispose();
  Future<void> clearCheckInOut();
  Future<void> savePerson(Person person);
  Future<Person?> getPerson(int employeeId);
  Future<void> deletePerson(int employeeId);
  Future<void> updatePerson(Person person);
  Future<void> clearPersons();
  Future<List<CheckInOut>> getUnSyncedCheckInOuts();
  Future<void> updateCheckInOutFlag(int ioId, bool isSynced);
  Future<void> init();
  Future<List<Person>> getAllPersons();
  Future<void> refreshCheckInOutBox();
  Future<void> updatePersonSynced(int employeeId, bool isSynced);
}

@LazySingleton(as: HiveService)
class HiveServiceImplement implements HiveService {
  static const String _checkInOutBoxName = 'checkIO_box';
  static const String _personBoxName = 'person_box';
  Box<CheckInOut>? _checkInOutBox;
  Box<Person>? _personBox;

  @override
  Future<void> init() async {
    try {
      if (_checkInOutBox?.isOpen ?? false) {
        await _checkInOutBox?.close();
      }
      if (_personBox?.isOpen ?? false) {
        await _personBox?.close();
      }
      _checkInOutBox = await Hive.openBox<CheckInOut>(_checkInOutBoxName);
      _personBox = await Hive.openBox<Person>(_personBoxName);
    } catch (e, stackTrace) {
      await pushLog('Error initializing Hive: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> refreshCheckInOutBox() async {
    try {
      if (_checkInOutBox?.isOpen ?? false) {
        await _checkInOutBox?.close();
      }
      _checkInOutBox = await Hive.openBox<CheckInOut>(_checkInOutBoxName);
    } catch (e, stackTrace) {
      await pushLog('Error refreshing CheckInOut box: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<Person>> getAllPersons() async {
    _personBox ??= await Hive.openBox<Person>(_personBoxName);
    final result = _personBox!.values.toList();
    return result;
  }

  @override
  Future<void> updateCheckInOutFlag(int ioId, bool isSynced) async {
    try {
      _checkInOutBox ??= await Hive.openBox<CheckInOut>(_checkInOutBoxName);
      final checkInOut = _checkInOutBox!.get(ioId);
      if (checkInOut != null) {
        await _checkInOutBox?.put(
            ioId, checkInOut.copyWith(isSynced: isSynced));
      }
    } catch (e, stackTrace) {
      await pushLog('Error updating CheckInOut flag: $e\n$stackTrace');
    }
  }

  @override
  Future<List<CheckInOut>> getUnSyncedCheckInOuts() async {
    final allCheckInOuts = await getAllCheckInOuts();
    return allCheckInOuts.where((e) => e.isSynced == false).toList();
  }

  // CheckInOut methods
  @override
  Future<int> saveCheckInOut(CheckInOut checkInOut) async {
    _checkInOutBox ??= await Hive.openBox<CheckInOut>(_checkInOutBoxName);
    final id = await _checkInOutBox!.add(checkInOut);
    return id;
  }

  @override
  Future<CheckInOut?> getCheckInOut(int id) async {
    _checkInOutBox ??= await Hive.openBox<CheckInOut>(_checkInOutBoxName);
    final checkInOut = _checkInOutBox!.get(id);
    if (checkInOut == null) return null;
    return checkInOut.copyWith(id: id);
  }

  @override
  Future<List<CheckInOut>> getAllCheckInOuts() async {
    _checkInOutBox ??= await Hive.openBox<CheckInOut>(_checkInOutBoxName);
    final entries = _checkInOutBox!.toMap().entries;
    final items =
        entries.map((e) => e.value.copyWith(id: e.key)).toList(growable: false);
    items.sort(
      (a, b) {
        final aTime = a.time;
        final bTime = b.time;
        return bTime.compareTo(aTime);
      },
    );

    return items;
  }

  @override
  Future<List<CheckInOut>> getCheckInOutsOnOrAfter(DateTime? date) async {
    _checkInOutBox ??= await Hive.openBox<CheckInOut>(_checkInOutBoxName);
    final entries = _checkInOutBox!.toMap().entries;
    final items =
        entries.map((e) => e.value.copyWith(id: e.key)).toList(growable: false);
    if (date == null) return items;
    final filtered = items.where((e) => e.time.isAfter(date)).toList();
    return filtered;
  }

  @override
  Future<void> updateCheckInOut(CheckInOut checkInOut) async {
    _checkInOutBox ??= await Hive.openBox<CheckInOut>(_checkInOutBoxName);
    await _checkInOutBox!.put(checkInOut.id, checkInOut);
  }

  @override
  Future<void> deleteCheckInOut(int id) async {
    _checkInOutBox ??= await Hive.openBox<CheckInOut>(_checkInOutBoxName);
    await _checkInOutBox!.delete(id);
  }

  @override
  Future<void> clearCheckInOut() async {
    _checkInOutBox ??= await Hive.openBox<CheckInOut>(_checkInOutBoxName);
    await _checkInOutBox!.clear();
  }

  // Person methods
  @override
  Future<void> savePerson(Person person) async {
    _personBox ??= await Hive.openBox<Person>(_personBoxName);

    await _personBox!.put(person.employeeId, person);
  }

  @override
  Future<Person?> getPerson(int employeeId) async {
    _personBox ??= await Hive.openBox<Person>(_personBoxName);
    return _personBox!.get(employeeId);
  }

  @override
  Future<void> updatePerson(Person person) async {
    _personBox ??= await Hive.openBox<Person>(_personBoxName);
    await _personBox!.put(person.employeeId, person);
  }

  @override
  Future<void> deletePerson(int employeeId) async {
    _personBox ??= await Hive.openBox<Person>(_personBoxName);
    await _personBox!.delete(employeeId);
  }

  @override
  Future<void> clearPersons() async {
    try {
      _personBox ??= await Hive.openBox<Person>(_personBoxName);
      // clear all person
      await _personBox!.clear();
    } catch (e, stackTrace) {
      await pushLog('Error clearing persons: $e\n$stackTrace');
    }
  }

  @override
  Future<void> updatePersonSynced(int employeeId, bool isSynced) async {
    try {
      _personBox ??= await Hive.openBox<Person>(_personBoxName);
      await _personBox!.put(
          employeeId,
          Person(
              employeeId: employeeId,
              updatedTime: DateTime.now(),
              isSynced: isSynced));
    } catch (e, stackTrace) {
      await pushLog('Error updating person synced: $e\n$stackTrace');
      rethrow;
    }
  }

  // Utility methods
  @override
  Future<void> dispose() async {
    await _checkInOutBox?.close();
    await _personBox?.close();
  }
}
