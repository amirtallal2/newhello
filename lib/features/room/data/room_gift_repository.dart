import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_flow_store.dart';

class RoomGiftItemData {
  const RoomGiftItemData({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    required this.priceCoins,
    this.animationPath = '',
    this.soundPath = '',
    this.isAnimated = false,
    this.effectDurationMs = 1800,
  });

  final int id;
  final String name;
  final String category;
  final String assetPath;
  final int priceCoins;
  final String animationPath;
  final String soundPath;
  final bool isAnimated;
  final int effectDurationMs;

  String get effectAssetPath =>
      animationPath.trim().isEmpty ? assetPath : animationPath;

  bool get hasSound => soundPath.trim().isNotEmpty;

  factory RoomGiftItemData.fromJson(Map<String, dynamic> json) {
    return RoomGiftItemData(
      id: _giftAsInt(json['id'], fallback: 1),
      name: json['name']?.toString() ?? 'الهدية الصغيرة',
      category: json['category']?.toString() ?? 'الهداية عادية',
      assetPath:
          json['asset_path']?.toString() ?? 'assets/images/room_gift_1.png',
      priceCoins: _giftAsInt(json['price_coins'], fallback: 10),
      animationPath: json['animation_path']?.toString() ?? '',
      soundPath: json['sound_path']?.toString() ?? '',
      isAnimated:
          json['is_animated'] == true ||
          _giftAsInt(json['is_animated'], fallback: 0) == 1,
      effectDurationMs: _giftAsInt(json['effect_duration_ms'], fallback: 1800),
    );
  }
}

class RoomGiftPanelData {
  const RoomGiftPanelData({
    required this.walletCoinsBalance,
    required this.walletDiamondsBalance,
    required this.isGuest,
    required this.gifts,
  });

  final int walletCoinsBalance;
  final int walletDiamondsBalance;
  final bool isGuest;
  final List<RoomGiftItemData> gifts;

  RoomGiftPanelData copyWith({
    int? walletCoinsBalance,
    int? walletDiamondsBalance,
    bool? isGuest,
    List<RoomGiftItemData>? gifts,
  }) {
    return RoomGiftPanelData(
      walletCoinsBalance: walletCoinsBalance ?? this.walletCoinsBalance,
      walletDiamondsBalance:
          walletDiamondsBalance ?? this.walletDiamondsBalance,
      isGuest: isGuest ?? this.isGuest,
      gifts: gifts ?? this.gifts,
    );
  }
}

class RoomGiftSupporterData {
  const RoomGiftSupporterData({
    required this.rank,
    required this.name,
    required this.avatarAsset,
    required this.totalCoins,
    required this.coinsLabel,
    required this.isTopSupporter,
  });

  final int rank;
  final String name;
  final String avatarAsset;
  final int totalCoins;
  final String coinsLabel;
  final bool isTopSupporter;

  factory RoomGiftSupporterData.fromJson(Map<String, dynamic> json) {
    return RoomGiftSupporterData(
      rank: _giftAsInt(json['rank'], fallback: 1),
      name: json['name']?.toString() ?? 'Mohammed Ahmed',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      totalCoins: _giftAsInt(json['total_coins'], fallback: 0),
      coinsLabel: json['coins_label']?.toString() ?? '0 Coin',
      isTopSupporter: json['is_top_supporter'] == true,
    );
  }
}

abstract class RoomGiftRepository {
  static RoomGiftRepository instance = LiveRoomGiftRepository();

  Future<RoomGiftPanelData> loadGiftPanel({required int roomId});

  Future<RoomGiftPanelData> sendGift({
    required int roomId,
    required int giftId,
    required int quantity,
    required String recipientMode,
    int? recipientSlot,
  });

  Future<List<RoomGiftSupporterData>> loadRoomSupporters({required int roomId});
}

