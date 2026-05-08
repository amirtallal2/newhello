import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class ShippingAgencyData {
  const ShippingAgencyData({
    required this.id,
    required this.name,
    required this.handle,
    required this.diamondBalance,
    required this.diamondBalanceLabel,
    required this.supportedCountryCodes,
  });

  final int id;
  final String name;
  final String handle;
  final int diamondBalance;
  final String diamondBalanceLabel;
  final List<String> supportedCountryCodes;

  int get supportedCountriesCount => supportedCountryCodes.length;

  factory ShippingAgencyData.fromJson(Map<String, dynamic> json) {
    return ShippingAgencyData(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? 'Mohamed Ahmed',
      handle: json['handle']?.toString() ?? '@ ابو احمد',
      diamondBalance: _asInt(json['diamond_balance']),
      diamondBalanceLabel:
          json['diamond_balance_label']?.toString() ?? '30.5M',
      supportedCountryCodes:
          (json['supported_country_codes'] as List? ?? const <dynamic>[])
              .map((code) => code.toString())
              .toList(),
    );
  }
}

class SupportAttachmentDraft {
  const SupportAttachmentDraft({
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

class SupportTicketReceipt {
  const SupportTicketReceipt({
    required this.id,
    required this.ticketCode,
    required this.status,
  });

  final int id;
  final String ticketCode;
  final String status;

  factory SupportTicketReceipt.fromJson(Map<String, dynamic> json) {
    return SupportTicketReceipt(
      id: _asInt(json['id']),
      ticketCode: json['ticket_code']?.toString() ?? 'SUP-000000',
      status: json['status']?.toString() ?? 'new',
    );
  }
}

abstract class ProfileSupportRepository {
  static ProfileSupportRepository instance = LiveProfileSupportRepository();

  Future<List<ShippingAgencyData>> listShippingAgencies({String query = ''});

  Future<SupportTicketReceipt> submitSupportTicket({
    required String category,
    required String description,
    required List<SupportAttachmentDraft> attachments,
  });
}

final class LiveProfileSupportRepository implements ProfileSupportRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<List<ShippingAgencyData>> listShippingAgencies({
    String query = '',
  }) async {
    final encodedQuery = Uri.encodeQueryComponent(query.trim());
    final path = encodedQuery.isEmpty
        ? '/shipping-agencies'
        : '/shipping-agencies?query=$encodedQuery';
    final response = await _client.get(
      path,
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['agencies'] as List? ?? const <dynamic>[])
        .map(
          (item) => ShippingAgencyData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<SupportTicketReceipt> submitSupportTicket({
    required String category,
    required String description,
    required List<SupportAttachmentDraft> attachments,
  }) async {
    final response = await _client.post(
      '/support/tickets',
      body: {
        'category': category,
        'description': description,
        'attachments': attachments.map((item) => item.toJson()).toList(),
      },
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return SupportTicketReceipt.fromJson(
      Map<String, dynamic>.from(data['ticket'] as Map),
    );
  }
}

final class FakeProfileSupportRepository implements ProfileSupportRepository {
  final List<ShippingAgencyData> _agencies = const <ShippingAgencyData>[
    ShippingAgencyData(
      id: 1,
      name: 'Mohamed Ahmed',
      handle: '@ ابو احمد',
      diamondBalance: 30500000,
      diamondBalanceLabel: '30.5M',
      supportedCountryCodes: <String>['at', 'az', 'ae'],
    ),
    ShippingAgencyData(
      id: 2,
      name: 'Sara Mohamed',
      handle: '@ سارة',
      diamondBalance: 17200000,
      diamondBalanceLabel: '17.2M',
      supportedCountryCodes: <String>['ae', 'az'],
    ),
    ShippingAgencyData(
      id: 3,
      name: 'Nour Salem',
      handle: '@ نور',
      diamondBalance: 8900000,
      diamondBalanceLabel: '8.9M',
      supportedCountryCodes: <String>['at', 'ae'],
    ),
  ];

  int _nextTicketId = 3;

  @override
  Future<List<ShippingAgencyData>> listShippingAgencies({
    String query = '',
  }) async {
    if (query.trim().isEmpty) {
      return _agencies;
    }

    final normalized = query.trim().toLowerCase();
    return _agencies.where((agency) {
      return '${agency.name} ${agency.handle} ${agency.diamondBalanceLabel}'
          .toLowerCase()
          .contains(normalized);
    }).toList();
  }

  @override
  Future<SupportTicketReceipt> submitSupportTicket({
    required String category,
    required String description,
    required List<SupportAttachmentDraft> attachments,
  }) async {
    final ticketId = _nextTicketId++;
    return SupportTicketReceipt(
      id: ticketId,
      ticketCode: 'SUP-${ticketId.toString().padLeft(6, '0')}',
      status: 'new',
    );
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
