import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class LiveFeedRoomData {
  const LiveFeedRoomData({
    required this.id,
    required this.title,
    required this.posterAsset,
    required this.viewerCount,
    this.hostUserId,
    this.hostName = '',
    this.relationshipStatus = 'none',
  });

  final int id;
  final String title;
  final String posterAsset;
  final int viewerCount;
  final int? hostUserId;
  final String hostName;
  final String relationshipStatus;

  factory LiveFeedRoomData.fromJson(Map<String, dynamic> json) {
    final relationship = Map<String, dynamic>.from(
      json['relationship'] as Map? ?? const <String, dynamic>{},
    );
    return LiveFeedRoomData(
      id: _liveAsInt(json['id']),
      title: json['title']?.toString() ?? 'مداهم 777',
      posterAsset:
          json['poster_asset']?.toString() ?? 'assets/images/home149_card1.png',
      viewerCount: _liveAsInt(json['viewer_count']),
      hostUserId: json['host_user_id'] == null
          ? null
          : _liveAsInt(json['host_user_id']),
      hostName: json['host_name']?.toString() ?? '',
      relationshipStatus: relationship['status']?.toString() ?? 'none',
    );
  }
}

class LiveCommentData {
  const LiveCommentData({
    required this.id,
    required this.userId,
    required this.name,
    required this.message,
    required this.avatarAsset,
  });

  final int id;
  final int? userId;
  final String name;
  final String message;
  final String avatarAsset;

  factory LiveCommentData.fromJson(Map<String, dynamic> json) {
    return LiveCommentData(
      id: _liveAsInt(json['id']),
      userId: json['user_id'] == null ? null : _liveAsInt(json['user_id']),
      name: json['name']?.toString() ?? 'Mohamed Ahmed',
      message: json['message']?.toString() ?? '',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/live150_comment_avatar.png',
    );
  }
}

class LiveViewerData {
  const LiveViewerData({
    required this.id,
    required this.rank,
    required this.name,
    required this.avatarAsset,
    required this.isTopSupporter,
  });

  final int id;
  final int rank;
  final String name;
  final String avatarAsset;
  final bool isTopSupporter;

  factory LiveViewerData.fromJson(Map<String, dynamic> json) {
    return LiveViewerData(
      id: _liveAsInt(json['id']),
      rank: _liveAsInt(json['rank'], fallback: 1),
      name: json['name']?.toString() ?? 'Mohamed Ahmed',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/live150_comment_avatar.png',
      isTopSupporter: json['is_top_supporter'] == true,
    );
  }
}