final class LiveRoomGiftRepository implements RoomGiftRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<RoomGiftPanelData> loadGiftPanel({required int roomId}) async {
    final catalogResponse = await _client.get(
      '/gifts/catalog',
      bearerToken: _authStore.authToken,
    );
    final walletResponse = await _client.get(
      '/wallet/summary',
      bearerToken: _authStore.authToken,
    );

    final catalogData = catalogResponse['data'] as Map<String, dynamic>;
    final walletData = walletResponse['data'] as Map<String, dynamic>;

    return RoomGiftPanelData(
      walletCoinsBalance: _giftAsInt(
        walletData['coins_balance'],
        fallback: 1235,
      ),
      walletDiamondsBalance: _giftAsInt(
        walletData['diamonds_balance'],
        fallback: 5,
      ),
      isGuest: walletData['is_guest'] == true,
      gifts: (catalogData['gifts'] as List? ?? const <dynamic>[])
          .map(
            (item) => RoomGiftItemData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<RoomGiftPanelData> sendGift({
    required int roomId,
    required int giftId,
    required int quantity,
    required String recipientMode,
    int? recipientSlot,
  }) async {
    final response = await _client.post(
      '/rooms/$roomId/gifts/send',
      body: {
        'gift_id': giftId,
        'quantity': quantity,
        'recipient_mode': recipientMode,
        'recipient_slot': recipientSlot,
      },
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    final wallet = data['wallet'] as Map<String, dynamic>;
    final currentPanel = await loadGiftPanel(roomId: roomId);

    return currentPanel.copyWith(
      walletCoinsBalance: _giftAsInt(wallet['coins_balance'], fallback: 1235),
      walletDiamondsBalance: _giftAsInt(
        wallet['diamonds_balance'],
        fallback: 5,
      ),
      isGuest: wallet['is_guest'] == true,
    );
  }

  @override
  Future<List<RoomGiftSupporterData>> loadRoomSupporters({
    required int roomId,
  }) async {
    final response = await _client.get(
      '/rooms/$roomId/gifts/received',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['supporters'] as List? ?? const <dynamic>[])
        .map(
          (item) => RoomGiftSupporterData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}

final class FakeRoomGiftRepository implements RoomGiftRepository {
  FakeRoomGiftRepository() {
    _seed();
  }

  RoomGiftPanelData _panel = const RoomGiftPanelData(
    walletCoinsBalance: 1235,
    walletDiamondsBalance: 5,
    isGuest: false,
    gifts: <RoomGiftItemData>[],
  );
  final Map<int, List<RoomGiftSupporterData>> _supportersByRoom =
      <int, List<RoomGiftSupporterData>>{};

  void _seed() {
    if (_panel.gifts.isNotEmpty) {
      return;
    }

    _panel = RoomGiftPanelData(
      walletCoinsBalance: 1235,
      walletDiamondsBalance: 5,
      isGuest: false,
      gifts: const <RoomGiftItemData>[
        RoomGiftItemData(
          id: 1,
          name: 'الهدية الصغيرة',
          category: 'الهداية عادية',
          assetPath: 'assets/images/room_gift_1.png',
          priceCoins: 10,
        ),
        RoomGiftItemData(
          id: 2,
          name: 'الهدية الصغيرة',
          category: 'الهداية عادية',
          assetPath: 'assets/images/room_gift_2.png',
          priceCoins: 10,
        ),
        RoomGiftItemData(
          id: 3,
          name: 'الهدية الصغيرة',
          category: 'الهداية عادية',
          assetPath: 'assets/images/room_gift_3.png',
          priceCoins: 10,
        ),
        RoomGiftItemData(
          id: 4,
          name: 'الهدية الصغيرة',
          category: 'الهداية عادية',
          assetPath: 'assets/images/room_gift_4.png',
          priceCoins: 10,
        ),
        RoomGiftItemData(
          id: 5,
          name: 'الهدية الصغيرة',
          category: 'VIP',
          assetPath: 'assets/images/room_gift_5.png',
          priceCoins: 20,
        ),
        RoomGiftItemData(
          id: 6,
          name: 'الهدية الصغيرة',
          category: 'VIP',
          assetPath: 'assets/images/room_gift_6.png',
          priceCoins: 25,
        ),
        RoomGiftItemData(
          id: 7,
          name: 'الهدية الصغيرة',
          category: 'المحظوظ',
          assetPath: 'assets/images/room_gift_7.png',
          priceCoins: 30,
        ),
        RoomGiftItemData(
          id: 8,
          name: 'الهدية الصغيرة',
          category: 'متحرك',
          assetPath: 'assets/images/room_gift_8.png',
          priceCoins: 40,
        ),
      ],
    );

    _supportersByRoom[1] = const <RoomGiftSupporterData>[
      RoomGiftSupporterData(
        rank: 1,
        name: 'Mohammed Ahmed',
        avatarAsset: 'assets/images/profile_avatar.png',
        totalCoins: 200,
        coinsLabel: '200 Coin',
        isTopSupporter: true,
      ),
      RoomGiftSupporterData(
        rank: 2,
        name: 'Mohammed Ahmed',
        avatarAsset: 'assets/images/profile_avatar.png',
        totalCoins: 200,
        coinsLabel: '200 Coin',
        isTopSupporter: false,
      ),
      RoomGiftSupporterData(
        rank: 3,
        name: 'Mohammed Ahmed',
        avatarAsset: 'assets/images/profile_avatar.png',
        totalCoins: 200,
        coinsLabel: '200 Coin',
        isTopSupporter: false,
      ),
      RoomGiftSupporterData(
        rank: 4,
        name: 'Mohammed Ahmed',
        avatarAsset: 'assets/images/profile_avatar.png',
        totalCoins: 21,
        coinsLabel: '21 Coin',
        isTopSupporter: false,
      ),
    ];
  }

  @override
  Future<RoomGiftPanelData> loadGiftPanel({required int roomId}) async {
    return _panel;
  }

  @override
  Future<RoomGiftPanelData> sendGift({
    required int roomId,
    required int giftId,
    required int quantity,
    required String recipientMode,
    int? recipientSlot,
  }) async {
    final gift = _panel.gifts.firstWhere(
      (item) => item.id == giftId,
      orElse: () => _panel.gifts.first,
    );
    final total = gift.priceCoins * quantity;
    if (_panel.walletCoinsBalance < total) {
      throw ApiException('Insufficient coin balance.');
    }

    _panel = _panel.copyWith(
      walletCoinsBalance: _panel.walletCoinsBalance - total,
    );

    final senderName =
        AuthFlowStore.instance.currentUser?['nickname']?.toString() ??
        'Mohammed Ahmed';
    final supporters = List<RoomGiftSupporterData>.from(
      _supportersByRoom[roomId] ?? const <RoomGiftSupporterData>[],
    );
    final updated = RoomGiftSupporterData(
      rank: 1,
      name: senderName,
      avatarAsset: 'assets/images/profile_avatar.png',
      totalCoins: total,
      coinsLabel: '$total Coin',
      isTopSupporter: true,
    );
    supporters.insert(0, updated);
    _supportersByRoom[roomId] = supporters.asMap().entries.map((entry) {
      final item = entry.value;
      return RoomGiftSupporterData(
        rank: entry.key + 1,
        name: item.name,
        avatarAsset: item.avatarAsset,
        totalCoins: item.totalCoins,
        coinsLabel: item.coinsLabel,
        isTopSupporter: entry.key == 0,
      );
    }).toList();

    return _panel;
  }

  @override
  Future<List<RoomGiftSupporterData>> loadRoomSupporters({
    required int roomId,
  }) async {
    return _supportersByRoom[roomId] ?? const <RoomGiftSupporterData>[];
  }
}

int _giftAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
