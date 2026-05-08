import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class EconomyWalletData {
  const EconomyWalletData({
    required this.coinsBalance,
    required this.diamondsBalance,
  });

  final int coinsBalance;
  final int diamondsBalance;

  factory EconomyWalletData.fromJson(Map<String, dynamic> json) {
    return EconomyWalletData(
      coinsBalance: _economyAsInt(json['coins_balance']),
      diamondsBalance: _economyAsInt(json['diamonds_balance']),
    );
  }
}

class WalletPackageData {
  const WalletPackageData({
    required this.id,
    required this.walletType,
    required this.amount,
    required this.bonusAmount,
    required this.priceLabel,
  });

  final int id;
  final String walletType;
  final int amount;
  final int bonusAmount;
  final String priceLabel;

  int get totalAmount => amount + bonusAmount;

  factory WalletPackageData.fromJson(Map<String, dynamic> json) {
    return WalletPackageData(
      id: _economyAsInt(json['id']),
      walletType: json['wallet_type']?.toString() ?? 'coins',
      amount: _economyAsInt(json['amount']),
      bonusAmount: _economyAsInt(json['bonus_amount']),
      priceLabel: json['price_label']?.toString() ?? '0',
    );
  }
}

class WalletDashboardData {
  const WalletDashboardData({
    required this.wallet,
    required this.diamondPackages,
    required this.coinPackages,
  });

  final EconomyWalletData wallet;
  final List<WalletPackageData> diamondPackages;
  final List<WalletPackageData> coinPackages;
}

class WalletRecordData {
  const WalletRecordData({
    required this.id,
    required this.walletType,
    required this.direction,
    required this.amount,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.timeLabel,
  });

  final int id;
  final String walletType;
  final String direction;
  final int amount;
  final String status;
  final String title;
  final String subtitle;
  final String dateLabel;
  final String timeLabel;

  bool get isSuccess => status == 'success';

  factory WalletRecordData.fromJson(Map<String, dynamic> json) {
    return WalletRecordData(
      id: _economyAsInt(json['id']),
      walletType: json['wallet_type']?.toString() ?? 'coins',
      direction: json['direction']?.toString() ?? 'credit',
      amount: _economyAsInt(json['amount']),
      status: json['status']?.toString() ?? 'success',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      dateLabel: json['date_label']?.toString() ?? '20/10/2024',
      timeLabel: json['time_label']?.toString() ?? '10:55',
    );
  }
}

class WalletRecordsPayload {
  const WalletRecordsPayload({required this.wallet, required this.records});

  final EconomyWalletData wallet;
  final List<WalletRecordData> records;
}

class StoreDurationOptionData {
  const StoreDurationOptionData({
    required this.days,
    required this.price,
    required this.discount,
  });

  final int days;
  final int price;
  final String discount;

  factory StoreDurationOptionData.fromJson(Map<String, dynamic> json) {
    return StoreDurationOptionData(
      days: _economyAsInt(json['days']),
      price: _economyAsInt(json['price']),
      discount: json['discount']?.toString() ?? '',
    );
  }
}

class StoreItemData {
  const StoreItemData({
    required this.id,
    required this.categoryKey,
    required this.name,
    required this.previewAssetPath,
    this.dialogIconAssetPath,
    this.dialogPreviewAssetPath,
    required this.currencyType,
    required this.durations,
    required this.defaultDurationDays,
  });

  final int id;
  final String categoryKey;
  final String name;
  final String previewAssetPath;
  final String? dialogIconAssetPath;
  final String? dialogPreviewAssetPath;
  final String currencyType;
  final List<StoreDurationOptionData> durations;
  final int defaultDurationDays;

  StoreDurationOptionData get defaultDuration {
    return durations.firstWhere(
      (duration) => duration.days == defaultDurationDays,
      orElse: () => durations.first,
    );
  }

  factory StoreItemData.fromJson(Map<String, dynamic> json) {
    return StoreItemData(
      id: _economyAsInt(json['id']),
      categoryKey: json['category_key']?.toString() ?? 'frames',
      name: json['name']?.toString() ?? 'عنصر',
      previewAssetPath:
          json['preview_asset_path']?.toString() ??
          'assets/images/profile_store_frames_preview_overlay.png',
      dialogIconAssetPath: json['dialog_icon_asset_path']?.toString(),
      dialogPreviewAssetPath: json['dialog_preview_asset_path']?.toString(),
      currencyType: json['currency_type']?.toString() ?? 'coins',
      durations: (json['durations'] as List? ?? const <dynamic>[])
          .map(
            (item) => StoreDurationOptionData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      defaultDurationDays: _economyAsInt(json['default_duration_days']),
    );
  }
}

class StoreCatalogData {
  const StoreCatalogData({required this.categoryKey, required this.items});

