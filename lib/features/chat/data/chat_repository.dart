import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_flow_store.dart';

class ChatThreadData {
  const ChatThreadData({
    required this.id,
    required this.listingGroup,
    required this.threadType,
    required this.title,
    required this.previewText,
    required this.avatarAsset,
    required this.statusColorHex,
    required this.readStyle,
    required this.isPhotoPreview,
    required this.messageDateLabel,
    required this.unreadCount,
    required this.isSystem,
    required this.status,
    this.targetUserId,
  });

  final int id;
  final String listingGroup;
  final String threadType;
  final String title;
  final String previewText;
  final String avatarAsset;
  final String statusColorHex;
  final String readStyle;
  final bool isPhotoPreview;
  final String messageDateLabel;
  final int unreadCount;
  final bool isSystem;
  final String status;
  final int? targetUserId;

  factory ChatThreadData.fromJson(Map<String, dynamic> json) {
    return ChatThreadData(
      id: _chatAsInt(json['id']),
      listingGroup: json['listing_group']?.toString() ?? 'messages',
      threadType: json['thread_type']?.toString() ?? 'direct',
      title: json['title']?.toString() ?? 'محمد احمد',
      previewText: json['preview_text']?.toString() ?? '',
      avatarAsset:
          json['avatar_asset']?.toString() ??
          'assets/images/profile_avatar.png',
      statusColorHex: json['status_color_hex']?.toString() ?? '#34A853',
      readStyle: json['read_style']?.toString() ?? 'none',
      isPhotoPreview: json['is_photo_preview'] == true,
      messageDateLabel: json['message_date_label']?.toString() ?? '11/16/19',
      unreadCount: _chatAsInt(json['unread_count']),
      isSystem: json['is_system'] == true,
      status: json['status']?.toString() ?? 'active',
      targetUserId: json['target_user_id'] == null
          ? null
          : _chatAsInt(json['target_user_id']),
    );
  }

  ChatThreadData copyWith({
    int? id,
    String? listingGroup,
    String? threadType,
    String? title,
    String? previewText,
    String? avatarAsset,
    String? statusColorHex,
    String? readStyle,
    bool? isPhotoPreview,
    String? messageDateLabel,
    int? unreadCount,
    bool? isSystem,
    String? status,
    int? targetUserId,
  }) {
    return ChatThreadData(
      id: id ?? this.id,
      listingGroup: listingGroup ?? this.listingGroup,
      threadType: threadType ?? this.threadType,
      title: title ?? this.title,
      previewText: previewText ?? this.previewText,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      statusColorHex: statusColorHex ?? this.statusColorHex,
      readStyle: readStyle ?? this.readStyle,
      isPhotoPreview: isPhotoPreview ?? this.isPhotoPreview,
      messageDateLabel: messageDateLabel ?? this.messageDateLabel,
      unreadCount: unreadCount ?? this.unreadCount,
      isSystem: isSystem ?? this.isSystem,
      status: status ?? this.status,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }
}

class ChatInboxPayload {
  const ChatInboxPayload({required this.threads});

  final List<ChatThreadData> threads;
}

class ChatMessagesPayload {
  const ChatMessagesPayload({
    required this.systemThreads,
    required this.threads,
  });

  final List<ChatThreadData> systemThreads;
  final List<ChatThreadData> threads;
}

class ChatSearchEntryData {
  const ChatSearchEntryData({
    required this.id,
    required this.label,
    this.targetThreadId,
  });

  final int id;
  final String label;
  final int? targetThreadId;

  factory ChatSearchEntryData.fromJson(Map<String, dynamic> json) {
    return ChatSearchEntryData(
      id: _chatAsInt(json['id']),
      label: json['label']?.toString() ?? '',
      targetThreadId: json['target_thread_id'] == null
          ? null
          : _chatAsInt(json['target_thread_id']),
    );
  }
}

class ChatSearchPayload {
  const ChatSearchPayload({
    required this.query,
    required this.recentSearches,
    required this.results,
  });

  final String query;
  final List<ChatSearchEntryData> recentSearches;
  final List<ChatThreadData> results;
}

class ChatConversationMessageData {
  const ChatConversationMessageData({
    required this.id,
    required this.direction,
    required this.senderName,
    required this.bodyText,
    required this.messageType,
    this.attachmentPath,
    this.attachmentMimeType,
    this.attachmentName,
    required this.timeLabel,
    required this.createdAtLabel,
  });

