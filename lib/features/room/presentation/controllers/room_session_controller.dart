import 'package:flutter/foundation.dart';

import '../../../auth/data/auth_flow_store.dart';
import '../../data/room_repository.dart';

enum RoomUserRole { admin, member }

final class RoomSessionController {
  RoomSessionController._();

  static final RoomSessionController instance = RoomSessionController._();

  final ValueNotifier<RoomData> room = ValueNotifier<RoomData>(
    RoomData.fallback,
  );
  final ValueNotifier<int> micCount = ValueNotifier<int>(9);
  final ValueNotifier<int?> pendingMicRequestSeatNumber = ValueNotifier<int?>(
    null,
  );
  final ValueNotifier<List<RoomSeatRequestData>> seatRequests =
      ValueNotifier<List<RoomSeatRequestData>>(<RoomSeatRequestData>[]);
  final ValueNotifier<RoomUserRole> currentUserRole =
      ValueNotifier<RoomUserRole>(RoomUserRole.member);
  bool _hasManualRoleOverride = false;

  int _activeRoomId = RoomData.fallback.id;
  int get activeRoomId => _activeRoomId;

  Future<void> loadRoom({int roomId = 1}) async {
    final roomData = await RoomRepository.instance.getRoom(roomId);
    _activeRoomId = roomId;
    final currentUserId = int.tryParse(
      AuthFlowStore.instance.currentUser?['id']?.toString() ?? '',
    );
    final mergedPendingSeats = <int>{
      ...roomData.pendingRequestSeatNumbers,
      ...room.value.pendingRequestSeatNumbers,
      if (pendingMicRequestSeatNumber.value != null)
        pendingMicRequestSeatNumber.value!,
    }.toList()..sort();
    room.value = roomData.copyWith(
      pendingRequestSeatNumbers: mergedPendingSeats,
    );
    micCount.value = roomData.micCount;
    pendingMicRequestSeatNumber.value = mergedPendingSeats.isEmpty
        ? null
        : mergedPendingSeats.first;
    if (!_hasManualRoleOverride) {
      currentUserRole.value = currentUserId == null
          ? RoomUserRole.admin
          : currentUserId == roomData.hostUserId
          ? RoomUserRole.admin
          : RoomUserRole.member;
    }
  }

  void updateMicCount(int count) {
    micCount.value = count;
    room.value = room.value.copyWith(micCount: count);
  }

  void updateUserRole(RoomUserRole role) {
    _hasManualRoleOverride = true;
    currentUserRole.value = role;
  }

  void requestMic(int seatNumber) {
    pendingMicRequestSeatNumber.value = seatNumber;
    final pendingSeats = <int>{
      ...room.value.pendingRequestSeatNumbers,
      seatNumber,
    }.toList()..sort();
    room.value = room.value.copyWith(pendingRequestSeatNumbers: pendingSeats);
  }

  void clearMicRequest() {
    pendingMicRequestSeatNumber.value = null;
    room.value = room.value.copyWith(pendingRequestSeatNumbers: const <int>[]);
    seatRequests.value = <RoomSeatRequestData>[];
  }

  Future<void> persistMicCount(int count) async {
    updateMicCount(count);
    final roomData = await RoomRepository.instance.updateMicCount(
      roomId: _activeRoomId,
      micCount: count,
    );
    room.value = roomData;
    micCount.value = roomData.micCount;
    pendingMicRequestSeatNumber.value =
        roomData.pendingRequestSeatNumbers.isEmpty
        ? null
        : roomData.pendingRequestSeatNumbers.first;
  }

  Future<void> submitMicRequest(int seatNumber) async {
    requestMic(seatNumber);
    await RoomRepository.instance.createSeatRequest(
      roomId: _activeRoomId,
      seatNumber: seatNumber,
    );
    await loadRoom(roomId: _activeRoomId);
  }

  Future<List<RoomSeatRequestData>> loadSeatRequests(int seatNumber) async {
    final requests = await RoomRepository.instance.listSeatRequests(
      roomId: _activeRoomId,
      seatNumber: seatNumber,
    );
    seatRequests.value = requests;
    return requests;
  }

  void reset() {
    _activeRoomId = RoomData.fallback.id;
    room.value = RoomData.fallback;
    micCount.value = 9;
    pendingMicRequestSeatNumber.value = null;
    seatRequests.value = <RoomSeatRequestData>[];
    currentUserRole.value = RoomUserRole.admin;
    _hasManualRoleOverride = false;
  }
}