class LiveContributionEntryData {
  const LiveContributionEntryData({
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

  factory LiveContributionEntryData.fromJson(Map<String, dynamic> json) {
    return LiveContributionEntryData(
      rank: _liveAsInt(json['rank'], fallback: 1),
      name: json['name']?.toString() ?? 'Mohamed Ahmed',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      totalCoins: _liveAsInt(json['total_coins']),
      coinsLabel: json['coins_label']?.toString() ?? '0 Coin',
      isTopSupporter: json['is_top_supporter'] == true,
    );
  }
}

class LivePkSettingsData {
  const LivePkSettingsData({
    required this.talkPermission,
    required this.partyInvitePermission,
    required this.voiceRoomInvitePermission,
    required this.chatPermission,
    required this.battleDuration,
  });

  final String talkPermission;
  final String partyInvitePermission;
  final String voiceRoomInvitePermission;
  final String chatPermission;
  final String battleDuration;

  factory LivePkSettingsData.fromJson(Map<String, dynamic> json) {
    return LivePkSettingsData(
      talkPermission: json['talk_permission']?.toString() ?? 'عند الطلب',
      partyInvitePermission:
          json['party_invite_permission']?.toString() ?? 'عند الطلب',
      voiceRoomInvitePermission:
          json['voice_room_invite_permission']?.toString() ?? 'عند الطلب',
      chatPermission: json['chat_permission']?.toString() ?? 'عند الطلب',
      battleDuration: json['battle_duration']?.toString() ?? '30د',
    );
  }
}

class LivePkStateData {
  const LivePkStateData({
    required this.status,
    required this.activeInviteId,
    required this.guestUserId,
    required this.guestName,
    required this.startedAt,
    required this.endsAt,
    this.hostTapCount = 0,
    this.guestTapCount = 0,
    this.hostScore = 0,
    this.guestScore = 0,
    this.secondsRemaining = 0,
    this.winnerSide = '',
  });

  final String status;
  final int? activeInviteId;
  final int? guestUserId;
  final String guestName;
  final String startedAt;
  final String endsAt;
  final int hostTapCount;
  final int guestTapCount;
  final int hostScore;
  final int guestScore;
  final int secondsRemaining;
  final String winnerSide;

  bool get isMatching => status == 'matching';
  bool get isActive => status == 'active';
  bool get isPkVisible => isMatching || isActive;

  factory LivePkStateData.fromJson(Map<String, dynamic> json) {
    return LivePkStateData(
      status: json['status']?.toString() ?? 'idle',
      activeInviteId: json['active_invite_id'] == null
          ? null
          : _liveAsInt(json['active_invite_id']),
      guestUserId: json['guest_user_id'] == null
          ? null
          : _liveAsInt(json['guest_user_id']),
      guestName: json['guest_name']?.toString() ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      endsAt: json['ends_at']?.toString() ?? '',
      hostTapCount: _liveAsInt(json['host_tap_count']),
      guestTapCount: _liveAsInt(json['guest_tap_count']),
      hostScore: _liveAsInt(json['host_score']),
      guestScore: _liveAsInt(json['guest_score']),
      secondsRemaining: _liveAsInt(json['seconds_remaining']),
      winnerSide: json['winner_side']?.toString() ?? '',
    );
  }

  LivePkStateData copyWith({
    String? status,
    int? activeInviteId,
    int? guestUserId,
    String? guestName,
    String? startedAt,
    String? endsAt,
    int? hostTapCount,
    int? guestTapCount,
    int? hostScore,
    int? guestScore,
    int? secondsRemaining,
    String? winnerSide,
  }) {
    return LivePkStateData(
      status: status ?? this.status,
      activeInviteId: activeInviteId ?? this.activeInviteId,
      guestUserId: guestUserId ?? this.guestUserId,
      guestName: guestName ?? this.guestName,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      hostTapCount: hostTapCount ?? this.hostTapCount,
      guestTapCount: guestTapCount ?? this.guestTapCount,
      hostScore: hostScore ?? this.hostScore,
      guestScore: guestScore ?? this.guestScore,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      winnerSide: winnerSide ?? this.winnerSide,
    );
  }
}

class LivePkInviteData {
  const LivePkInviteData({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.senderName,
    required this.status,
    required this.createdAtLabel,
  });

  final int id;
  final int roomId;
  final String roomTitle;
  final String senderName;
  final String status;
  final String createdAtLabel;

  factory LivePkInviteData.fromJson(Map<String, dynamic> json) {
    return LivePkInviteData(
      id: _liveAsInt(json['id']),
      roomId: _liveAsInt(json['room_id']),
      roomTitle: json['room_title']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'sent',
      createdAtLabel: json['created_at_label']?.toString() ?? '',
    );
  }
}

class LiveGiftItemData {
  const LiveGiftItemData({
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

  factory LiveGiftItemData.fromJson(Map<String, dynamic> json) {
    return LiveGiftItemData(
      id: _liveAsInt(json['id'], fallback: 1),
      name: json['name']?.toString() ?? 'الهدية الصغيرة',
      category: json['category']?.toString() ?? 'الهداية عادية',
      assetPath:
          json['asset_path']?.toString() ?? 'assets/images/room_gift_1.png',
      priceCoins: _liveAsInt(json['price_coins'], fallback: 10),
      animationPath: json['animation_path']?.toString() ?? '',
      soundPath: json['sound_path']?.toString() ?? '',
      isAnimated:
          json['is_animated'] == true ||
          _liveAsInt(json['is_animated'], fallback: 0) == 1,
      effectDurationMs: _liveAsInt(json['effect_duration_ms'], fallback: 1800),
    );
  }
}

class LiveGiftEventData {
  const LiveGiftEventData({
    required this.id,
    required this.senderName,
    required this.senderAvatarAsset,
    required this.gift,
    required this.quantity,
    required this.totalPriceCoins,
    required this.createdAtLabel,
  });

  final int id;
  final String senderName;
  final String senderAvatarAsset;
  final LiveGiftItemData gift;
  final int quantity;
  final int totalPriceCoins;
  final String createdAtLabel;

  factory LiveGiftEventData.fromJson(Map<String, dynamic> json) {
    return LiveGiftEventData(
      id: _liveAsInt(json['id']),
      senderName: json['sender_name']?.toString() ?? 'Mohamed Ahmed',
      senderAvatarAsset:
          json['sender_avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      gift: LiveGiftItemData.fromJson(
        Map<String, dynamic>.from(
          (json['gift'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      quantity: _liveAsInt(json['quantity'], fallback: 1),
      totalPriceCoins: _liveAsInt(json['total_price_coins']),
      createdAtLabel: json['created_at_label']?.toString() ?? '',
    );
  }
}

class LiveGiftPanelData {
  const LiveGiftPanelData({
    required this.walletCoinsBalance,
    required this.walletDiamondsBalance,
    required this.isGuest,
    required this.gifts,
  });

  final int walletCoinsBalance;
  final int walletDiamondsBalance;
  final bool isGuest;
  final List<LiveGiftItemData> gifts;

  LiveGiftPanelData copyWith({
    int? walletCoinsBalance,
    int? walletDiamondsBalance,
    bool? isGuest,
    List<LiveGiftItemData>? gifts,
  }) {
    return LiveGiftPanelData(
      walletCoinsBalance: walletCoinsBalance ?? this.walletCoinsBalance,
      walletDiamondsBalance:
          walletDiamondsBalance ?? this.walletDiamondsBalance,
      isGuest: isGuest ?? this.isGuest,
      gifts: gifts ?? this.gifts,
    );
  }
}

class LiveGiftSendResult {
  const LiveGiftSendResult({required this.panel, required this.room});

  final LiveGiftPanelData panel;
  final LiveRoomDetailsData room;
}

class LiveNotificationData {
  const LiveNotificationData({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.title,
    required this.message,
    required this.createdAtLabel,
  });

  final int id;
  final int roomId;
  final String roomTitle;
  final String title;
  final String message;
  final String createdAtLabel;

  factory LiveNotificationData.fromJson(Map<String, dynamic> json) {
    return LiveNotificationData(
      id: _liveAsInt(json['id']),
      roomId: _liveAsInt(json['room_id']),
      roomTitle: json['room_title']?.toString() ?? '',
      title: json['title']?.toString() ?? json['title_text']?.toString() ?? '',
      message:
          json['message']?.toString() ?? json['body_text']?.toString() ?? '',
      createdAtLabel: json['created_at_label']?.toString() ?? '',
    );
  }
}

class LivePkRecipientData {
  const LivePkRecipientData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatarAsset,
  });

  final int id;
  final String name;
  final String subtitle;
  final String avatarAsset;

  factory LivePkRecipientData.fromJson(Map<String, dynamic> json) {
    return LivePkRecipientData(
      id: _liveAsInt(json['id']),
      name: json['name']?.toString() ?? 'Mohamed Ahmed',
      subtitle: json['subtitle']?.toString() ?? '@live',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
    );
  }
}

class LiveActionButtonData {
  const LiveActionButtonData({
    required this.id,
    required this.sectionKey,
    required this.sectionTitle,
    required this.actionKey,
    required this.label,
    required this.iconKind,
    required this.iconAsset,
    required this.behavior,
    required this.detailTitle,
    required this.detailBody,
    required this.requiresHost,
  });

  final int id;
  final String sectionKey;
  final String sectionTitle;
  final String actionKey;
  final String label;
  final String iconKind;
  final String iconAsset;
  final String behavior;
  final String detailTitle;
  final String detailBody;
  final bool requiresHost;

  factory LiveActionButtonData.fromJson(Map<String, dynamic> json) {
    return LiveActionButtonData(
      id: _liveAsInt(json['id']),
      sectionKey: json['section_key']?.toString() ?? 'broadcast',
      sectionTitle: json['section_title']?.toString() ?? 'ادارة البث',
      actionKey: json['action_key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      iconKind: json['icon_kind']?.toString() ?? 'sparkles',
      iconAsset: json['icon_asset']?.toString() ?? '',
      behavior: json['behavior']?.toString() ?? 'custom',
      detailTitle: json['detail_title']?.toString() ?? '',
      detailBody: json['detail_body']?.toString() ?? '',
      requiresHost:
          json['requires_host'] == true ||
          _liveAsInt(json['requires_host'], fallback: 0) == 1,
    );
  }
}

class LiveActionSectionData {
  const LiveActionSectionData({required this.title, required this.actions});

  final String title;
  final List<LiveActionButtonData> actions;

  factory LiveActionSectionData.fromJson(Map<String, dynamic> json) {
    return LiveActionSectionData(
      title: json['title']?.toString() ?? 'ادارة البث',
      actions: (json['actions'] as List? ?? const <dynamic>[])
          .map(
            (item) => LiveActionButtonData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  static const List<LiveActionSectionData> defaults = [
    LiveActionSectionData(
      title: 'ادارة البث',
      actions: [
        LiveActionButtonData(
          id: 1,
          sectionKey: 'broadcast',
          sectionTitle: 'ادارة البث',
          actionKey: 'beauty',
          label: 'جمال',
          iconKind: 'beauty',
          iconAsset: 'assets/images/live153_beauty.png',
          behavior: 'beauty',
          detailTitle: 'جمال البث',
          detailBody: 'تفعيل تحسينات الصورة أثناء البث.',
          requiresHost: true,
        ),
        LiveActionButtonData(
          id: 2,
          sectionKey: 'broadcast',
          sectionTitle: 'ادارة البث',
          actionKey: 'sticker',
          label: 'ملصق',
          iconKind: 'sticker',
          iconAsset: 'assets/images/live153_sticker.png',
          behavior: 'sticker',
          detailTitle: 'ملصقات اللايف',
          detailBody: 'اختر ملصقات البث من لوحة التحكم.',
          requiresHost: true,
        ),
        LiveActionButtonData(
          id: 3,
          sectionKey: 'broadcast',
          sectionTitle: 'ادارة البث',
          actionKey: 'interface',
          label: 'واجهة',
          iconKind: 'interface',
          iconAsset: '',
          behavior: 'interface',
          detailTitle: 'واجهة البث',
          detailBody: 'إدارة مظهر واجهة اللايف.',
          requiresHost: true,
        ),
        LiveActionButtonData(
          id: 4,
          sectionKey: 'broadcast',
          sectionTitle: 'ادارة البث',
          actionKey: 'mute',
          label: 'كتم الصوت',
          iconKind: 'mute',
          iconAsset: '',
          behavior: 'mute',
          detailTitle: 'كتم الصوت',
          detailBody: 'تشغيل أو إيقاف صوت اللايف.',
          requiresHost: false,
        ),
      ],
    ),
    LiveActionSectionData(
      title: 'ادارة الغرفة',
      actions: [
        LiveActionButtonData(
          id: 5,
          sectionKey: 'room',
          sectionTitle: 'ادارة الغرفة',
          actionKey: 'room_notice',
          label: 'نشرة الغرفة',
          iconKind: 'announcement',
          iconAsset: '',
          behavior: 'notifications',
          detailTitle: 'نشرة الغرفة',
          detailBody: 'عرض إشعارات ونشرات اللايف.',
          requiresHost: false,
        ),
        LiveActionButtonData(
          id: 6,
          sectionKey: 'room',
          sectionTitle: 'ادارة الغرفة',
          actionKey: 'new_user',
          label: 'مستخدم جديد',
          iconKind: 'new_user',
          iconAsset: '',
          behavior: 'viewers',
          detailTitle: 'المشاهدون',
          detailBody: 'عرض قائمة المشاهدين الحاليين.',
          requiresHost: false,
        ),
        LiveActionButtonData(
          id: 7,
          sectionKey: 'room',
          sectionTitle: 'ادارة الغرفة',
          actionKey: 'room_admin',
          label: 'مسؤول الغرفة',
          iconKind: 'admin',
          iconAsset: '',
          behavior: 'room_admin',
          detailTitle: 'مسؤول الغرفة',
          detailBody: 'إدارة صلاحيات ومسؤولي اللايف من لوحة التحكم.',
          requiresHost: true,
        ),
        LiveActionButtonData(
          id: 8,
          sectionKey: 'room',
          sectionTitle: 'ادارة الغرفة',
          actionKey: 'entry_rank',
          label: 'القيمة في ترتيب\nالدخولية',
          iconKind: 'ranking',
          iconAsset: '',
          behavior: 'supporters',
          detailTitle: 'ترتيب الدخولية',
          detailBody: 'عرض ترتيب الداعمين والمساهمات.',
          requiresHost: false,
        ),
      ],
    ),
    LiveActionSectionData(
      title: 'مركز الالعاب',
      actions: [
        LiveActionButtonData(
          id: 9,
          sectionKey: 'games',
          sectionTitle: 'مركز الالعاب',
          actionKey: 'valorant_1',
          label: 'Valorant',
          iconKind: 'game',
          iconAsset: 'assets/images/live153_game.png',
          behavior: 'game',
          detailTitle: 'Valorant',
          detailBody: 'تم فتح لعبة اللايف. يمكن تعديل الألعاب من الأدمن.',
          requiresHost: false,
        ),
        LiveActionButtonData(
          id: 10,
          sectionKey: 'games',
          sectionTitle: 'مركز الالعاب',
          actionKey: 'valorant_2',
          label: 'Valorant',
          iconKind: 'game',
          iconAsset: 'assets/images/live153_game.png',
          behavior: 'game',
          detailTitle: 'Valorant',
          detailBody: 'تم فتح لعبة اللايف. يمكن تعديل الألعاب من الأدمن.',
          requiresHost: false,
        ),
        LiveActionButtonData(
          id: 11,
          sectionKey: 'games',
          sectionTitle: 'مركز الالعاب',
          actionKey: 'valorant_3',
          label: 'Valorant',
          iconKind: 'game',
          iconAsset: 'assets/images/live153_game.png',
          behavior: 'game',
          detailTitle: 'Valorant',
          detailBody: 'تم فتح لعبة اللايف. يمكن تعديل الألعاب من الأدمن.',
          requiresHost: false,
        ),
        LiveActionButtonData(
          id: 12,
          sectionKey: 'games',
          sectionTitle: 'مركز الالعاب',
          actionKey: 'valorant_4',
          label: 'Valorant',
          iconKind: 'game',
          iconAsset: 'assets/images/live153_game.png',
          behavior: 'game',
          detailTitle: 'Valorant',
          detailBody: 'تم فتح لعبة اللايف. يمكن تعديل الألعاب من الأدمن.',
          requiresHost: false,
        ),
        LiveActionButtonData(
          id: 13,
          sectionKey: 'games',
          sectionTitle: 'مركز الالعاب',
          actionKey: 'valorant_5',
          label: 'Valorant',
          iconKind: 'game',
          iconAsset: 'assets/images/live153_game.png',
          behavior: 'game',
          detailTitle: 'Valorant',
          detailBody: 'تم فتح لعبة اللايف. يمكن تعديل الألعاب من الأدمن.',
          requiresHost: false,
        ),
      ],
    ),
  ];
}

class LiveActionResultData {
  const LiveActionResultData({
    required this.eventId,
    required this.action,
    required this.message,
  });

  final int eventId;
  final LiveActionButtonData action;
  final String message;

  factory LiveActionResultData.fromJson(Map<String, dynamic> json) {
    return LiveActionResultData(
      eventId: _liveAsInt(json['event_id']),
      action: LiveActionButtonData.fromJson(
        Map<String, dynamic>.from(
          (json['action'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      message: json['message']?.toString() ?? 'تم تنفيذ الأمر.',
    );
  }
}

class LiveRtcSessionData {
  const LiveRtcSessionData({
    required this.enabled,
    required this.configured,
    required this.usesTokens,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.tokenExpiresInSeconds,
    required this.userAccount,
    required this.role,
    required this.clientRole,
  });

  final bool enabled;
  final bool configured;
  final bool usesTokens;
  final String appId;
  final String channelName;
  final String token;
  final int tokenExpiresInSeconds;
  final String userAccount;
  final String role;
  final String clientRole;

  bool get isBroadcaster => clientRole == 'broadcaster';

  factory LiveRtcSessionData.fromJson(Map<String, dynamic> json) {
    return LiveRtcSessionData(
      enabled: json['enabled'] == true || _liveAsInt(json['enabled']) == 1,
      configured:
          json['configured'] == true || _liveAsInt(json['configured']) == 1,
      usesTokens:
          json['uses_tokens'] == true || _liveAsInt(json['uses_tokens']) == 1,
      appId: json['app_id']?.toString() ?? '',
      channelName: json['channel_name']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      tokenExpiresInSeconds: _liveAsInt(
        json['token_expires_in_seconds'],
        fallback: 3600,
      ),
      userAccount: json['user_account']?.toString() ?? '',
      role: json['role']?.toString() ?? 'viewer',
      clientRole: json['client_role']?.toString() ?? 'audience',
    );
  }
}

class LiveRoomDetailsData {
  const LiveRoomDetailsData({
    required this.id,
    required this.title,
    required this.hostName,
    required this.hostIdLabel,
    required this.hostUserId,
    required this.hostAvatarAsset,
    required this.videoEnabled,
    required this.agoraChannelName,
    required this.status,
    required this.endedAt,
    required this.viewerCount,
    required this.coinCount,
    required this.backgroundAsset,
    required this.leftVideoAsset,
    required this.rightVideoAsset,
    required this.battleTimerLabel,
    required this.contributionDiamondsTotal,
    required this.contributionSenderCount,
    required this.pkSettings,
    required this.pkState,
    required this.viewers,
    required this.comments,
    required this.supporters,
    required this.recentGifts,
  });

  final int id;
  final String title;
  final String hostName;
  final String hostIdLabel;
  final int? hostUserId;
  final String hostAvatarAsset;
  final bool videoEnabled;
  final String agoraChannelName;
  final String status;
  final String endedAt;
  final int viewerCount;
  final int coinCount;
  final String backgroundAsset;
  final String leftVideoAsset;
  final String rightVideoAsset;
  final String battleTimerLabel;
  final int contributionDiamondsTotal;
  final int contributionSenderCount;
  final LivePkSettingsData pkSettings;
  final LivePkStateData pkState;
  final List<LiveViewerData> viewers;
  final List<LiveCommentData> comments;
  final List<LiveContributionEntryData> supporters;
  final List<LiveGiftEventData> recentGifts;

  factory LiveRoomDetailsData.fromJson(Map<String, dynamic> json) {
    return LiveRoomDetailsData(
      id: _liveAsInt(json['id']),
      title: json['title']?.toString() ?? 'مداهم 777',
      hostName: json['host_name']?.toString() ?? 'Mohamed Ahmed',
      hostIdLabel: json['host_id_label']?.toString() ?? 'ID:1512345412',
      hostUserId: json['host_user_id'] == null
          ? null
          : _liveAsInt(json['host_user_id']),
      hostAvatarAsset:
          json['host_avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      videoEnabled:
          json['video_enabled'] == true ||
          _liveAsInt(json['video_enabled'], fallback: 1) == 1,
      agoraChannelName: json['agora_channel_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      endedAt: json['ended_at']?.toString() ?? '',
      viewerCount: _liveAsInt(json['viewer_count']),
      coinCount: _liveAsInt(json['coin_count']),
      backgroundAsset:
          json['background_asset']?.toString() ??
          'assets/images/live150_background.png',
      leftVideoAsset:
          json['left_video_asset']?.toString() ??
          'assets/images/live150_video_left.png',
      rightVideoAsset:
          json['right_video_asset']?.toString() ??
          'assets/images/live150_video_right.png',
      battleTimerLabel: json['battle_timer_label']?.toString() ?? '11:50',
      contributionDiamondsTotal: _liveAsInt(
        json['contribution_diamonds_total'],
      ),
      contributionSenderCount: _liveAsInt(json['contribution_sender_count']),
      pkSettings: LivePkSettingsData.fromJson(
        Map<String, dynamic>.from(
          (json['pk_settings'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      pkState: LivePkStateData.fromJson(
        Map<String, dynamic>.from(
          (json['pk_state'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      viewers: (json['viewers'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                LiveViewerData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      comments: (json['comments'] as List? ?? const <dynamic>[])
          .map(
            (item) => LiveCommentData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      supporters: (json['supporters'] as List? ?? const <dynamic>[])
          .map(
            (item) => LiveContributionEntryData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      recentGifts: (json['recent_gifts'] as List? ?? const <dynamic>[])
          .map(
            (item) => LiveGiftEventData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  LiveRoomDetailsData copyWith({
    bool? videoEnabled,
    String? status,
    String? endedAt,
    int? viewerCount,
    LivePkSettingsData? pkSettings,
    LivePkStateData? pkState,
    List<LiveViewerData>? viewers,
    List<LiveCommentData>? comments,
    List<LiveContributionEntryData>? supporters,
    List<LiveGiftEventData>? recentGifts,
    int? contributionDiamondsTotal,
    int? contributionSenderCount,
    int? coinCount,
  }) {
    return LiveRoomDetailsData(
      id: id,
      title: title,
      hostName: hostName,
      hostIdLabel: hostIdLabel,
      hostUserId: hostUserId,
      hostAvatarAsset: hostAvatarAsset,
      videoEnabled: videoEnabled ?? this.videoEnabled,
      agoraChannelName: agoraChannelName,
      status: status ?? this.status,
      endedAt: endedAt ?? this.endedAt,
      viewerCount: viewerCount ?? this.viewerCount,
      coinCount: coinCount ?? this.coinCount,
      backgroundAsset: backgroundAsset,
      leftVideoAsset: leftVideoAsset,
      rightVideoAsset: rightVideoAsset,
      battleTimerLabel: battleTimerLabel,
      contributionDiamondsTotal:
          contributionDiamondsTotal ?? this.contributionDiamondsTotal,
      contributionSenderCount:
          contributionSenderCount ?? this.contributionSenderCount,
      pkSettings: pkSettings ?? this.pkSettings,
      pkState: pkState ?? this.pkState,
      viewers: viewers ?? this.viewers,
      comments: comments ?? this.comments,
      supporters: supporters ?? this.supporters,
      recentGifts: recentGifts ?? this.recentGifts,
    );
  }
}

abstract class LiveRepository {
  static LiveRepository instance = LiveLiveRepository();

  Future<List<LiveFeedRoomData>> listRooms({
    required String scope,
    String query = '',
  });

  Future<LiveRoomDetailsData> createRoom({required String title});

  Future<LiveRoomDetailsData> getRoom({required int roomId});

  Future<LiveRtcSessionData> joinRtc({required int roomId});

  Future<LiveRtcSessionData> renewRtcToken({required int roomId});

  Future<void> heartbeatRtc({required int roomId});

  Future<void> leaveRtc({required int roomId});

  Future<void> endRoom({required int roomId});

  Future<LiveRoomDetailsData> updatePkSettings({
    required int roomId,
    required LivePkSettingsData settings,
  });

  Future<LiveRoomDetailsData> startPkMatching({required int roomId});

  Future<LiveRoomDetailsData> endPkBattle({required int roomId});

  Future<LiveRoomDetailsData> sendPkTap({
    required int roomId,
    required String side,
  });

  Future<LiveRoomDetailsData> sendComment({
    required int roomId,
    required String messageText,
  });

  Future<List<LiveNotificationData>> listNotifications({int? roomId});

  Future<LiveGiftPanelData> loadGiftPanel({required int roomId});

  Future<LiveGiftSendResult> sendGift({
    required int roomId,
    required int giftId,
    required int quantity,
  });

  Future<void> reportRoom({required int roomId, required String reason});

  Future<List<LivePkRecipientData>> listPkRecipients({String query = ''});

  Future<List<LivePkInviteData>> listPkInvites();

  Future<List<LiveActionSectionData>> listActionSections();

  Future<LiveActionResultData> triggerAction({
    required int roomId,
    required LiveActionButtonData action,
  });

  Future<void> sendPkInvite({
    required int roomId,
    required int recipientUserId,
  });

  Future<LiveRoomDetailsData> acceptPkInvite({required int inviteId});

  Future<void> rejectPkInvite({required int inviteId});
}

final class LiveLiveRepository implements LiveRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<List<LiveFeedRoomData>> listRooms({
    required String scope,
    String query = '',
  }) async {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final response = await _client.get(
      '/live/rooms?scope=$scope&query=$encodedQuery',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['rooms'] as List? ?? const <dynamic>[])
        .map(
          (item) =>
              LiveFeedRoomData.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<LiveRoomDetailsData> createRoom({required String title}) async {
    final response = await _client.post(
      '/live/rooms',
      bearerToken: _authStore.authToken,
      body: {'title': title},
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  @override
  Future<LiveRoomDetailsData> getRoom({required int roomId}) async {
    final response = await _client.get(
      '/live/rooms/$roomId',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  @override
  Future<LiveRtcSessionData> joinRtc({required int roomId}) async {
    final response = await _client.post(
      '/live/rooms/$roomId/rtc/join',
      bearerToken: _authStore.authToken,
    );
    return LiveRtcSessionData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<LiveRtcSessionData> renewRtcToken({required int roomId}) async {
    final response = await _client.get(
      '/live/rooms/$roomId/rtc/token',
      bearerToken: _authStore.authToken,
    );
    return LiveRtcSessionData.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  @override
  Future<void> heartbeatRtc({required int roomId}) async {
    await _client.post(
      '/live/rooms/$roomId/rtc/heartbeat',
      bearerToken: _authStore.authToken,
    );
  }

  @override
  Future<void> leaveRtc({required int roomId}) async {
    await _client.post(
      '/live/rooms/$roomId/rtc/leave',
      bearerToken: _authStore.authToken,
    );
  }

  @override
  Future<void> endRoom({required int roomId}) async {
    await _client.post(
      '/live/rooms/$roomId/end',
      bearerToken: _authStore.authToken,
    );
  }

  @override
  Future<LiveRoomDetailsData> updatePkSettings({
    required int roomId,
    required LivePkSettingsData settings,
  }) async {
    final response = await _client.post(
      '/live/rooms/$roomId/pk-settings',
      bearerToken: _authStore.authToken,
      body: {
        'talk_permission': settings.talkPermission,
        'party_invite_permission': settings.partyInvitePermission,
        'voice_room_invite_permission': settings.voiceRoomInvitePermission,
        'chat_permission': settings.chatPermission,
        'battle_duration': settings.battleDuration,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  @override
  Future<LiveRoomDetailsData> startPkMatching({required int roomId}) async {
    final response = await _client.post(
      '/live/rooms/$roomId/pk-matching/start',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  @override
  Future<LiveRoomDetailsData> endPkBattle({required int roomId}) async {
    final response = await _client.post(
      '/live/rooms/$roomId/pk/end',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  @override
  Future<LiveRoomDetailsData> sendPkTap({
    required int roomId,
    required String side,
  }) async {
    final response = await _client.post(
      '/live/rooms/$roomId/pk/tap',
      bearerToken: _authStore.authToken,
      body: {'side': side},
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  @override
  Future<LiveRoomDetailsData> sendComment({
    required int roomId,
    required String messageText,
  }) async {
    final response = await _client.post(
      '/live/rooms/$roomId/comments',
      bearerToken: _authStore.authToken,
      body: {'message_text': messageText},
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  @override
  Future<List<LiveNotificationData>> listNotifications({int? roomId}) async {
    final path = roomId == null
        ? '/live/notifications'
        : '/live/rooms/$roomId/notifications';
    final response = await _client.get(path, bearerToken: _authStore.authToken);
    final data = response['data'] as Map<String, dynamic>;
    return (data['notifications'] as List? ?? const <dynamic>[])
        .map(
          (item) => LiveNotificationData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<LiveGiftPanelData> loadGiftPanel({required int roomId}) async {
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

    return LiveGiftPanelData(
      walletCoinsBalance: _liveAsInt(
        walletData['coins_balance'],
        fallback: 1235,
      ),
      walletDiamondsBalance: _liveAsInt(
        walletData['diamonds_balance'],
        fallback: 5,
      ),
      isGuest: walletData['is_guest'] == true,
      gifts: (catalogData['gifts'] as List? ?? const <dynamic>[])
          .map(
            (item) => LiveGiftItemData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<LiveGiftSendResult> sendGift({
    required int roomId,
    required int giftId,
    required int quantity,
  }) async {
    final response = await _client.post(
      '/live/rooms/$roomId/gifts/send',
      bearerToken: _authStore.authToken,
      body: {'gift_id': giftId, 'quantity': quantity},
    );
    final data = response['data'] as Map<String, dynamic>;
    final wallet = data['wallet'] as Map<String, dynamic>;
    final room = LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
    final panel = await loadGiftPanel(roomId: roomId);

    return LiveGiftSendResult(
      panel: panel.copyWith(
        walletCoinsBalance: _liveAsInt(wallet['coins_balance'], fallback: 1235),
        walletDiamondsBalance: _liveAsInt(
          wallet['diamonds_balance'],
          fallback: 5,
        ),
        isGuest: wallet['is_guest'] == true,
      ),
      room: room,
    );
  }

  @override
  Future<void> reportRoom({required int roomId, required String reason}) async {
    await _client.post(
      '/live/rooms/$roomId/report',
      bearerToken: _authStore.authToken,
      body: {'reason': reason},
    );
  }

  @override
  Future<List<LivePkRecipientData>> listPkRecipients({
    String query = '',
  }) async {
    final response = await _client.get(
      '/live/pk/recipients?query=${Uri.encodeQueryComponent(query)}',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['recipients'] as List? ?? const <dynamic>[])
        .map(
          (item) => LivePkRecipientData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<List<LivePkInviteData>> listPkInvites() async {
    final response = await _client.get(
      '/live/pk/invites?status=sent',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['invites'] as List? ?? const <dynamic>[])
        .map(
          (item) =>
              LivePkInviteData.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<List<LiveActionSectionData>> listActionSections() async {
    final response = await _client.get(
      '/live/action-buttons',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    final sections = (data['sections'] as List? ?? const <dynamic>[])
        .map(
          (item) => LiveActionSectionData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    return sections.isEmpty ? LiveActionSectionData.defaults : sections;
  }

  @override
  Future<LiveActionResultData> triggerAction({
    required int roomId,
    required LiveActionButtonData action,
  }) async {
    final response = await _client.post(
      '/live/rooms/$roomId/actions',
      bearerToken: _authStore.authToken,
      body: {'action_key': action.actionKey, 'action_id': action.id},
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveActionResultData.fromJson(data);
  }

  @override
  Future<void> sendPkInvite({
    required int roomId,
    required int recipientUserId,
  }) async {
    await _client.post(
      '/live/rooms/$roomId/pk-invites',
      bearerToken: _authStore.authToken,
      body: {'recipient_user_id': recipientUserId},
    );
  }

  @override
  Future<LiveRoomDetailsData> acceptPkInvite({required int inviteId}) async {
    final response = await _client.post(
      '/live/pk/invites/$inviteId/accept',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return LiveRoomDetailsData.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  @override
  Future<void> rejectPkInvite({required int inviteId}) async {
    await _client.post(
      '/live/pk/invites/$inviteId/reject',
      bearerToken: _authStore.authToken,
    );
  }
}

final class FakeLiveRepository implements LiveRepository {
  final List<LiveFeedRoomData> _rooms = <LiveFeedRoomData>[
    LiveFeedRoomData(
      id: 1,
      title: 'مداهم 777',
      posterAsset: 'assets/images/home149_card1.png',
      viewerCount: 393,
    ),
    LiveFeedRoomData(
      id: 2,
      title: 'هاي عاملين ايه',
      posterAsset: 'assets/images/home149_card2.png',
      viewerCount: 188,
    ),
    LiveFeedRoomData(
      id: 3,
      title: 'مساء الخير يا جماعة',
      posterAsset: 'assets/images/home149_card3.png',
      viewerCount: 126,
    ),
    LiveFeedRoomData(
      id: 4,
      title: 'لايف بنات مصر',
      posterAsset: 'assets/images/home149_card4.png',
      viewerCount: 210,
    ),
    LiveFeedRoomData(
      id: 5,
      title: 'سهرة اليوم',
      posterAsset: 'assets/images/home149_card7.png',
      viewerCount: 95,
    ),
    LiveFeedRoomData(
      id: 6,
      title: 'نجوم اللايف',
      posterAsset: 'assets/images/home149_card8.png',
      viewerCount: 241,
    ),
  ];

  final Map<int, LiveRoomDetailsData> _details = <int, LiveRoomDetailsData>{};
  final List<LiveNotificationData> _notifications = const [
    LiveNotificationData(
      id: 1,
      roomId: 1,
      roomTitle: 'مداهم 777',
      title: 'اعلان الجولة',
      message: 'ابدأوا التفاعل الآن والجولة الحالية مفتوحة لمدة 15 دقيقة.',
      createdAtLabel: '2026-04-20 19:30',
    ),
    LiveNotificationData(
      id: 2,
      roomId: 1,
      roomTitle: 'مداهم 777',
      title: 'تنبيه اداري',
      message: 'يمنع نشر أي محتوى مخالف داخل الدردشة المباشرة.',
      createdAtLabel: '2026-04-20 19:28',
    ),
  ];
  final List<LiveGiftItemData> _gifts = const [
    LiveGiftItemData(
      id: 1,
      name: 'الهدية الصغيرة',
      category: 'الهداية عادية',
      assetPath: 'assets/images/room_gift_1.png',
      priceCoins: 10,
    ),
    LiveGiftItemData(
      id: 2,
      name: 'الهدية الصغيرة',
      category: 'VIP',
      assetPath: 'assets/images/room_gift_5.png',
      priceCoins: 20,
    ),
  ];
  final List<LivePkRecipientData> _recipients = const [
    LivePkRecipientData(
      id: 11,
      name: 'Yara Mohamed',
      subtitle: '201000000101',
      avatarAsset: 'assets/images/profile_avatar.png',
    ),
    LivePkRecipientData(
      id: 12,
      name: 'Nona Mohamed',
      subtitle: '201000000102',
      avatarAsset: 'assets/images/profile_avatar.png',
    ),
  ];
  int _walletCoins = 1235;
  int _nextGiftEventId = 100;

  FakeLiveRepository() {
    _details[1] = LiveRoomDetailsData(
      id: 1,
      title: 'مداهم 777',
      hostName: 'Mohamed Ahmed',
      hostIdLabel: 'ID:1512345412',
      hostUserId: null,
      hostAvatarAsset: 'assets/images/profile_avatar.png',
      videoEnabled: true,
      agoraChannelName: 'live-room-1',
      status: 'active',
      endedAt: '',
      viewerCount: 393,
      coinCount: 214,
      backgroundAsset: 'assets/images/live150_background.png',
      leftVideoAsset: 'assets/images/live150_video_left.png',
      rightVideoAsset: 'assets/images/live150_video_right.png',
      battleTimerLabel: '11:50',
      contributionDiamondsTotal: 230,
      contributionSenderCount: 3,
      pkSettings: const LivePkSettingsData(
        talkPermission: 'عند الطلب',
        partyInvitePermission: 'عند الطلب',
        voiceRoomInvitePermission: 'عند الطلب',
        chatPermission: 'عند الطلب',
        battleDuration: '30د',
      ),
      pkState: const LivePkStateData(
        status: 'idle',
        activeInviteId: null,
        guestUserId: null,
        guestName: '',
        startedAt: '',
        endsAt: '',
      ),
      viewers: const [
        LiveViewerData(
          id: 1,
          rank: 1,
          name: 'Mohammed Ahmed',
          avatarAsset: 'assets/images/live150_comment_avatar.png',
          isTopSupporter: true,
        ),
        LiveViewerData(
          id: 2,
          rank: 2,
          name: 'Sara Mohamed',
          avatarAsset: 'assets/images/live150_comment_avatar.png',
          isTopSupporter: false,
        ),
        LiveViewerData(
          id: 3,
          rank: 3,
          name: 'Nona Mohamed',
          avatarAsset: 'assets/images/live150_comment_avatar.png',
          isTopSupporter: false,
        ),
        LiveViewerData(
          id: 4,
          rank: 4,
          name: 'Yara Mohamed',
          avatarAsset: 'assets/images/live150_comment_avatar.png',
          isTopSupporter: false,
        ),
      ],
      comments: const [
        LiveCommentData(
          id: 1,
          userId: 3,
          name: 'Mohamed Ahmed',
          message: 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات',
          avatarAsset: 'assets/images/live150_comment_avatar.png',
        ),
        LiveCommentData(
          id: 2,
          userId: null,
          name: 'Sara Mohamed',
          message: 'لايف جميل جدا استمروا',
          avatarAsset: 'assets/images/live150_comment_avatar.png',
        ),
      ],
      supporters: const [
        LiveContributionEntryData(
          rank: 1,
          name: 'Mohammed Ahmed',
          avatarAsset: 'assets/images/profile_avatar.png',
          totalCoins: 100,
          coinsLabel: '100 Coin',
          isTopSupporter: true,
        ),
        LiveContributionEntryData(
          rank: 2,
          name: 'Sara Mohamed',
          avatarAsset: 'assets/images/profile_avatar.png',
          totalCoins: 80,
          coinsLabel: '80 Coin',
          isTopSupporter: false,
        ),
      ],
      recentGifts: const [],
    );

    for (final room in _rooms.skip(1)) {
      _details[room.id] = LiveRoomDetailsData(
        id: room.id,
        title: room.title,
        hostName: 'Host ${room.id}',
        hostIdLabel: 'ID:15123454${room.id}0',
        hostUserId: null,
        hostAvatarAsset: 'assets/images/profile_avatar.png',
        videoEnabled: true,
        agoraChannelName: 'live-room-${room.id}',
        status: 'active',
        endedAt: '',
        viewerCount: room.viewerCount,
        coinCount: 80 + room.id,
        backgroundAsset: 'assets/images/live150_background.png',
        leftVideoAsset: 'assets/images/live150_video_left.png',
        rightVideoAsset: 'assets/images/live150_video_right.png',
        battleTimerLabel: '11:50',
        contributionDiamondsTotal: 0,
        contributionSenderCount: 0,
        pkSettings: const LivePkSettingsData(
          talkPermission: 'عند الطلب',
          partyInvitePermission: 'عند الطلب',
          voiceRoomInvitePermission: 'عند الطلب',
          chatPermission: 'عند الطلب',
          battleDuration: '30د',
        ),
        pkState: const LivePkStateData(
          status: 'idle',
          activeInviteId: null,
          guestUserId: null,
          guestName: '',
          startedAt: '',
          endsAt: '',
        ),
        viewers: const [],
        comments: const [],
        supporters: const [],
        recentGifts: const [],
      );
    }
  }

  @override
  Future<List<LiveFeedRoomData>> listRooms({
    required String scope,
    String query = '',
  }) async {
    Iterable<LiveFeedRoomData> result;
    if (scope == 'friends') {
      result = _rooms.where((room) => room.id == 2 || room.id == 4);
    } else if (scope == 'newest') {
      result = _rooms.reversed;
    } else {
      result = _rooms;
    }

    if (query.trim().isNotEmpty) {
      result = result.where((room) => room.title.contains(query.trim()));
    }

    return result.toList();
  }

  @override
  Future<LiveRoomDetailsData> createRoom({required String title}) async {
    final nextId =
        (_rooms.map((room) => room.id).fold<int>(0, (a, b) => a > b ? a : b)) +
        1;
    final normalizedTitle = title.trim().isEmpty
        ? 'لايف Hallo Party'
        : title.trim();
    final card = LiveFeedRoomData(
      id: nextId,
      title: normalizedTitle,
      posterAsset: 'assets/images/home149_card1.png',
      viewerCount: 1,
    );
    _rooms.insert(0, card);
    final details = LiveRoomDetailsData(
      id: nextId,
      title: normalizedTitle,
      hostName: 'Gift Smoke',
      hostIdLabel: 'ID:1',
      hostUserId: 1,
      hostAvatarAsset: 'assets/images/profile_avatar.png',
      videoEnabled: true,
      agoraChannelName: 'live-video-fake-$nextId',
      status: 'active',
      endedAt: '',
      viewerCount: 1,
      coinCount: 0,
      backgroundAsset: 'assets/images/live150_background.png',
      leftVideoAsset: 'assets/images/live150_video_left.png',
      rightVideoAsset: 'assets/images/live150_video_right.png',
      battleTimerLabel: '11:50',
      contributionDiamondsTotal: 0,
      contributionSenderCount: 0,
      pkSettings: const LivePkSettingsData(
        talkPermission: 'عند الطلب',
        partyInvitePermission: 'عند الطلب',
        voiceRoomInvitePermission: 'عند الطلب',
        chatPermission: 'عند الطلب',
        battleDuration: '30د',
      ),
      pkState: const LivePkStateData(
        status: 'idle',
        activeInviteId: null,
        guestUserId: null,
        guestName: '',
        startedAt: '',
        endsAt: '',
      ),
      viewers: const [
        LiveViewerData(
          id: 1,
          rank: 1,
          name: 'Gift Smoke',
          avatarAsset: 'assets/images/profile_avatar.png',
          isTopSupporter: false,
        ),
      ],
      comments: const [],
      supporters: const [],
      recentGifts: const [],
    );
    _details[nextId] = details;
    return details;
  }

  @override
  Future<LiveRoomDetailsData> getRoom({required int roomId}) async {
    return _details[roomId] ?? _details.values.first;
  }

  @override
  Future<LiveRtcSessionData> joinRtc({required int roomId}) async {
    final room = _details[roomId] ?? _details.values.first;
    final isBroadcaster = room.hostUserId != null;
    return LiveRtcSessionData(
      enabled: room.videoEnabled,
      configured: false,
      usesTokens: false,
      appId: '',
      channelName: room.agoraChannelName,
      token: '',
      tokenExpiresInSeconds: 3600,
      userAccount: 'fake-live-user',
      role: isBroadcaster ? 'host' : 'viewer',
      clientRole: isBroadcaster ? 'broadcaster' : 'audience',
    );
  }

  @override
  Future<LiveRtcSessionData> renewRtcToken({required int roomId}) {
    return joinRtc(roomId: roomId);
  }

  @override
  Future<void> heartbeatRtc({required int roomId}) async {}

  @override
  Future<void> leaveRtc({required int roomId}) async {}

  @override
  Future<void> endRoom({required int roomId}) async {
    final current = _details[roomId];
    if (current == null) {
      return;
    }

    _rooms.removeWhere((room) => room.id == roomId);
    _details[roomId] = current.copyWith(
      status: 'hidden',
      endedAt: DateTime.now().toIso8601String(),
      videoEnabled: false,
      viewerCount: 0,
    );
  }

  @override
  Future<LiveRoomDetailsData> updatePkSettings({
    required int roomId,
    required LivePkSettingsData settings,
  }) async {
    final current = _details[roomId] ?? _details.values.first;
    final updated = current.copyWith(pkSettings: settings);
    _details[roomId] = updated;
    return updated;
  }

  @override
  Future<LiveRoomDetailsData> startPkMatching({required int roomId}) async {
    final current = _details[roomId] ?? _details.values.first;
    final updated = current.copyWith(
      pkState: const LivePkStateData(
        status: 'matching',
        activeInviteId: null,
        guestUserId: null,
        guestName: '',
        startedAt: '',
        endsAt: '',
      ),
    );
    _details[roomId] = updated;
    return updated;
  }

  @override
  Future<LiveRoomDetailsData> endPkBattle({required int roomId}) async {
    final current = _details[roomId] ?? _details.values.first;
    final updated = current.copyWith(
      pkState: const LivePkStateData(
        status: 'idle',
        activeInviteId: null,
        guestUserId: null,
        guestName: '',
        startedAt: '',
        endsAt: '',
      ),
    );
    _details[roomId] = updated;
    return updated;
  }

  @override
  Future<LiveRoomDetailsData> sendPkTap({
    required int roomId,
    required String side,
  }) async {
    final current = _details[roomId] ?? _details.values.first;
    final currentState = current.pkState;
    final updatedState = currentState.copyWith(
      hostTapCount: side == 'host'
          ? currentState.hostTapCount + 1
          : currentState.hostTapCount,
      guestTapCount: side == 'guest'
          ? currentState.guestTapCount + 1
          : currentState.guestTapCount,
      hostScore: side == 'host'
          ? currentState.hostScore + 1
          : currentState.hostScore,
      guestScore: side == 'guest'
          ? currentState.guestScore + 1
          : currentState.guestScore,
    );
    final updated = current.copyWith(pkState: updatedState);
    _details[roomId] = updated;
    return updated;
  }

  @override
  Future<LiveRoomDetailsData> sendComment({
    required int roomId,
    required String messageText,
  }) async {
    final current = _details[roomId] ?? _details.values.first;
    final updatedComments = List<LiveCommentData>.from(current.comments)
      ..add(
        LiveCommentData(
          id: current.comments.length + 1,
          userId: _currentUserId(),
          name: 'Gift Smoke',
          message: messageText,
          avatarAsset: 'assets/images/live150_comment_avatar.png',
        ),
      );
    final updated = current.copyWith(comments: updatedComments);
    _details[roomId] = updated;
    return updated;
  }

  int? _currentUserId() {
    final id = AuthFlowStore.instance.currentUser?['id'];
    if (id is int) {
      return id;
    }
    return int.tryParse(id?.toString() ?? '');
  }

  @override
  Future<List<LiveNotificationData>> listNotifications({int? roomId}) async {
    if (roomId == null) {
      return _notifications;
    }
    return _notifications.where((item) => item.roomId == roomId).toList();
  }

  @override
  Future<LiveGiftPanelData> loadGiftPanel({required int roomId}) async {
    return LiveGiftPanelData(
      walletCoinsBalance: _walletCoins,
      walletDiamondsBalance: 5,
      isGuest: false,
      gifts: _gifts,
    );
  }

  @override
  Future<LiveGiftSendResult> sendGift({
    required int roomId,
    required int giftId,
    required int quantity,
  }) async {
    final gift = _gifts.firstWhere((item) => item.id == giftId);
    _walletCoins -= gift.priceCoins * quantity;
    final current = _details[roomId] ?? _details.values.first;
    final updatedSupporters =
        List<LiveContributionEntryData>.from(current.supporters)..insert(
          0,
          LiveContributionEntryData(
            rank: 1,
            name: 'Gift Smoke',
            avatarAsset: 'assets/images/profile_avatar.png',
            totalCoins: gift.priceCoins * quantity,
            coinsLabel: '${gift.priceCoins * quantity} Coin',
            isTopSupporter: true,
          ),
        );
    final giftEvent = LiveGiftEventData(
      id: _nextGiftEventId++,
      senderName: 'Gift Smoke',
      senderAvatarAsset: 'assets/images/profile_avatar.png',
      gift: gift,
      quantity: quantity,
      totalPriceCoins: gift.priceCoins * quantity,
      createdAtLabel: 'الآن',
    );
    final updated = current.copyWith(
      supporters: updatedSupporters,
      recentGifts: [giftEvent, ...current.recentGifts].take(5).toList(),
      contributionDiamondsTotal:
          current.contributionDiamondsTotal + gift.priceCoins * quantity,
      contributionSenderCount: current.contributionSenderCount + 1,
      coinCount: current.coinCount + gift.priceCoins * quantity,
    );
    _details[roomId] = updated;

    return LiveGiftSendResult(
      panel: await loadGiftPanel(roomId: roomId),
      room: updated,
    );
  }

  @override
  Future<void> reportRoom({
    required int roomId,
    required String reason,
  }) async {}

  @override
  Future<List<LivePkRecipientData>> listPkRecipients({
    String query = '',
  }) async {
    if (query.trim().isEmpty) {
      return _recipients;
    }
    return _recipients
        .where((item) => item.name.contains(query.trim()))
        .toList();
  }

  @override
  Future<List<LivePkInviteData>> listPkInvites() async {
    return const [];
  }

  @override
  Future<List<LiveActionSectionData>> listActionSections() async {
    return LiveActionSectionData.defaults;
  }

  @override
  Future<LiveActionResultData> triggerAction({
    required int roomId,
    required LiveActionButtonData action,
  }) async {
    return LiveActionResultData(
      eventId: DateTime.now().millisecondsSinceEpoch,
      action: action,
      message: 'تم تنفيذ ${action.label}',
    );
  }

  @override
  Future<void> sendPkInvite({
    required int roomId,
    required int recipientUserId,
  }) async {
    await startPkMatching(roomId: roomId);
  }

  @override
  Future<LiveRoomDetailsData> acceptPkInvite({required int inviteId}) async {
    final current = _details.values.first;
    final updated = current.copyWith(
      pkState: const LivePkStateData(
        status: 'active',
        activeInviteId: 1,
        guestUserId: 11,
        guestName: 'Yara Mohamed',
        startedAt: '',
        endsAt: '',
      ),
    );
    _details[current.id] = updated;
    return updated;
  }

  @override
  Future<void> rejectPkInvite({required int inviteId}) async {}
}

int _liveAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