  final int id;
  final String direction;
  final String senderName;
  final String bodyText;
  final String messageType;
  final String? attachmentPath;
  final String? attachmentMimeType;
  final String? attachmentName;
  final String timeLabel;
  final String createdAtLabel;

  factory ChatConversationMessageData.fromJson(Map<String, dynamic> json) {
    return ChatConversationMessageData(
      id: _chatAsInt(json['id']),
      direction: json['direction']?.toString() ?? 'incoming',
      senderName: json['sender_name']?.toString() ?? 'محمد احمد',
      bodyText: json['body_text']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      attachmentPath: json['attachment_path']?.toString(),
      attachmentMimeType: json['attachment_mime_type']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      timeLabel: json['time_label']?.toString() ?? '11:43',
      createdAtLabel: json['created_at_label']?.toString() ?? 'just now',
    );
  }

  ChatConversationMessageData copyWith({
    int? id,
    String? direction,
    String? senderName,
    String? bodyText,
    String? messageType,
    String? attachmentPath,
    String? attachmentMimeType,
    String? attachmentName,
    String? timeLabel,
    String? createdAtLabel,
  }) {
    return ChatConversationMessageData(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      senderName: senderName ?? this.senderName,
      bodyText: bodyText ?? this.bodyText,
      messageType: messageType ?? this.messageType,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentMimeType: attachmentMimeType ?? this.attachmentMimeType,
      attachmentName: attachmentName ?? this.attachmentName,
      timeLabel: timeLabel ?? this.timeLabel,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
    );
  }
}

class ChatAttachmentDraft {
  const ChatAttachmentDraft({
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

class ChatGiftItemData {
  const ChatGiftItemData({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    required this.priceCoins,
    this.animationPath = '',
    this.soundPath = '',
    this.isAnimated = false,
  });

  final int id;
  final String name;
  final String category;
  final String assetPath;
  final int priceCoins;
  final String animationPath;
  final String soundPath;
  final bool isAnimated;

  factory ChatGiftItemData.fromJson(Map<String, dynamic> json) {
    return ChatGiftItemData(
      id: _chatAsInt(json['id'], fallback: 1),
      name: json['name']?.toString() ?? 'هدية',
      category: json['category']?.toString() ?? 'عام',
      assetPath:
          json['asset_path']?.toString() ?? 'assets/images/room_gift_1.png',
      priceCoins: _chatAsInt(json['price_coins'], fallback: 10),
      animationPath: json['animation_path']?.toString() ?? '',
      soundPath: json['sound_path']?.toString() ?? '',
      isAnimated:
          json['is_animated'] == true ||
          _chatAsInt(json['is_animated'], fallback: 0) == 1,
    );
  }
}

class ChatGiftPanelData {
  const ChatGiftPanelData({
    required this.coinsBalance,
    required this.diamondsBalance,
    required this.isGuest,
    required this.gifts,
  });

  final int coinsBalance;
  final int diamondsBalance;
  final bool isGuest;
  final List<ChatGiftItemData> gifts;
}

class ChatConversationPayload {
  const ChatConversationPayload({
    required this.thread,
    required this.messages,
    required this.currentUserName,
  });

  final ChatThreadData thread;
  final List<ChatConversationMessageData> messages;
  final String currentUserName;
}

abstract class ChatRepository {
  static ChatRepository instance = LiveChatRepository();

  Future<ChatInboxPayload> loadFriendsInbox();

  Future<ChatMessagesPayload> loadMessagesInbox();

  Future<ChatSearchPayload> loadSearch({String query = 'Mo'});

  Future<List<ChatSearchEntryData>> deleteSearchEntry({required int searchId});

  Future<List<ChatSearchEntryData>> rememberSearch({
    required String label,
    int? threadId,
  });

  Future<ChatConversationPayload> loadConversation({int? threadId});

  Future<ChatConversationPayload> openDirectThread({required int userId});

  Future<ChatConversationPayload> sendMessage({
    required int threadId,
    required String bodyText,
    String messageType = 'text',
    ChatAttachmentDraft? attachment,
  });

  Future<ChatGiftPanelData> loadGiftPanel();

  Future<ChatConversationPayload> sendGiftMessage({
    required int threadId,
    required int giftId,
    required int quantity,
  });

  Future<List<ChatThreadData>> loadSelectionThreads();

  Future<int> bulkAction({
    required List<int> threadIds,
    required String action,
  });
}

final class LiveChatRepository implements ChatRepository {
  final ApiClient _client = ApiClient.instance;
  final AuthFlowStore _authStore = AuthFlowStore.instance;

  @override
  Future<ChatInboxPayload> loadFriendsInbox() async {
    final response = await _client.get(
      '/chat/inbox?scope=friends',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ChatInboxPayload(
      threads: (data['threads'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                ChatThreadData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<ChatMessagesPayload> loadMessagesInbox() async {
    final response = await _client.get(
      '/chat/inbox?scope=messages',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ChatMessagesPayload(
      systemThreads: (data['system_threads'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                ChatThreadData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      threads: (data['threads'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                ChatThreadData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<ChatSearchPayload> loadSearch({String query = 'Mo'}) async {
    final response = await _client.get(
      '/chat/search?query=${Uri.encodeQueryComponent(query)}',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ChatSearchPayload(
      query: data['query']?.toString() ?? query,
      recentSearches: (data['recent_searches'] as List? ?? const <dynamic>[])
          .map(
            (item) => ChatSearchEntryData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      results: (data['results'] as List? ?? const <dynamic>[])
          .map(
            (item) =>
                ChatThreadData.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  @override
  Future<List<ChatSearchEntryData>> deleteSearchEntry({
    required int searchId,
  }) async {
    final response = await _client.post(
      '/chat/search/delete',
      body: {'search_id': searchId},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['recent_searches'] as List? ?? const <dynamic>[])
        .map(
          (item) => ChatSearchEntryData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<List<ChatSearchEntryData>> rememberSearch({
    required String label,
    int? threadId,
  }) async {
    final response = await _client.post(
      '/chat/search/remember',
      body: {'label': label, 'thread_id': threadId},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['recent_searches'] as List? ?? const <dynamic>[])
        .map(
          (item) => ChatSearchEntryData.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<ChatConversationPayload> loadConversation({int? threadId}) async {
    var targetThreadId = threadId;
    if (targetThreadId == null) {
      final inbox = await loadMessagesInbox();
      final allThreads = <ChatThreadData>[
        ...inbox.threads,
        ...inbox.systemThreads,
      ];
      if (allThreads.isEmpty) {
        throw Exception('No chat thread is available.');
      }
      targetThreadId = allThreads.first.id;
    }
    final response = await _client.get(
      '/chat/threads/$targetThreadId',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ChatConversationPayload(
      thread: ChatThreadData.fromJson(
        Map<String, dynamic>.from(data['thread'] as Map),
      ),
      messages: (data['messages'] as List? ?? const <dynamic>[])
          .map(
            (item) => ChatConversationMessageData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      currentUserName:
          data['current_user_name']?.toString() ?? 'المستخدم الحالي',
    );
  }

  @override
  Future<ChatConversationPayload> openDirectThread({
    required int userId,
  }) async {
    final response = await _client.post(
      '/chat/direct',
      body: {'user_id': userId},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ChatConversationPayload(
      thread: ChatThreadData.fromJson(
        Map<String, dynamic>.from(data['thread'] as Map),
      ),
      messages: (data['messages'] as List? ?? const <dynamic>[])
          .map(
            (item) => ChatConversationMessageData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      currentUserName:
          data['current_user_name']?.toString() ?? 'المستخدم الحالي',
    );
  }

  @override
  Future<ChatConversationPayload> sendMessage({
    required int threadId,
    required String bodyText,
    String messageType = 'text',
    ChatAttachmentDraft? attachment,
  }) async {
    final response = await _client.post(
      '/chat/threads/$threadId/messages',
      body: {
        'body_text': bodyText,
        'message_type': messageType,
        if (attachment != null) 'attachment_upload': attachment.toJson(),
      },
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ChatConversationPayload(
      thread: ChatThreadData.fromJson(
        Map<String, dynamic>.from(data['thread'] as Map),
      ),
      messages: (data['messages'] as List? ?? const <dynamic>[])
          .map(
            (item) => ChatConversationMessageData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      currentUserName:
          data['current_user_name']?.toString() ?? 'المستخدم الحالي',
    );
  }

  @override
  Future<ChatGiftPanelData> loadGiftPanel() async {
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

    return ChatGiftPanelData(
      coinsBalance: _chatAsInt(walletData['coins_balance'], fallback: 0),
      diamondsBalance: _chatAsInt(walletData['diamonds_balance'], fallback: 0),
      isGuest: walletData['is_guest'] == true,
      gifts: (catalogData['gifts'] as List? ?? const <dynamic>[])
          .map(
            (item) => ChatGiftItemData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<ChatConversationPayload> sendGiftMessage({
    required int threadId,
    required int giftId,
    required int quantity,
  }) async {
    final response = await _client.post(
      '/chat/threads/$threadId/messages',
      body: {
        'body_text': '',
        'message_type': 'gift',
        'gift_id': giftId,
        'quantity': quantity,
      },
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ChatConversationPayload(
      thread: ChatThreadData.fromJson(
        Map<String, dynamic>.from(data['thread'] as Map),
      ),
      messages: (data['messages'] as List? ?? const <dynamic>[])
          .map(
            (item) => ChatConversationMessageData.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      currentUserName:
          data['current_user_name']?.toString() ?? 'المستخدم الحالي',
    );
  }

  @override
  Future<List<ChatThreadData>> loadSelectionThreads() async {
    final response = await _client.get(
      '/chat/selection',
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['threads'] as List? ?? const <dynamic>[])
        .map(
          (item) =>
              ChatThreadData.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<int> bulkAction({
    required List<int> threadIds,
    required String action,
  }) async {
    final response = await _client.post(
      '/chat/threads/bulk',
      body: {'thread_ids': threadIds, 'action': action},
      bearerToken: _authStore.authToken,
    );
    final data = response['data'] as Map<String, dynamic>;
    return _chatAsInt(data['updated_count']);
  }
}

final class FakeChatRepository implements ChatRepository {
  final List<ChatThreadData> _threads = <ChatThreadData>[
    const ChatThreadData(
      id: 1,
      listingGroup: 'friends',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: '',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#EA4335',
      readStyle: 'single',
      isPhotoPreview: false,
      messageDateLabel: '11/16/19',
      unreadCount: 1,
      isSystem: false,
      status: 'active',
    ),
    const ChatThreadData(
      id: 2,
      listingGroup: 'friends',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: 'كيف حالك يارب ان تكون بخير ؟؟',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#34A853',
      readStyle: 'double',
      isPhotoPreview: false,
      messageDateLabel: '11/16/19',
      unreadCount: 0,
      isSystem: false,
      status: 'active',
    ),
    const ChatThreadData(
      id: 3,
      listingGroup: 'friends',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: 'صورة',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#34A853',
      readStyle: 'double',
      isPhotoPreview: true,
      messageDateLabel: '11/16/19',
      unreadCount: 0,
      isSystem: false,
      status: 'active',
    ),
    const ChatThreadData(
      id: 4,
      listingGroup: 'friends',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: '',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#EA4335',
      readStyle: 'single',
      isPhotoPreview: false,
      messageDateLabel: '11/16/19',
      unreadCount: 1,
      isSystem: false,
      status: 'active',
    ),
    const ChatThreadData(
      id: 5,
      listingGroup: 'friends',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: 'كيف حالك يارب ان تكون بخير ؟؟',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#34A853',
      readStyle: 'double',
      isPhotoPreview: false,
      messageDateLabel: '11/16/19',
      unreadCount: 0,
      isSystem: false,
      status: 'active',
    ),
    const ChatThreadData(
      id: 6,
      listingGroup: 'friends',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: 'صورة',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#34A853',
      readStyle: 'double',
      isPhotoPreview: true,
      messageDateLabel: '11/16/19',
      unreadCount: 0,
      isSystem: false,
      status: 'active',
    ),
    const ChatThreadData(
      id: 7,
      listingGroup: 'messages',
      threadType: 'support',
      title: 'خدمه العملاء',
      previewText: 'اي مشكله واجهتك يرجي تخبرني بتفاصيل',
      avatarAsset: 'assets/images/chat_support_icon.png',
      statusColorHex: '#34A853',
      readStyle: 'none',
      isPhotoPreview: false,
      messageDateLabel: '',
      unreadCount: 0,
      isSystem: true,
      status: 'active',
    ),
    const ChatThreadData(
      id: 8,
      listingGroup: 'messages',
      threadType: 'notification',
      title: 'الاشعارات',
      previewText: 'ممكن تعيطي هديه',
      avatarAsset: 'assets/images/chat_notification_icon.png',
      statusColorHex: '#34A853',
      readStyle: 'none',
      isPhotoPreview: false,
      messageDateLabel: '',
      unreadCount: 0,
      isSystem: true,
      status: 'active',
    ),
    const ChatThreadData(
      id: 9,
      listingGroup: 'messages',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: '',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#EA4335',
      readStyle: 'single',
      isPhotoPreview: false,
      messageDateLabel: '11/16/19',
      unreadCount: 1,
      isSystem: false,
      status: 'active',
    ),
    const ChatThreadData(
      id: 10,
      listingGroup: 'messages',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: 'كيف حالك يارب ان تكون بخير ؟؟',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#34A853',
      readStyle: 'double',
      isPhotoPreview: false,
      messageDateLabel: '11/16/19',
      unreadCount: 0,
      isSystem: false,
      status: 'active',
    ),
    const ChatThreadData(
      id: 11,
      listingGroup: 'messages',
      threadType: 'direct',
      title: 'محمد احمد',
      previewText: 'صورة',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#34A853',
      readStyle: 'double',
      isPhotoPreview: true,
      messageDateLabel: '11/16/19',
      unreadCount: 0,
      isSystem: false,
      status: 'active',
    ),
  ];

  final Map<int, List<ChatConversationMessageData>> _messagesByThread =
      <int, List<ChatConversationMessageData>>{
        1: const <ChatConversationMessageData>[
          ChatConversationMessageData(
            id: 1,
            direction: 'incoming',
            senderName: 'محمد احمد',
            bodyText: 'Good bye!',
            messageType: 'text',
            timeLabel: '17:47',
            createdAtLabel: 'just now',
          ),
          ChatConversationMessageData(
            id: 2,
            direction: 'outgoing',
            senderName: 'المستخدم الحالي',
            bodyText: 'Good morning!',
            messageType: 'text',
            timeLabel: '10:10',
            createdAtLabel: 'just now',
          ),
          ChatConversationMessageData(
            id: 3,
            direction: 'incoming',
            senderName: 'محمد احمد',
            bodyText: 'Do you know what time is it?',
            messageType: 'text',
            timeLabel: '11:40',
            createdAtLabel: 'just now',
          ),
          ChatConversationMessageData(
            id: 4,
            direction: 'outgoing',
            senderName: 'المستخدم الحالي',
            bodyText: 'It’s morning in Egypt 😎',
            messageType: 'text',
            timeLabel: '11:43',
            createdAtLabel: 'just now',
          ),
        ],
        7: const <ChatConversationMessageData>[
          ChatConversationMessageData(
            id: 5,
            direction: 'incoming',
            senderName: 'خدمه العملاء',
            bodyText: 'اي مشكله واجهتك يرجي تخبرني بتفاصيل',
            messageType: 'text',
            timeLabel: '09:00',
            createdAtLabel: '1 min ago',
          ),
        ],
        8: const <ChatConversationMessageData>[
          ChatConversationMessageData(
            id: 6,
            direction: 'incoming',
            senderName: 'الاشعارات',
            bodyText: 'ممكن تعيطي هديه',
            messageType: 'text',
            timeLabel: '09:05',
            createdAtLabel: '2 min ago',
          ),
        ],
        9: const <ChatConversationMessageData>[
          ChatConversationMessageData(
            id: 7,
            direction: 'incoming',
            senderName: 'محمد احمد',
            bodyText: 'Good bye!',
            messageType: 'text',
            timeLabel: '17:47',
            createdAtLabel: 'just now',
          ),
          ChatConversationMessageData(
            id: 8,
            direction: 'outgoing',
            senderName: 'المستخدم الحالي',
            bodyText: 'Good morning!',
            messageType: 'text',
            timeLabel: '10:10',
            createdAtLabel: 'just now',
          ),
          ChatConversationMessageData(
            id: 9,
            direction: 'incoming',
            senderName: 'محمد احمد',
            bodyText: 'Do you know what time is it?',
            messageType: 'text',
            timeLabel: '11:40',
            createdAtLabel: 'just now',
          ),
          ChatConversationMessageData(
            id: 10,
            direction: 'outgoing',
            senderName: 'المستخدم الحالي',
            bodyText: 'It’s morning in Egypt 😎',
            messageType: 'text',
            timeLabel: '11:43',
            createdAtLabel: 'just now',
          ),
        ],
      };

  List<ChatSearchEntryData> _recentSearches = const <ChatSearchEntryData>[
    ChatSearchEntryData(id: 1, label: 'Mo', targetThreadId: 9),
    ChatSearchEntryData(
      id: 2,
      label: 'Abdullahman Mohamed',
      targetThreadId: 10,
    ),
    ChatSearchEntryData(id: 3, label: 'Youssef Sherif', targetThreadId: 11),
  ];

  int _nextMessageId = 40;
  int _nextSearchId = 10;
  final List<ChatGiftItemData> _gifts = const <ChatGiftItemData>[
    ChatGiftItemData(
      id: 1,
      name: 'وردة',
      category: 'عام',
      assetPath: 'assets/images/room_gift_1.png',
      priceCoins: 10,
    ),
    ChatGiftItemData(
      id: 2,
      name: 'تاج',
      category: 'فاخر',
      assetPath: 'assets/images/room_gift_5.png',
      priceCoins: 99,
      isAnimated: true,
    ),
  ];

  @override
  Future<ChatInboxPayload> loadFriendsInbox() async {
    return ChatInboxPayload(
      threads: _threads
          .where(
            (thread) =>
                thread.listingGroup == 'friends' && thread.status == 'active',
          )
          .toList(),
    );
  }

  @override
  Future<ChatMessagesPayload> loadMessagesInbox() async {
    return ChatMessagesPayload(
      systemThreads: _threads
          .where(
            (thread) =>
                thread.listingGroup == 'messages' &&
                thread.isSystem &&
                thread.status == 'active',
          )
          .toList(),
      threads: _threads
          .where(
            (thread) =>
                thread.listingGroup == 'messages' &&
                !thread.isSystem &&
                thread.status == 'active',
          )
          .toList(),
    );
  }

  @override
  Future<ChatSearchPayload> loadSearch({String query = 'Mo'}) async {
    return ChatSearchPayload(
      query: query,
      recentSearches: List<ChatSearchEntryData>.from(_recentSearches),
      results: _threads
          .where(
            (thread) =>
                thread.title.toLowerCase().contains(query.toLowerCase()),
          )
          .toList(),
    );
  }

  @override
  Future<List<ChatSearchEntryData>> deleteSearchEntry({
    required int searchId,
  }) async {
    _recentSearches = _recentSearches
        .where((entry) => entry.id != searchId)
        .toList();
    return List<ChatSearchEntryData>.from(_recentSearches);
  }

  @override
  Future<List<ChatSearchEntryData>> rememberSearch({
    required String label,
    int? threadId,
  }) async {
    _recentSearches = _recentSearches
        .where((entry) => entry.label != label)
        .toList();
    _recentSearches.insert(
      0,
      ChatSearchEntryData(
        id: _nextSearchId++,
        label: label,
        targetThreadId: threadId,
      ),
    );
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
    return List<ChatSearchEntryData>.from(_recentSearches);
  }

  @override
  Future<ChatConversationPayload> loadConversation({int? threadId}) async {
    final thread = _threads
        .where((item) => item.status == 'active')
        .firstWhere(
          (item) => item.id == (threadId ?? 9),
          orElse: () => _threads.firstWhere((item) => item.status == 'active'),
        );
    final messages = List<ChatConversationMessageData>.from(
      _messagesByThread[thread.id] ?? const <ChatConversationMessageData>[],
    );
    _replaceThread(
      thread.copyWith(
        unreadCount: 0,
        readStyle: thread.readStyle == 'none' ? 'none' : 'double',
      ),
    );
    return ChatConversationPayload(
      thread: _threads.firstWhere((item) => item.id == thread.id),
      messages: messages,
      currentUserName: 'المستخدم الحالي',
    );
  }

  @override
  Future<ChatConversationPayload> openDirectThread({
    required int userId,
  }) async {
    final existing = _threads.where(
      (thread) => thread.targetUserId == userId && thread.status == 'active',
    );
    if (existing.isNotEmpty) {
      return loadConversation(threadId: existing.first.id);
    }

    final nextId =
        _threads.fold<int>(
          0,
          (maxId, item) => item.id > maxId ? item.id : maxId,
        ) +
        1;
    final thread = ChatThreadData(
      id: nextId,
      listingGroup: 'messages',
      threadType: 'direct',
      title: userId == 1 ? 'Yara Mohamed' : 'Hallo Party User',
      previewText: '',
      avatarAsset: 'assets/images/profile_avatar.png',
      statusColorHex: '#34A853',
      readStyle: 'none',
      isPhotoPreview: false,
      messageDateLabel: '',
      unreadCount: 0,
      isSystem: false,
      status: 'active',
      targetUserId: userId,
    );
    _threads.add(thread);
    _messagesByThread[nextId] = <ChatConversationMessageData>[];

    return loadConversation(threadId: nextId);
  }

  @override
  Future<ChatConversationPayload> sendMessage({
    required int threadId,
    required String bodyText,
    String messageType = 'text',
    ChatAttachmentDraft? attachment,
  }) async {
    final thread = _threads.firstWhere((item) => item.id == threadId);
    final normalizedType = attachment != null && messageType == 'text'
        ? 'image'
        : messageType;
    final normalizedBody = bodyText.trim().isNotEmpty
        ? bodyText.trim()
        : switch (normalizedType) {
            'image' => 'صورة',
            'gift' => 'أرسل هدية 🎁',
            'voice' => 'رسالة صوتية',
            _ => bodyText,
          };
    final messages = List<ChatConversationMessageData>.from(
      _messagesByThread[threadId] ?? const <ChatConversationMessageData>[],
    );
    messages.add(
      ChatConversationMessageData(
        id: _nextMessageId++,
        direction: 'outgoing',
        senderName: 'المستخدم الحالي',
        bodyText: normalizedBody,
        messageType: normalizedType,
        attachmentPath: null,
        attachmentMimeType: attachment?.mimeType,
        attachmentName: attachment?.fileName,
        timeLabel: '12:00',
        createdAtLabel: 'just now',
      ),
    );

    if (thread.threadType == 'support') {
      messages.add(
        ChatConversationMessageData(
          id: _nextMessageId++,
          direction: 'incoming',
          senderName: 'خدمه العملاء',
          bodyText: 'تم استلام رسالتك وسنراجعها في أقرب وقت.',
          messageType: 'text',
          timeLabel: '12:01',
          createdAtLabel: 'just now',
        ),
      );
      _replaceThread(
        thread.copyWith(
          previewText: 'تم استلام رسالتك وسنراجعها في أقرب وقت.',
          readStyle: 'single',
          unreadCount: 1,
          messageDateLabel: '11/16/19',
        ),
      );
    } else {
      _replaceThread(
        thread.copyWith(
          previewText: switch (normalizedType) {
            'image' => 'صورة',
            'voice' => 'رسالة صوتية',
            _ => normalizedBody,
          },
          readStyle: 'double',
          unreadCount: 0,
          messageDateLabel: '11/16/19',
          isPhotoPreview: normalizedType == 'image',
        ),
      );
    }

    _messagesByThread[threadId] = messages;
    return loadConversation(threadId: threadId);
  }

  @override
  Future<ChatGiftPanelData> loadGiftPanel() async {
    return ChatGiftPanelData(
      coinsBalance: 1235,
      diamondsBalance: 5,
      isGuest: false,
      gifts: List<ChatGiftItemData>.from(_gifts),
    );
  }

  @override
  Future<ChatConversationPayload> sendGiftMessage({
    required int threadId,
    required int giftId,
    required int quantity,
  }) async {
    final gift = _gifts.firstWhere((item) => item.id == giftId);
    return sendMessage(
      threadId: threadId,
      bodyText: 'أرسل ${gift.name} x$quantity',
      messageType: 'gift',
      attachment: ChatAttachmentDraft(
        fileName: gift.name,
        mimeType: 'image/png',
        bytes: Uint8List(0),
      ),
    );
  }

  @override
  Future<List<ChatThreadData>> loadSelectionThreads() async {
    return _threads
        .where((thread) => !thread.isSystem && thread.status == 'active')
        .toList();
  }

  @override
  Future<int> bulkAction({
    required List<int> threadIds,
    required String action,
  }) async {
    var updated = 0;
    for (final threadId in threadIds) {
      final index = _threads.indexWhere((thread) => thread.id == threadId);
      if (index == -1) {
        continue;
      }
      final thread = _threads[index];
      if (action == 'delete') {
        _threads[index] = thread.copyWith(status: 'hidden');
      } else {
        _threads[index] = thread.copyWith(
          unreadCount: 0,
          readStyle: thread.readStyle == 'none' ? 'none' : 'double',
        );
      }
      updated++;
    }
    return updated;
  }

  void _replaceThread(ChatThreadData updated) {
    final index = _threads.indexWhere((thread) => thread.id == updated.id);
    if (index == -1) {
      return;
    }
    _threads[index] = updated;
  }
}

int _chatAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