  final String categoryKey;
  final List<StoreItemData> items;
}

class StoreRecipientData {
  const StoreRecipientData({
    required this.id,
    required this.name,
    required this.avatarAssetPath,
    this.innerAvatarAssetPath,
  });

  final int? id;
  final String name;
  final String avatarAssetPath;
  final String? innerAvatarAssetPath;

  factory StoreRecipientData.fromJson(Map<String, dynamic> json) {
    return StoreRecipientData(
      id: json['id'] == null ? null : _economyAsInt(json['id']),
      name: json['name']?.toString() ?? 'Mohamed Ahmed',
      avatarAssetPath:
          json['avatar_asset_path']?.toString() ??
          'assets/images/profile_store_friend_yara.png',
      innerAvatarAssetPath: json['inner_avatar_asset_path']?.toString(),
    );
  }
}

class BagInventoryItemData {
  const BagInventoryItemData({
    required this.id,
    required this.itemId,
    required this.categoryKey,
    required this.name,
    required this.previewAssetPath,
    this.dialogPreviewAssetPath,
    required this.durationDays,
    required this.status,
    required this.isEquipped,
    required this.acquiredVia,
    required this.expiresAtLabel,
  });

  final int id;
  final int itemId;
  final String categoryKey;
  final String name;
  final String previewAssetPath;
  final String? dialogPreviewAssetPath;
  final int durationDays;
  final String status;
  final bool isEquipped;
  final String acquiredVia;
  final String expiresAtLabel;

  factory BagInventoryItemData.fromJson(Map<String, dynamic> json) {
    return BagInventoryItemData(
      id: _economyAsInt(json['id']),
      itemId: _economyAsInt(json['item_id']),
      categoryKey: json['category_key']?.toString() ?? 'frames',
      name: json['name']?.toString() ?? 'عنصر',
      previewAssetPath:
          json['preview_asset_path']?.toString() ??
          'assets/images/profile_store_frames_preview_overlay.png',
      dialogPreviewAssetPath: json['dialog_preview_asset_path']?.toString(),
      durationDays: _economyAsInt(json['duration_days'], fallback: 7),
      status: json['status']?.toString() ?? 'active',
      isEquipped: json['is_equipped'] == true,
      acquiredVia: json['acquired_via']?.toString() ?? 'purchase',
      expiresAtLabel: json['expires_at_label']?.toString() ?? '20/10/2024',
    );
  }
}

abstract class ProfileEconomyRepository {
  static ProfileEconomyRepository instance = LiveProfileEconomyRepository();

  Future<WalletDashboardData> loadWalletDashboard();

  Future<WalletDashboardData> topUpWallet({required int packageId});

  Future<WalletRecordsPayload> loadWalletRecords();

  Future<WalletRecordsPayload> loadHistory({required String walletType});

  Future<StoreCatalogData> loadStoreCatalog({required String categoryKey});

  Future<List<StoreRecipientData>> loadStoreRecipients({String query = ''});

  Future<EconomyWalletData> purchaseStoreItem({
    required int itemId,
    required int durationDays,
  });

  Future<EconomyWalletData> sendStoreItem({
    required int itemId,
    required int durationDays,
    required String recipientName,
    int? recipientUserId,
  });

  Future<List<BagInventoryItemData>> loadBagItems({required String group});

  Future<BagInventoryItemData> equipBagItem({required int inventoryId});

  Future<BagInventoryItemData> unequipBagItem({required int inventoryId});

