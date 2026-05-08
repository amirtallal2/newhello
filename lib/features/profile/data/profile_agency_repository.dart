import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class AgencyAssetDraft {
  const AgencyAssetDraft({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  Map<String, dynamic> toJson() {
    return {
      'filename': fileName,
      'mime_type': mimeType,
      'content_base64': base64Encode(bytes),
    };
  }
}

class AgencyProfileData {
  const AgencyProfileData({
    required this.id,
    required this.name,
    required this.invitationCode,
    required this.country,
    required this.phone,
    required this.address,
    required this.status,
    required this.memberCount,
    this.ownerName,
  });

  final int id;
  final String name;
  final String invitationCode;
  final String country;
  final String phone;
  final String address;
  final String status;
  final int memberCount;
  final String? ownerName;

  factory AgencyProfileData.fromJson(Map<String, dynamic> json) {
    return AgencyProfileData(
      id: _agencyAsInt(json['id']),
      name: json['name']?.toString() ?? '',
      invitationCode: json['invitation_code']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      memberCount: _agencyAsInt(json['member_count'], fallback: 0),
      ownerName: json['owner_name']?.toString(),
    );
  }
}

class AgencyRequestReceipt {
  const AgencyRequestReceipt({
    required this.requestCode,
    required this.status,
    required this.agencyName,
  });

  final String requestCode;
  final String status;
  final String agencyName;

  factory AgencyRequestReceipt.fromJson(Map<String, dynamic> json) {
    return AgencyRequestReceipt(
      requestCode: json['request_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'new',
      agencyName: json['agency_name']?.toString() ?? '',
    );
  }
}

class AgencySummaryData {
  const AgencySummaryData({
    required this.agencyRole,
    this.agency,
    this.pendingOpenRequest,
    this.pendingJoinRequest,
  });

  final AgencyProfileData? agency;
  final String? agencyRole;
  final AgencyRequestReceipt? pendingOpenRequest;
  final AgencyRequestReceipt? pendingJoinRequest;

  factory AgencySummaryData.fromJson(Map<String, dynamic> json) {
    return AgencySummaryData(
      agencyRole: json['agency_role']?.toString(),
      agency: json['agency'] is Map<String, dynamic>
          ? AgencyProfileData.fromJson(json['agency'] as Map<String, dynamic>)
          : json['agency'] is Map
          ? AgencyProfileData.fromJson(
              Map<String, dynamic>.from(json['agency'] as Map),
            )
          : null,
      pendingOpenRequest: json['pending_open_request'] is Map<String, dynamic>
          ? AgencyRequestReceipt.fromJson(
              json['pending_open_request'] as Map<String, dynamic>,
            )
          : json['pending_open_request'] is Map
          ? AgencyRequestReceipt.fromJson(
              Map<String, dynamic>.from(json['pending_open_request'] as Map),
            )
          : null,
      pendingJoinRequest: json['pending_join_request'] is Map<String, dynamic>
          ? AgencyRequestReceipt.fromJson(
              json['pending_join_request'] as Map<String, dynamic>,
            )
          : json['pending_join_request'] is Map
          ? AgencyRequestReceipt.fromJson(
              Map<String, dynamic>.from(json['pending_join_request'] as Map),
            )
          : null,
    );
  }
}

abstract class ProfileAgencyRepository {
  static ProfileAgencyRepository instance = LiveProfileAgencyRepository();

  Future<AgencySummaryData> loadSummary();

  Future<AgencyRequestReceipt> submitOpenRequest({
    required String agencyName,
    required String country,
    required String phone,
    required String address,
    AgencyAssetDraft? avatar,
    AgencyAssetDraft? frontId,
    AgencyAssetDraft? backId,
  });

  Future<AgencyRequestReceipt> submitJoinRequest({
    required String invitationCode,
    required String agencyType,
  });
}

final class LiveProfileAgencyRepository implements ProfileAgencyRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<AgencySummaryData> loadSummary() async {
    final response = await _client.get(
      '/agency/summary',
      bearerToken: _authStore.authToken,
    );
    return AgencySummaryData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<AgencyRequestReceipt> submitOpenRequest({
    required String agencyName,
    required String country,
    required String phone,
    required String address,
    AgencyAssetDraft? avatar,
    AgencyAssetDraft? frontId,
    AgencyAssetDraft? backId,
  }) async {
    final response = await _client.post(
      '/agency/open-requests',
      body: {
        'agency_name': agencyName,
        'country': country,
        'phone': phone,
        'address': address,
        'avatar': avatar?.toJson(),
        'front_id': frontId?.toJson(),
        'back_id': backId?.toJson(),
      },
      bearerToken: _authStore.authToken,
    );

    final data = Map<String, dynamic>.from(response['data'] as Map);
    return AgencyRequestReceipt.fromJson(
      Map<String, dynamic>.from(data['request'] as Map),
    );
  }

  @override
  Future<AgencyRequestReceipt> submitJoinRequest({
    required String invitationCode,
    required String agencyType,
  }) async {
    final response = await _client.post(
      '/agency/join-requests',
      body: {'invitation_code': invitationCode, 'agency_type': agencyType},
      bearerToken: _authStore.authToken,
    );

    final data = Map<String, dynamic>.from(response['data'] as Map);
    return AgencyRequestReceipt.fromJson(
      Map<String, dynamic>.from(data['request'] as Map),
    );
  }
}

final class FakeProfileAgencyRepository implements ProfileAgencyRepository {
  AgencySummaryData _summary = AgencySummaryData(
    agencyRole: 'owner',
    agency: const AgencyProfileData(
      id: 1,
      name: 'وكالة النخبة',
      invitationCode: 'VL-AGY-2026',
      country: 'مصر',
      phone: '201011223344',
      address: 'القاهرة - مدينة نصر',
      status: 'active',
      memberCount: 1,
      ownerName: 'Mohamed Ahmed',
    ),
  );

  int _nextOpenRequest = 2;
  int _nextJoinRequest = 2;

  @override
  Future<AgencySummaryData> loadSummary() async {
    return _summary;
  }

  @override
  Future<AgencyRequestReceipt> submitJoinRequest({
    required String invitationCode,
    required String agencyType,
  }) async {
    final receipt = AgencyRequestReceipt(
      requestCode: 'AJR-${_nextJoinRequest.toString().padLeft(6, '0')}',
      status: 'new',
      agencyName: 'وكالة النخبة',
    );
    _nextJoinRequest++;
    _summary = AgencySummaryData(
      agencyRole: _summary.agencyRole,
      agency: _summary.agency,
      pendingOpenRequest: _summary.pendingOpenRequest,
      pendingJoinRequest: receipt,
    );
    return receipt;
  }

  @override
  Future<AgencyRequestReceipt> submitOpenRequest({
    required String agencyName,
    required String country,
    required String phone,
    required String address,
    AgencyAssetDraft? avatar,
    AgencyAssetDraft? frontId,
    AgencyAssetDraft? backId,
  }) async {
    final receipt = AgencyRequestReceipt(
      requestCode: 'AOR-${_nextOpenRequest.toString().padLeft(6, '0')}',
      status: 'new',
      agencyName: agencyName,
    );
    _nextOpenRequest++;
    _summary = AgencySummaryData(
      agencyRole: _summary.agencyRole,
      agency: _summary.agency,
      pendingOpenRequest: receipt,
      pendingJoinRequest: _summary.pendingJoinRequest,
    );
    return receipt;
  }
}

int _agencyAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