  Future<void> removeBagItem({required int inventoryId});
}

final class LiveProfileEconomyRepository implements ProfileEconomyRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<WalletDashboardData> loadWalletDashboard() async {
    final response = await _client.get(
      '/economy/wallet',
      bearerToken: _authStore.authToken,
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final packages = Map<String, dynamic>.from(data['packages'] as Map);

    return WalletDashboardData(
      wallet: EconomyWalletData.fromJson(
        Map<String, dynamic>.from(data['wallet'] as Map),
      ),
      diamondPackages: (packages['diamonds'] as List? ?? const <dynamic>[])
          .map(
            (item) => WalletPackageData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      coinPackages: (packages['coins'] as List? ?? const <dynamic>[])
          .map(
            (item) => WalletPackageData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<WalletDashboardData> topUpWallet({required int packageId}) async {
    final response = await _client.post(
      '/economy/wallet/top-up',
      bearerToken: _authStore.authToken,
      body: {'package_id': packageId},
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final packages = Map<String, dynamic>.from(data['packages'] as Map);

    return WalletDashboardData(
      wallet: EconomyWalletData.fromJson(
        Map<String, dynamic>.from(data['wallet'] as Map),
      ),
      diamondPackages: (packages['diamonds'] as List? ?? const <dynamic>[])
          .map(
            (item) => WalletPackageData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      coinPackages: (packages['coins'] as List? ?? const <dynamic>[])
          .map(
            (item) => WalletPackageData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<WalletRecordsPayload> loadWalletRecords() async {
    final response = await _client.get(
      '/economy/wallet/records',
      bearerToken: _authStore.authToken,
    );
    return _recordsPayloadFromResponse(response);
  }

  @override
  Future<WalletRecordsPayload> loadHistory({required String walletType}) async {
    final response = await _client.get(
      '/economy/history?wallet_type=$walletType',
      bearerToken: _authStore.authToken,
    );
    return _recordsPayloadFromResponse(response, key: 'entries');
  }

  @override
  Future<StoreCatalogData> loadStoreCatalog({
    required String categoryKey,
  }) async {
    final response = await _client.get(
      '/economy/store/catalog?category=$categoryKey',
      bearerToken: _authStore.authToken,
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return StoreCatalogData(
      categoryKey: data['category_key']?.toString() ?? categoryKey,
      items: (data['items'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                StoreItemData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<List<StoreRecipientData>> loadStoreRecipients({
    String query = '',
  }) async {
    final response = await _client.get(
      '/economy/store/recipients?query=${Uri.encodeQueryComponent(query)}',
      bearerToken: _authStore.authToken,
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return (data['recipients'] as List? ?? const <dynamic>[])
        .map(
          (item) => StoreRecipientData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<EconomyWalletData> purchaseStoreItem({
    required int itemId,
    required int durationDays,
  }) async {
    final response = await _client.post(
      '/economy/store/purchase',
      bearerToken: _authStore.authToken,
      body: {'item_id': itemId, 'duration_days': durationDays},
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return EconomyWalletData.fromJson(
      Map<String, dynamic>.from(data['wallet'] as Map),
    );
  }

  @override
  Future<EconomyWalletData> sendStoreItem({
    required int itemId,
    required int durationDays,
    required String recipientName,
    int? recipientUserId,
  }) async {
    final response = await _client.post(
      '/economy/store/send',
      bearerToken: _authStore.authToken,
      body: {
        'item_id': itemId,
        'duration_days': durationDays,
        'recipient_user_id': recipientUserId,
        'recipient_name': recipientName,
      },
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return EconomyWalletData.fromJson(
      Map<String, dynamic>.from(data['wallet'] as Map),
    );
  }

  @override
  Future<List<BagInventoryItemData>> loadBagItems({
    required String group,
  }) async {
    final response = await _client.get(
      '/economy/bag?group=$group',
      bearerToken: _authStore.authToken,
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return (data['items'] as List? ?? const <dynamic>[])
        .map(
          (item) => BagInventoryItemData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<BagInventoryItemData> equipBagItem({required int inventoryId}) async {
    final response = await _client.post(
      '/economy/bag/equip',
      bearerToken: _authStore.authToken,
      body: {'inventory_id': inventoryId},
    );
    return BagInventoryItemData.fromJson(
      Map<String, dynamic>.from(
        (response['data'] as Map<String, dynamic>)['item'] as Map,
      ),
    );
  }

  @override
  Future<BagInventoryItemData> unequipBagItem({
    required int inventoryId,
  }) async {
    final response = await _client.post(
      '/economy/bag/unequip',
      bearerToken: _authStore.authToken,
      body: {'inventory_id': inventoryId},
    );
    return BagInventoryItemData.fromJson(
      Map<String, dynamic>.from(
        (response['data'] as Map<String, dynamic>)['item'] as Map,
      ),
    );
  }

  @override
  Future<void> removeBagItem({required int inventoryId}) async {
    await _client.post(
      '/economy/bag/remove',
      bearerToken: _authStore.authToken,
      body: {'inventory_id': inventoryId},
    );
  }

  WalletRecordsPayload _recordsPayloadFromResponse(
    Map<String, dynamic> response, {
    String key = 'records',
  }) {
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return WalletRecordsPayload(
      wallet: EconomyWalletData.fromJson(
        Map<String, dynamic>.from(data['wallet'] as Map),
      ),
      records: (data[key] as List? ?? const <dynamic>[])
          .map(
            (item) => WalletRecordData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

final class FakeProfileEconomyRepository implements ProfileEconomyRepository {
  EconomyWalletData _wallet = const EconomyWalletData(
    coinsBalance: 1235,
    diamondsBalance: 5,
  );

  late final List<WalletPackageData> _diamondPackages = <WalletPackageData>[
    const WalletPackageData(
      id: 1,
      walletType: 'diamonds',
      amount: 30990,
      bonusAmount: 0,
      priceLabel: '2,894,99 ج.م',
    ),
    const WalletPackageData(
      id: 2,
      walletType: 'diamonds',
      amount: 6090,
      bonusAmount: 0,
      priceLabel: '578,99 ج.م',
    ),
    const WalletPackageData(
      id: 3,
      walletType: 'diamonds',
      amount: 600,
      bonusAmount: 300,
      priceLabel: '57,99 ج.م',
    ),
  ];

  late final List<WalletPackageData> _coinPackages = <WalletPackageData>[
    const WalletPackageData(
      id: 4,
      walletType: 'coins',
      amount: 5000,
      bonusAmount: 0,
      priceLabel: '500',
    ),
    const WalletPackageData(
      id: 5,
      walletType: 'coins',
      amount: 1000,
      bonusAmount: 0,
      priceLabel: '100',
    ),
    const WalletPackageData(
      id: 6,
      walletType: 'coins',
      amount: 100,
      bonusAmount: 0,
      priceLabel: '10',
    ),
  ];

  final List<WalletRecordData> _records = <WalletRecordData>[
    const WalletRecordData(
      id: 1,
      walletType: 'coins',
      direction: 'credit',
      amount: 200,
      status: 'success',
      title: 'تم الشحن بنجاح',
      subtitle: 'شحن 200 عملة الآن',
      dateLabel: '20/10/2024',
      timeLabel: '10:55',
    ),
    const WalletRecordData(
      id: 2,
      walletType: 'coins',
      direction: 'debit',
      amount: 90,
      status: 'success',
      title: 'تم شراء العنصر',
      subtitle: 'شراء الاطار القوي لمدة 3 أيام',
      dateLabel: '20/10/2024',
      timeLabel: '10:59',
    ),
    const WalletRecordData(
      id: 3,
      walletType: 'diamonds',
      direction: 'credit',
      amount: 5,
      status: 'success',
      title: 'تبادل الحبوب الي الماس',
      subtitle: 'تبادل الحبوب الي الماس',
      dateLabel: '20/10/2024',
      timeLabel: '11:03',
    ),
  ];

  late final Map<String, List<StoreItemData>>
  _catalog = <String, List<StoreItemData>>{
    'frames': <StoreItemData>[
      _buildStoreItem(
        1,
        'frames',
        'الاطار القوي',
        'assets/images/profile_store_frames_preview_overlay.png',
        dialogIconAssetPath:
            'assets/images/profile_store_frames_dialog_icon.png',
      ),
    ],
    'animated_frames': <StoreItemData>[
      _buildStoreItem(
        2,
        'animated_frames',
        'رسم ادوات',
        'assets/images/profile_store_animated_frames_item.png',
        dialogIconAssetPath:
            'assets/images/profile_store_animated_frames_dialog_icon.png',
        dialogPreviewAssetPath:
            'assets/images/profile_store_animated_frames_dialog_preview.png',
      ),
    ],
    'backgrounds': <StoreItemData>[
      _buildStoreItem(
        3,
        'backgrounds',
        'خلفية روم ذهبية',
        'assets/images/profile_store_background_preview.png',
      ),
    ],
    'chat_frames': <StoreItemData>[
      _buildStoreItem(
        4,
        'chat_frames',
        'اطار محادثة فاخر',
        'assets/images/profile_store_chat_frames_item.png',
      ),
    ],
    'entry_effects': <StoreItemData>[
      _buildStoreItem(
        5,
        'entry_effects',
        'الاطار المتحرك السريع',
        'assets/images/profile_store_entry_effects_fast_frame_item.png',
        dialogIconAssetPath:
            'assets/images/profile_store_entry_effects_fast_frame_dialog_icon.png',
        dialogPreviewAssetPath:
            'assets/images/profile_store_entry_effects_fast_frame_dialog_preview.png',
      ),
    ],
    'aristocracy': <StoreItemData>[
      _buildStoreItem(
        6,
        'aristocracy',
        'شارة الاستقراطية',
        'assets/images/profile_store_aristocracy_icon.png',
        dialogIconAssetPath: 'assets/images/profile_store_aristocracy_icon.png',
        dialogPreviewAssetPath:
            'assets/images/profile_store_aristocracy_icon.png',
      ),
    ],
  };

  final List<StoreRecipientData> _recipients = const <StoreRecipientData>[
    StoreRecipientData(
      id: 100,
      name: 'Mohamed Ahmed',
      avatarAssetPath: 'assets/images/profile_store_friend_yara_alt.png',
    ),
    StoreRecipientData(
      id: 101,
      name: 'Yara Mohamed',
      avatarAssetPath: 'assets/images/profile_store_friend_yara.png',
    ),
    StoreRecipientData(
      id: 102,
      name: 'Nona Mohamed',
      avatarAssetPath: 'assets/images/profile_store_friend_nona_frame.png',
      innerAvatarAssetPath:
          'assets/images/profile_store_friend_nona_avatar.png',
    ),
  ];

  final List<BagInventoryItemData> _inventory = <BagInventoryItemData>[
    const BagInventoryItemData(
      id: 1,
      itemId: 2,
      categoryKey: 'animated_frames',
      name: 'رسم ادوات',
      previewAssetPath: 'assets/images/profile_store_animated_frames_item.png',
      dialogPreviewAssetPath:
          'assets/images/profile_store_animated_frames_dialog_preview.png',
      durationDays: 7,
      status: 'active',
      isEquipped: true,
      acquiredVia: 'purchase',
      expiresAtLabel: '20/10/2024',
    ),
    const BagInventoryItemData(
      id: 2,
      itemId: 1,
      categoryKey: 'frames',
      name: 'الاطار القوي',
      previewAssetPath:
          'assets/images/profile_store_frames_preview_overlay.png',
      durationDays: 7,
      status: 'active',
      isEquipped: false,
      acquiredVia: 'purchase',
      expiresAtLabel: '20/10/2024',
    ),
    const BagInventoryItemData(
      id: 3,
      itemId: 4,
      categoryKey: 'chat_frames',
      name: 'اطار محادثة فاخر',
      previewAssetPath: 'assets/images/profile_store_chat_frames_item.png',
      durationDays: 7,
      status: 'active',
      isEquipped: false,
      acquiredVia: 'purchase',
      expiresAtLabel: '20/10/2024',
    ),
    const BagInventoryItemData(
      id: 4,
      itemId: 3,
      categoryKey: 'backgrounds',
      name: 'خلفية روم ذهبية',
      previewAssetPath: 'assets/images/profile_store_background_preview.png',
      durationDays: 7,
      status: 'active',
      isEquipped: false,
      acquiredVia: 'purchase',
      expiresAtLabel: '20/10/2024',
    ),
    const BagInventoryItemData(
      id: 5,
      itemId: 5,
      categoryKey: 'entry_effects',
      name: 'الاطار المتحرك السريع',
      previewAssetPath:
          'assets/images/profile_store_entry_effects_fast_frame_item.png',
      dialogPreviewAssetPath:
          'assets/images/profile_store_entry_effects_fast_frame_dialog_preview.png',
      durationDays: 7,
      status: 'active',
      isEquipped: false,
      acquiredVia: 'purchase',
      expiresAtLabel: '20/10/2024',
    ),
    const BagInventoryItemData(
      id: 6,
      itemId: 6,
      categoryKey: 'aristocracy',
      name: 'شارة الاستقراطية',
      previewAssetPath: 'assets/images/profile_store_aristocracy_icon.png',
      dialogPreviewAssetPath:
          'assets/images/profile_store_aristocracy_icon.png',
      durationDays: 7,
      status: 'active',
      isEquipped: false,
      acquiredVia: 'purchase',
      expiresAtLabel: '20/10/2024',
    ),
  ];
  int _nextInventoryId = 7;

  @override
  Future<WalletDashboardData> loadWalletDashboard() async {
    return WalletDashboardData(
      wallet: _wallet,
      diamondPackages: _diamondPackages,
      coinPackages: _coinPackages,
    );
  }

  @override
  Future<WalletDashboardData> topUpWallet({required int packageId}) async {
    final allPackages = <WalletPackageData>[
      ..._diamondPackages,
      ..._coinPackages,
    ];
    final package = allPackages.firstWhere((item) => item.id == packageId);
    if (package.walletType == 'coins') {
      _wallet = EconomyWalletData(
        coinsBalance: _wallet.coinsBalance + package.totalAmount,
        diamondsBalance: _wallet.diamondsBalance,
      );
    } else {
      _wallet = EconomyWalletData(
        coinsBalance: _wallet.coinsBalance,
        diamondsBalance: _wallet.diamondsBalance + package.totalAmount,
      );
    }

    _records.insert(
      0,
      WalletRecordData(
        id: _records.length + 1,
        walletType: package.walletType,
        direction: 'credit',
        amount: package.totalAmount,
        status: 'success',
        title: 'تم الشحن بنجاح',
        subtitle:
            'شحن ${package.totalAmount} ${package.walletType == 'coins' ? 'عملة' : 'ماسة'} الآن',
        dateLabel: '20/10/2024',
        timeLabel: '11:00',
      ),
    );

    return loadWalletDashboard();
  }

  @override
  Future<WalletRecordsPayload> loadWalletRecords() async {
    return WalletRecordsPayload(wallet: _wallet, records: List.of(_records));
  }

  @override
  Future<WalletRecordsPayload> loadHistory({required String walletType}) async {
    return WalletRecordsPayload(
      wallet: _wallet,
      records: _records.where((item) => item.walletType == walletType).toList(),
    );
  }

  @override
  Future<StoreCatalogData> loadStoreCatalog({
    required String categoryKey,
  }) async {
    return StoreCatalogData(
      categoryKey: categoryKey,
      items: List.of(_catalog[categoryKey] ?? const <StoreItemData>[]),
    );
  }

  @override
  Future<List<StoreRecipientData>> loadStoreRecipients({
    String query = '',
  }) async {
    if (query.trim().isEmpty) {
      return List.of(_recipients);
    }

    return _recipients
        .where(
          (item) =>
              item.name.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
  }

  @override
  Future<EconomyWalletData> purchaseStoreItem({
    required int itemId,
    required int durationDays,
  }) async {
    final item = _findItem(itemId);
    final duration = item.durations.firstWhere(
      (entry) => entry.days == durationDays,
    );
    _wallet = EconomyWalletData(
      coinsBalance: _wallet.coinsBalance - duration.price,
      diamondsBalance: _wallet.diamondsBalance,
    );
    _inventory.insert(
      0,
      BagInventoryItemData(
        id: _nextInventoryId++,
        itemId: item.id,
        categoryKey: item.categoryKey,
        name: item.name,
        previewAssetPath: item.previewAssetPath,
        dialogPreviewAssetPath: item.dialogPreviewAssetPath,
        durationDays: durationDays,
        status: 'active',
        isEquipped: false,
        acquiredVia: 'purchase',
        expiresAtLabel: '20/10/2024',
      ),
    );
    _records.insert(
      0,
      WalletRecordData(
        id: _records.length + 1,
        walletType: 'coins',
        direction: 'debit',
        amount: duration.price,
        status: 'success',
        title: 'تم شراء العنصر',
        subtitle: 'شراء ${item.name} لمدة $durationDays أيام',
        dateLabel: '20/10/2024',
        timeLabel: '11:05',
      ),
    );
    return _wallet;
  }

  @override
  Future<EconomyWalletData> sendStoreItem({
    required int itemId,
    required int durationDays,
    required String recipientName,
    int? recipientUserId,
  }) async {
    final item = _findItem(itemId);
    final duration = item.durations.firstWhere(
      (entry) => entry.days == durationDays,
    );
    _wallet = EconomyWalletData(
      coinsBalance: _wallet.coinsBalance - duration.price,
      diamondsBalance: _wallet.diamondsBalance,
    );
    _records.insert(
      0,
      WalletRecordData(
        id: _records.length + 1,
        walletType: 'coins',
        direction: 'debit',
        amount: duration.price,
        status: 'success',
        title: 'تم الإرسال بنجاح',
        subtitle: 'إرسال ${item.name} إلى $recipientName',
        dateLabel: '20/10/2024',
        timeLabel: '11:08',
      ),
    );
    return _wallet;
  }

  @override
  Future<List<BagInventoryItemData>> loadBagItems({
    required String group,
  }) async {
    final categories = switch (group) {
      'animated' => <String>['animated_frames'],
      'entry_effects' => <String>['entry_effects'],
      _ => <String>['frames', 'backgrounds', 'chat_frames', 'aristocracy'],
    };

    return _inventory
        .where((item) => categories.contains(item.categoryKey))
        .toList();
  }

  @override
  Future<BagInventoryItemData> equipBagItem({required int inventoryId}) async {
    final target = _inventory.firstWhere((item) => item.id == inventoryId);
    final group = switch (target.categoryKey) {
      'animated_frames' => 'animated_frames',
      'entry_effects' => 'entry_effects',
      _ => 'art',
    };

    for (var index = 0; index < _inventory.length; index += 1) {
      final item = _inventory[index];
      final sameGroup = group == 'art'
          ? <String>[
              'frames',
              'backgrounds',
              'chat_frames',
              'aristocracy',
            ].contains(item.categoryKey)
          : item.categoryKey == group;
      if (!sameGroup) {
        continue;
      }

      _inventory[index] = BagInventoryItemData(
        id: item.id,
        itemId: item.itemId,
        categoryKey: item.categoryKey,
        name: item.name,
        previewAssetPath: item.previewAssetPath,
        dialogPreviewAssetPath: item.dialogPreviewAssetPath,
        durationDays: item.durationDays,
        status: item.status,
        isEquipped: item.id == inventoryId,
        acquiredVia: item.acquiredVia,
        expiresAtLabel: item.expiresAtLabel,
      );
    }

    return _inventory.firstWhere((item) => item.id == inventoryId);
  }

  @override
  Future<BagInventoryItemData> unequipBagItem({
    required int inventoryId,
  }) async {
    final index = _inventory.indexWhere((item) => item.id == inventoryId);
    final item = _inventory[index];
    _inventory[index] = BagInventoryItemData(
      id: item.id,
      itemId: item.itemId,
      categoryKey: item.categoryKey,
      name: item.name,
      previewAssetPath: item.previewAssetPath,
      dialogPreviewAssetPath: item.dialogPreviewAssetPath,
      durationDays: item.durationDays,
      status: item.status,
      isEquipped: false,
      acquiredVia: item.acquiredVia,
      expiresAtLabel: item.expiresAtLabel,
    );
    return _inventory[index];
  }

  @override
  Future<void> removeBagItem({required int inventoryId}) async {
    _inventory.removeWhere((item) => item.id == inventoryId);
  }

  StoreItemData _findItem(int itemId) {
    return _catalog.values
        .expand((items) => items)
        .firstWhere((item) => item.id == itemId);
  }

  static StoreItemData _buildStoreItem(
    int id,
    String categoryKey,
    String name,
    String previewAssetPath, {
    String? dialogIconAssetPath,
    String? dialogPreviewAssetPath,
  }) {
    return StoreItemData(
      id: id,
      categoryKey: categoryKey,
      name: name,
      previewAssetPath: previewAssetPath,
      dialogIconAssetPath: dialogIconAssetPath,
      dialogPreviewAssetPath: dialogPreviewAssetPath,
      currencyType: 'coins',
      defaultDurationDays: 7,
      durations: const <StoreDurationOptionData>[
        StoreDurationOptionData(days: 3, price: 90, discount: '10% Off'),
        StoreDurationOptionData(days: 7, price: 180, discount: '22% Off'),
        StoreDurationOptionData(days: 15, price: 330, discount: '27% Off'),
        StoreDurationOptionData(days: 30, price: 540, discount: '27% Off'),
      ],
    );
  }
}

int _economyAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
