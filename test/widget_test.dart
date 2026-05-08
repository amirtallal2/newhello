import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newhello/app/app.dart';
import 'package:newhello/app/router/app_router.dart';
import 'package:newhello/core/storage/app_launch_store.dart';
import 'package:newhello/features/auth/data/auth_flow_store.dart';
import 'package:newhello/features/auth/data/auth_repository.dart';
import 'package:newhello/features/chat/data/chat_repository.dart';
import 'package:newhello/features/home/data/club_repository.dart';
import 'package:newhello/features/home/data/live_repository.dart';
import 'package:newhello/features/post/data/post_repository.dart';
import 'package:newhello/features/profile/data/profile_agency_repository.dart';
import 'package:newhello/features/profile/data/profile_account_repository.dart';
import 'package:newhello/features/profile/data/profile_economy_repository.dart';
import 'package:newhello/features/profile/data/profile_levels_repository.dart';
import 'package:newhello/features/profile/data/profile_referral_repository.dart';
import 'package:newhello/features/profile/data/profile_support_repository.dart';
import 'package:newhello/features/profile/presentation/screens/profile_connections_screen.dart';
import 'package:newhello/features/room/data/room_gift_repository.dart';
import 'package:newhello/features/room/data/room_game_repository.dart';
import 'package:newhello/features/room/data/room_music_repository.dart';
import 'package:newhello/features/room/data/room_audio_repository.dart';
import 'package:newhello/features/room/data/room_repository.dart';
import 'package:newhello/features/social/data/social_repository.dart';
import 'package:newhello/features/room/presentation/controllers/room_background_controller.dart';
import 'package:newhello/features/room/presentation/controllers/room_session_controller.dart';
import 'package:newhello/features/room/presentation/screens/room_game_lobby_screen.dart';

Future<void> _pumpRouteAtSize(
  WidgetTester tester, {
  required String route,
  required Size size,
}) async {
  final binding = tester.binding;
  await binding.setSurfaceSize(size);
  addTearDown(() async {
    await binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MaterialApp(
      initialRoute: route,
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppLaunchStore.instance.initialize();
    await AppLaunchStore.instance.reset();
    await AuthFlowStore.instance.initialize();
    AuthRepository.instance = FakeAuthRepository();
    ChatRepository.instance = FakeChatRepository();
    ClubRepository.instance = FakeClubRepository();
    LiveRepository.instance = FakeLiveRepository();
    PostRepository.instance = FakePostRepository();
    ProfileAccountRepository.instance = FakeProfileAccountRepository();
    ProfileAgencyRepository.instance = FakeProfileAgencyRepository();
    ProfileEconomyRepository.instance = FakeProfileEconomyRepository();
    ProfileLevelsRepository.instance = FakeProfileLevelsRepository();
    ProfileReferralRepository.instance = FakeProfileReferralRepository();
    SocialRepository.instance = FakeSocialRepository();
    RoomGiftRepository.instance = FakeRoomGiftRepository();
    RoomGameRepository.instance = FakeRoomGameRepository();
    RoomMusicRepository.instance = FakeRoomMusicRepository();
    RoomAudioRepository.instance = FakeRoomAudioRepository();
    RoomRepository.instance = FakeRoomRepository();
    ProfileSupportRepository.instance = FakeProfileSupportRepository();
    await AuthFlowStore.instance.reset();
    RoomSessionController.instance.reset();
    RoomBackgroundController.instance.reset();
  });

  testWidgets('onboarding flow reaches auth entry screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VoiceLiveApp());

    expect(find.byType(Image), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('Discover Meaningful\nConnections'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue').first);
    await tester.pumpAndSettle();

    expect(find.text('Explore Authentic\nConnections'), findsOneWidget);

    await tester.tap(find.text('Continue').first);
    await tester.pumpAndSettle();

    expect(find.text('Discover Real\nConnections'), findsOneWidget);

    await tester.tap(find.text('Continue').first);
    await tester.pumpAndSettle();

    expect(find.text('Let’s dive into your account!'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(
      find.text('Continue with Apple'),
      Platform.isIOS ? findsOneWidget : findsNothing,
    );
    expect(find.text('Continue with Number'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back 👋'), findsOneWidget);
    expect(
      find.text('Please enter your email & password to sign in.'),
      findsOneWidget,
    );
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('auth entry routes number flow to number login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.authEntry,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('Continue with Number'), findsOneWidget);

    await tester.tap(find.text('Continue with Number'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back 👋'), findsOneWidget);
    expect(
      find.text('Please enter your number & password to sign in.'),
      findsOneWidget,
    );
    expect(find.text('Number'), findsOneWidget);
    expect(find.text('Enter Your Number'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('later launches skip onboarding when it was already seen', (
    WidgetTester tester,
  ) async {
    await AppLaunchStore.instance.markOnboardingSeen();

    await tester.pumpWidget(const VoiceLiveApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('Let’s dive into your account!'), findsOneWidget);
    expect(find.text('Discover Meaningful\nConnections'), findsNothing);
  });

  testWidgets('saved auth session opens home instead of auth flow', (
    WidgetTester tester,
  ) async {
    await AppLaunchStore.instance.markOnboardingSeen();
    await AuthFlowStore.instance.saveAuthSession(
      token: 'persisted-token',
      user: <String, dynamic>{'id': 1, 'email': 'persisted@example.com'},
    );

    await tester.pumpWidget(const VoiceLiveApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('Let’s dive into your account!'), findsNothing);
  });

  testWidgets('email login submit routes to home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('Log in'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'tester@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('هاشتاق'), findsOneWidget);
    expect(find.text('الالعاب'), findsOneWidget);
    expect(find.text('خدمة العملاء'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('اللايف'), findsOneWidget);
  });

  testWidgets('home chat tab routes to chat inbox screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('الدردشة'), findsOneWidget);

    await tester.tap(find.text('الدردشة'));
    await tester.pumpAndSettle();

    expect(find.text('المحادثات'), findsOneWidget);
    expect(find.text('تعديل'), findsOneWidget);
    expect(find.text('الاصدقاء'), findsOneWidget);
    expect(find.text('رسالة'), findsOneWidget);
    expect(find.text('اكتشف'), findsOneWidget);
  });

  testWidgets('home live tab routes to live screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('اللايف'), findsOneWidget);

    await tester.tap(find.text('اللايف'));
    await tester.pumpAndSettle();

    expect(find.text('بث مباشر'), findsOneWidget);
    expect(find.text('اهلآ بكم في اللايف الخاص بنـا'), findsOneWidget);
    expect(find.byKey(const ValueKey('live-room-card-0')), findsOneWidget);
  });

  testWidgets('home search button opens figma search screen with real tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-search-field')), findsOneWidget);
    expect(find.text('مستخدم'), findsOneWidget);
    expect(find.text('غرفة'), findsOneWidget);
    expect(find.text('عمليات البحث الأخيرة'), findsOneWidget);
    expect(find.text('Mo'), findsOneWidget);
  });

  testWidgets('home notifications button opens figma notifications screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('الاشعارات الخاصة بك'), findsOneWidget);
    expect(find.text('تعليق جديد'), findsOneWidget);
    expect(find.textContaining('محمد احمد'), findsOneWidget);
  });

  testWidgets('home create room button routes to create room screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('انشاء غرفة'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create-room-title')), findsOneWidget);
    expect(find.text('انشاء غرفتي'), findsOneWidget);
    expect(find.text('انشاء غرفة'), findsOneWidget);
  });

  testWidgets('home clubs button opens real clubs list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('النوادى'));
    await tester.pumpAndSettle();

    expect(find.text('النوادى'), findsOneWidget);
    expect(find.text('نادي ملوك هالو'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-club-create-fab')), findsOneWidget);
  });

  testWidgets('create club submit saves a real club', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.homeClubCreate,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('home-club-create-name-field')),
      'نادي الاختبار',
    );
    await tester.enterText(
      find.byKey(const ValueKey('home-club-create-code-field')),
      'TESTCLUB',
    );
    await tester.enterText(
      find.byKey(const ValueKey('home-club-create-announcement-field')),
      'إعلان نادي الاختبار',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('home-club-create-submit-button')),
    );
    await tester.pumpAndSettle();

    final clubs = await ClubRepository.instance.listClubs(scope: 'newest');
    expect(clubs.any((club) => club.name == 'نادي الاختبار'), isTrue);
  });

  testWidgets('create room submit opens created room screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomCreate,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'غرفة الاختبار');
    await tester.enterText(find.byType(TextField).at(1), 'شعار الغرفة الجديد');
    await tester.ensureVisible(
      find.byKey(const ValueKey('create-room-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('create-room-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('غرفة الاختبار'), findsOneWidget);

    final rooms = await RoomRepository.instance.listRooms();
    expect(rooms.any((room) => room.roomTitle == 'غرفة الاختبار'), isTrue);
  });

  testWidgets('live card routes to live room screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.live,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('live-room-card-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('live-room-screen')), findsOneWidget);
    expect(find.text('مداهم 777'), findsOneWidget);
    expect(find.text('ID:1512345412'), findsOneWidget);
  });

  testWidgets('live room tools action opens room tools sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.liveRoom,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('live-room-tools-action'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('live-room-tools-sheet')), findsOneWidget);
    expect(find.text('اداة الغرفة'), findsOneWidget);
    expect(find.text('كتم الصوت'), findsOneWidget);
    expect(find.text('ابلاغ'), findsOneWidget);
    expect(find.text('شارك'), findsOneWidget);
    expect(find.text('اعدادات التاثير'), findsOneWidget);
  });

  testWidgets('live room effects action opens settings panel directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.liveRoom,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('live-room-tools-action'));
    await tester.pumpAndSettle();
    expect(find.text('اعدادات التاثير'), findsOneWidget);
    await tester.tap(find.text('اعدادات التاثير'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('live-room-effects-mode')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('live-room-effect-settings-panel')),
      findsOneWidget,
    );
    expect(find.text('إعدادات التأثير واللايف'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('live-room-effects-settings')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('live-room-effects-pk')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('live-room-effects-message')),
      findsOneWidget,
    );
  });

  testWidgets('live room effects settings opens management panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.liveRoom,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('live-room-tools-action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اعدادات التاثير'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('live-room-effect-settings-panel')),
      findsOneWidget,
    );
    expect(find.text('ادارة البث'), findsOneWidget);
    expect(find.text('ادارة الغرفة'), findsOneWidget);
    expect(find.text('مركز الالعاب'), findsOneWidget);
    expect(find.text('جمال'), findsOneWidget);
    expect(find.text('Valorant'), findsNWidgets(5));
  });

  testWidgets('live room people action opens viewers panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.liveRoom,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('live-room-people-action'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('live-room-viewers-panel')),
      findsOneWidget,
    );
    expect(find.text('المشاهدين'), findsOneWidget);
    expect(find.text('افضل الداعمين'), findsOneWidget);
    expect(find.text('Mohammed Ahmed'), findsWidgets);
    expect(find.text('Sara Mohamed'), findsWidgets);
    expect(find.text('Nona Mohamed'), findsWidgets);
    expect(find.text('Yara Mohamed'), findsWidgets);
  });

  testWidgets('top supporters entry opens contribution panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.liveRoom,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('live-room-people-action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('افضل الداعمين'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('live-room-contribution-panel')),
      findsOneWidget,
    );
    expect(find.text('قائمة المساهمات لهذه الجولة'), findsOneWidget);
    expect(find.text('Mohammed Ahmed'), findsOneWidget);
    expect(find.text('100 Coin'), findsOneWidget);
    expect(find.text('الهدية الاجمالية'), findsOneWidget);
    expect(find.text('عدد المرسلين'), findsOneWidget);
  });

  testWidgets('live room pk action opens pk panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.liveRoom,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('live-room-tools-action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اعدادات التاثير'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('live-room-effect-settings-dismiss')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('live-room-effects-pk')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('live-room-pk-panel')), findsOneWidget);
    expect(find.text('1v1 PK'), findsOneWidget);
    expect(find.text('نمط المطابقة'), findsOneWidget);
    expect(find.text('بدء المطابقة'), findsOneWidget);
    expect(find.text('وضع الدعوة'), findsOneWidget);
    expect(find.text('تحدي الاصدقاء'), findsOneWidget);
    expect(find.text('إعدادات PK'), findsOneWidget);
  });

  testWidgets('pk settings action opens pk live settings panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.liveRoom,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('live-room-tools-action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اعدادات التاثير'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('live-room-effect-settings-dismiss')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('live-room-effects-pk')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعدادات PK'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('live-room-pk-settings-panel')),
      findsOneWidget,
    );
    expect(find.text('اعدادات الايف'), findsOneWidget);
    expect(find.text('من يستطيع التحدث في حياتي'), findsOneWidget);
    expect(find.text('مدة المعركة'), findsOneWidget);
    expect(find.text('30د'), findsOneWidget);
  });

  testWidgets('home profile tab routes to profile screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('الملف'), findsOneWidget);

    await tester.tap(find.text('الملف'));
    await tester.pumpAndSettle();

    expect(find.text('بسمة أحمد'), findsOneWidget);
    expect(find.text('Shark.island'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-avatar-frame')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-avatar-badge')), findsOneWidget);
    expect(find.text('مركز الدعم'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
  });

  testWidgets('profile header routes to profile edit screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-edit-entry')));
    await tester.pumpAndSettle();

    expect(find.text('التحرير'), findsOneWidget);
    expect(find.text('بسمة أحمد'), findsOneWidget);
    expect(find.text('عيد ميلاد'), findsOneWidget);
    expect(find.text('2004/09/20'), findsOneWidget);
  });

  testWidgets('profile settings item routes to profile settings screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('الإعدادات'));
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('التحرير'), findsOneWidget);
    expect(find.text('بسمة أحمد'), findsOneWidget);
    expect(find.text('غير قابل للتعديل'), findsOneWidget);
    expect(find.text('توقيع شخصي'), findsOneWidget);
  });

  testWidgets(
    'profile stats route to connections screen with correct initial tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.profile,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('المتابعون'));
      await tester.pumpAndSettle();

      expect(find.text('الاتصال'), findsOneWidget);
      expect(find.text('لا يوجد محتوي'), findsOneWidget);

      final followingIndicatorSize = tester.getSize(
        find.byKey(const ValueKey('profile-connections-active-following')),
      );
      final followersIndicatorSize = tester.getSize(
        find.byKey(const ValueKey('profile-connections-active-followers')),
      );

      expect(followingIndicatorSize.width, 0);
      expect(followersIndicatorSize.width, 59);
    },
  );

  testWidgets('connections screen supports visitor mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileConnectionsScreen(
          args: ProfileConnectionsScreenArgs(
            initialTab: ProfileConnectionsTab.friends,
            isCurrentUser: false,
          ),
        ),
      ),
    );

    expect(find.text('الاتصال'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-connections-visitor')),
      findsOneWidget,
    );

    final friendsIndicatorSize = tester.getSize(
      find.byKey(const ValueKey('profile-connections-active-friends')),
    );
    expect(friendsIndicatorSize.width, 27);
  });

  testWidgets('profile income action routes to income screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('الدخل').first);
    await tester.tap(find.text('الدخل').first);
    await tester.pumpAndSettle();

    expect(find.text('الدخل'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('عملاتي'), findsNWidgets(2));
    expect(find.text('التقرير اليومي'), findsOneWidget);
    expect(find.text('المكسب الاجمالي'), findsOneWidget);
  });

  testWidgets('profile charge action routes to wallet screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('الشحن').first);
    await tester.tap(find.text('الشحن').first);
    await tester.pumpAndSettle();

    expect(find.text('محفظتي'), findsOneWidget);
    expect(find.text('رصيد الالماس الخاص بك :'), findsOneWidget);
    expect(find.text('الماس'), findsOneWidget);
    expect(find.text('6090'), findsOneWidget);
    expect(find.text('تواصل معنا الان'), findsOneWidget);
  });

  testWidgets('wallet screen switches to coins tab state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileWallet,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profile-wallet-tab-coins')));
    await tester.pumpAndSettle();

    expect(find.text('رصيد الكوينز الخاص بك :'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
    expect(find.text('100'), findsWidgets);
    expect(
      find.byKey(const ValueKey('profile-wallet-contact')),
      findsOneWidget,
    );
  });

  testWidgets('wallet contact action routes to shipping agency screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileWallet,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-wallet-contact')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-wallet-contact')));
    await tester.pumpAndSettle();

    expect(find.text('وكالة الشحن'), findsOneWidget);
    expect(find.text('بحث'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-shipping-agency-field')),
      findsOneWidget,
    );
    expect(find.text('الدول المدعومة للتداول'), findsWidgets);
  });

  testWidgets('wallet records action routes to wallet records screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileWallet,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل'), findsOneWidget);
    expect(find.text('تحويل المبلغ'), findsOneWidget);
    expect(find.text('عدد العملات المتاحة الان : 1235'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('تم الشحن بنجاح'), findsWidgets);
    expect(find.text('تم شراء العنصر'), findsWidgets);
  });

  testWidgets('wallet history action routes to income history screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileWallet,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('المحفوظات'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('الكوينز'), findsOneWidget);
    expect(find.text('الدخل: 1235'), findsOneWidget);
    expect(find.text('شحن 200 عملة الآن'), findsWidgets);
  });

  testWidgets('income history supports diamonds state from wallet flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileWallet,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('المحفوظات'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الماس'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('الماس'), findsOneWidget);
    expect(find.text('الدخل: 5'), findsOneWidget);
    expect(find.text('تبادل الحبوب الي الماس'), findsWidgets);
    expect(find.text('هدايا الاليف'), findsOneWidget);
    expect(find.text('هدايا الغرف الصوتي'), findsOneWidget);
    expect(find.text('العاب'), findsOneWidget);
    expect(find.text('المرود'), findsOneWidget);
  });

  testWidgets('profile store action routes to store screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('المتجر').first);
    await tester.tap(find.text('المتجر').first);
    await tester.pumpAndSettle();

    expect(find.text('المتجر'), findsOneWidget);
    expect(find.text('الاطارات المتحركة'), findsOneWidget);
    expect(find.text('قبعات الدردشة'), findsOneWidget);
    expect(find.text('الملف'), findsOneWidget);
  });

  testWidgets('profile bag action routes to bag screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('الحقيبة').first);
    await tester.tap(find.text('الحقيبة').first);
    await tester.pumpAndSettle();

    expect(find.text('حقيبتي'), findsOneWidget);
    expect(find.text('الاطارات المتحركة'), findsOneWidget);
    expect(find.text('استخدام'), findsOneWidget);
    expect(find.text('الغاء'), findsOneWidget);
    expect(find.text('ارتداء'), findsOneWidget);
    expect(find.text('ازالة'), findsOneWidget);
  });

  testWidgets('store frames category routes to frames listing screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileStore,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('profile-store-category-الاطارات')),
    );
    await tester.pumpAndSettle();

    expect(find.text('الاطارات'), findsOneWidget);
    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('معاينة'), findsOneWidget);
    expect(find.text('شراء'), findsOneWidget);
    expect(find.text('ارسال'), findsOneWidget);
  });

  testWidgets(
    'store backgrounds category routes to backgrounds listing screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.profileStore,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('profile-store-category-الخلفيات')),
      );
      await tester.tap(
        find.byKey(const ValueKey('profile-store-category-الخلفيات')),
      );
      await tester.pumpAndSettle();

      expect(find.text('الخلفيات'), findsOneWidget);
      expect(find.text('جديد'), findsOneWidget);
      expect(find.text('معاينة'), findsOneWidget);
      expect(find.text('شراء'), findsOneWidget);
      expect(find.text('ارسال'), findsOneWidget);
    },
  );

  testWidgets(
    'store animated frames category routes to animated frames listing screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.profileStore,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('profile-store-category-الاطارات المتحركة')),
      );
      await tester.pumpAndSettle();

      expect(find.text('الاطارات المتحركة'), findsOneWidget);
      expect(find.text('جديد'), findsOneWidget);
      expect(find.text('معاينة'), findsOneWidget);
      expect(find.text('شراء'), findsOneWidget);
      expect(find.text('ارسال'), findsOneWidget);
    },
  );

  testWidgets('store chat hats category routes to chat frames listing screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileStore,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-store-category-قبعات الدردشة')),
    );
    await tester.tap(
      find.byKey(const ValueKey('profile-store-category-قبعات الدردشة')),
    );
    await tester.pumpAndSettle();

    expect(find.text('اطارات المحادثات'), findsOneWidget);
    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('معاينة'), findsOneWidget);
    expect(find.text('شراء'), findsOneWidget);
    expect(find.text('ارسال'), findsOneWidget);
  });

  testWidgets('store entry effects category routes to entry effects screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileStore,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-store-category-الدخلات')),
    );
    await tester.tap(
      find.byKey(const ValueKey('profile-store-category-الدخلات')),
    );
    await tester.pumpAndSettle();

    expect(find.text('الدخلات'), findsOneWidget);
    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('معاينة'), findsOneWidget);
    expect(find.text('شراء'), findsOneWidget);
    expect(find.text('ارسال'), findsOneWidget);
  });

  testWidgets('entry effects item buy button opens purchase dialog overlay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileStoreEntryEffects,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-store-entry-effects-item-buy-0')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-store-entry-effects-dialog')),
      findsOneWidget,
    );
    expect(find.text('الاطار المتحرك السريع'), findsOneWidget);
    expect(find.text('3 ايام'), findsOneWidget);
    expect(find.text('30 ايام'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-store-entry-effects-dialog-buy')),
      findsOneWidget,
    );
  });

  testWidgets('animated frames item buy button opens purchase dialog overlay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileStoreAnimatedFrames,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-store-animated-frames-item-buy-0')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-store-animated-frames-dialog')),
      findsOneWidget,
    );
    expect(find.text('رسم ادوات'), findsOneWidget);
    expect(find.text('3 ايام'), findsOneWidget);
    expect(find.text('30 ايام'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-store-animated-frames-dialog-buy')),
      findsOneWidget,
    );
  });

  testWidgets('frames item buy button opens purchase dialog overlay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileStoreFrames,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-store-frames-item-buy-0')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-store-frames-dialog')),
      findsOneWidget,
    );
    expect(find.text('الاطار القوي'), findsOneWidget);
    expect(find.text('3 ايام'), findsOneWidget);
    expect(find.text('30 ايام'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-store-frames-dialog-buy')),
      findsOneWidget,
    );
  });

  testWidgets('frames item gift button routes to send frame screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileStoreFrames,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ارسال').first);
    await tester.pumpAndSettle();

    expect(find.text('اصدقائي'), findsOneWidget);
    expect(find.text('احدث الدردشات '), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-store-send-search')),
      findsOneWidget,
    );
    expect(find.text('ارسال الان'), findsOneWidget);
  });

  testWidgets('profile support menu routes to support center screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('مركز الدعم'));
    await tester.tap(find.text('مركز الدعم'));
    await tester.pumpAndSettle();

    expect(find.text('مركز الدعم الفني'), findsOneWidget);
    expect(find.text('مشكلة تطبيق'), findsOneWidget);
    expect(find.text('اعادة الشحن'), findsOneWidget);
    expect(find.text('ارسال الان المشكلة'), findsOneWidget);
    expect(find.text('0/300'), findsOneWidget);
  });

  testWidgets('shipping agency search filters agencies from repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileShippingAgency,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-shipping-agency-card-0')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('profile-shipping-agency-field')),
      'سارة',
    );
    await tester.tap(
      find.byKey(const ValueKey('profile-shipping-agency-search')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sara Mohamed'), findsOneWidget);
    expect(find.text('Mohamed Ahmed'), findsNothing);
  });

  testWidgets('support center submits ticket through repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileSupportCenter,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('profile-support-description')),
      'يوجد تأخير في وصول الشحن داخل التطبيق.',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-support-submit')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-support-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('SUP-000003'), findsOneWidget);
    expect(find.text('0/300'), findsOneWidget);
  });

  testWidgets('profile open agency item routes to open agency screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('فتح وكالة'));
    await tester.tap(find.text('فتح وكالة'));
    await tester.pumpAndSettle();

    expect(find.text('فتح وكالة جديدة'), findsOneWidget);
    expect(find.text('اسم الوكالة والدولة الخاصة بك'), findsOneWidget);
    expect(find.text('معلومات الهوية'), findsOneWidget);
    expect(find.text('ارسال المراجعة'), findsOneWidget);
  });

  testWidgets('profile join agency item routes to join agency screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('انضم إلى وكالة'));
    await tester.tap(find.text('انضم إلى وكالة'));
    await tester.pumpAndSettle();

    expect(find.text('الانضمام الي وكالة'), findsOneWidget);
    expect(find.text('لا يوجد وكالة مقترحة الان !'), findsOneWidget);
    expect(find.text('الانضمام الي الوكالة'), findsOneWidget);
  });

  testWidgets('join agency continue button routes to agency link screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileJoinAgency,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الانضمام الي الوكالة'));
    await tester.pumpAndSettle();

    expect(find.text('ربط الوكالة'), findsOneWidget);
    expect(find.text('يرجي كتابة رمز دعوة الوكالة'), findsOneWidget);
    expect(find.text('ربط الان'), findsOneWidget);
  });

  testWidgets('agency link type field updates after choosing agency type', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileAgencyLink,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-agency-link-type-field')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('صوتي'));
    await tester.pumpAndSettle();

    expect(find.text('صوتي'), findsOneWidget);
  });

  testWidgets('open agency country field updates after choosing country', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileOpenAgency,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-open-agency-country-field')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('مصر'));
    await tester.pumpAndSettle();

    expect(find.text('مصر'), findsOneWidget);
  });

  testWidgets('profile invitation code opens real referral screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('كود الدعوة'));
    await tester.tap(find.text('كود الدعوة'));
    await tester.pumpAndSettle();

    expect(find.text('Halo Party'), findsOneWidget);
    expect(find.text('HPABC123'), findsOneWidget);
    expect(find.text('دعوة الاصدقاء'), findsOneWidget);
  });

  testWidgets('agency link submit shows join request code', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileAgencyLink,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-agency-link-type-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('لايف'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-agency-link-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('AJR-'), findsOneWidget);
  });

  testWidgets('open agency submit shows open request code', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileOpenAgency,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('profile-open-agency-name')),
      'وكالة جديدة',
    );
    await tester.tap(
      find.byKey(const ValueKey('profile-open-agency-country-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('مصر'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-open-agency-phone')),
      '201012345678',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-open-agency-address')),
      'القاهرة',
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-open-agency-submit')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-open-agency-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('AOR-'), findsOneWidget);
  });

  testWidgets('profile income history routes to income history screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileIncome,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.ensureVisible(find.text('History'));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('الكوينز'), findsOneWidget);
    expect(find.text('الدخل: 1235'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('شحن 200 عملة الآن'), findsWidgets);

    await tester.tap(find.text('الماس'));
    await tester.pumpAndSettle();

    expect(find.text('الماس'), findsOneWidget);
    expect(find.text('تبادل الحبوب الي الماس'), findsWidgets);
  });

  testWidgets(
    'profile edit screen shows inline edit actions for editable fields',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.profileEdit,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('profile-inline-edit-الاسم'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('profile-inline-edit-عيد ميلاد'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('profile-inline-edit-الدولة الخاصة بك'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('profile-inline-edit-جنس'), findsNothing);
      expect(find.text('غير قابل للتعديل'), findsOneWidget);
    },
  );

  testWidgets('profile name inline edit opens dialog and updates name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileEdit,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    final nameEdit = find.bySemanticsLabel('profile-inline-edit-الاسم');
    await tester.ensureVisible(nameEdit);
    await tester.tap(nameEdit, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-name-dialog-input')),
      findsOneWidget,
    );
    expect(find.text('تاكيد التغير'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('profile-name-dialog-input')),
      'لمياء احمد',
    );
    await tester.tap(find.byKey(const ValueKey('profile-name-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('لمياء احمد'), findsOneWidget);
  });

  testWidgets('profile birthdate inline edit opens dialog and updates value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileEdit,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    final birthdateEdit = find.bySemanticsLabel(
      'profile-inline-edit-عيد ميلاد',
    );
    await tester.ensureVisible(birthdateEdit);
    await tester.tap(birthdateEdit, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-birthdate-day-picker')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-birthdate-month-picker')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-birthdate-year-picker')),
      findsOneWidget,
    );
    expect(find.text('عيد الميلاد'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('profile-birthdate-month-picker')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('05').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('profile-birthdate-dialog-confirm')),
    );
    await tester.pumpAndSettle();

    expect(find.text('2004/05/20'), findsOneWidget);
  });

  testWidgets('profile country inline edit opens dialog and updates value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profileEdit,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    final countryEdit = find.bySemanticsLabel(
      'profile-inline-edit-الدولة الخاصة بك',
    );
    await tester.ensureVisible(countryEdit);
    await tester.tap(countryEdit, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('اختار بلد'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-country-option-السعودية')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('profile-country-option-السعودية')),
    );
    await tester.pumpAndSettle();

    expect(find.text('السعودية'), findsOneWidget);
  });

  testWidgets('home post tab routes to post screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('المنشورات'), findsOneWidget);

    await tester.tap(find.text('المنشورات'));
    await tester.pumpAndSettle();

    expect(find.text('الجميع'), findsOneWidget);
    expect(find.text('الاصدقاء'), findsOneWidget);
    expect(find.text('اسماء فتحي'), findsWidgets);
    expect(find.text('اضغط مطولا للاختيارات'), findsNothing);
  });

  testWidgets('post friends tab switches cards to unfollow state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.post,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('post-tab-friends')));
    await tester.pumpAndSettle();

    expect(find.text('الغاء المتابعة'), findsWidgets);
    expect(find.text('متابعة'), findsNothing);
  });

  testWidgets('post compose button routes to create post screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.post,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('post-compose-button'));
    await tester.pumpAndSettle();

    expect(find.text('نشر لحظات'), findsOneWidget);
    expect(find.text('نشر البوست الان'), findsOneWidget);
    expect(find.text('0/1000'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('post-create-editor')),
      'مرحبا',
    );
    await tester.pumpAndSettle();

    expect(find.text('5/1000'), findsOneWidget);
  });

  testWidgets('post create submit returns to feed with new post', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.post,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('post-compose-button'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('post-create-editor')),
      'هذا اول بوست حقيقي',
    );
    await tester.tap(find.byKey(const ValueKey('post-create-submit')));
    await tester.pumpAndSettle();

    expect(find.text('هذا اول بوست حقيقي'), findsOneWidget);
    expect(find.text('المستخدم الحالي'), findsOneWidget);
    expect(find.text('منشورك'), findsNothing);
  });

  testWidgets('post report opens admin-controlled reasons sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.post,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('اسماء فتحي').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('إبلاغ عن مشكلة').first);
    await tester.pumpAndSettle();

    expect(find.text('سبب البلاغ'), findsOneWidget);
    expect(find.text('محتوى مزعج أو سبام'), findsOneWidget);

    await tester.tap(find.text('محتوى مزعج أو سبام'));
    await tester.pumpAndSettle();

    expect(find.text('تم إرسال البلاغ بنجاح.'), findsOneWidget);
  });

  testWidgets('post long press opens actions menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.post,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('اسماء فتحي').first);
    await tester.pumpAndSettle();

    expect(find.text('اختيارات المنشور'), findsOneWidget);
    expect(find.text('لايك'), findsOneWidget);
    expect(find.text('التعليقات'), findsOneWidget);
    expect(find.text('مشاركة'), findsOneWidget);
    expect(find.text('إبلاغ عن مشكلة'), findsOneWidget);
  });

  testWidgets('post like comments and share actions update feed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.post,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('post-like-1-off')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('post-like-1-on')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('post-comment-1')));
    await tester.pumpAndSettle();

    expect(find.text('التعليقات'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('post-comment-input')),
      'تعليق اختبار جديد',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'إرسال'));
    await tester.pumpAndSettle();

    expect(find.text('تعليق اختبار جديد'), findsOneWidget);
    expect(find.text('التعليقات'), findsOneWidget);

    await tester.longPress(find.text('تعليق اختبار جديد'));
    await tester.pumpAndSettle();

    expect(find.text('اختيارات التعليق'), findsOneWidget);
    expect(find.text('تعديل التعليق'), findsOneWidget);
    expect(find.text('حذف التعليق'), findsOneWidget);

    await tester.tap(find.text('تعديل التعليق'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'تعليق بعد التعديل');
    await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('تعليق بعد التعديل'), findsOneWidget);

    await tester.longPress(find.text('تعليق بعد التعديل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف التعليق'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'حذف'));
    await tester.pumpAndSettle();

    expect(find.text('تعليق بعد التعديل'), findsNothing);

    await tester.longPress(find.text('منشور جميل جدا.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إبلاغ عن تعليق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محتوى مزعج أو سبام'));
    await tester.pumpAndSettle();

    expect(find.text('سبب البلاغ'), findsNothing);
    expect(find.text('التعليقات'), findsOneWidget);

    Navigator.of(tester.element(find.text('التعليقات'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('post-share-1')));
    await tester.pumpAndSettle();

    expect(find.textContaining('شارك منشور'), findsOneWidget);
  });

  testWidgets('post owner can edit and delete own post', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.post,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('post-compose-button'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('post-create-editor')),
      'هذا بوست قابل للتعديل',
    );
    await tester.tap(find.byKey(const ValueKey('post-create-submit')));
    await tester.pumpAndSettle();

    expect(find.text('تعديل'), findsNothing);
    expect(find.text('حذف'), findsNothing);

    await tester.longPress(find.text('هذا بوست قابل للتعديل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعديل المنشور'));
    await tester.pumpAndSettle();

    expect(find.text('تعديل المنشور'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('post-create-editor')),
      'هذا بوست بعد التعديل',
    );
    await tester.tap(find.byKey(const ValueKey('post-create-submit')));
    await tester.pumpAndSettle();

    expect(find.text('هذا بوست بعد التعديل'), findsOneWidget);

    await tester.longPress(find.text('هذا بوست بعد التعديل'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('حذف المنشور'));
    await tester.tap(find.text('حذف المنشور'));
    await tester.pumpAndSettle();

    expect(find.text('حذف المنشور'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'حذف'));
    await tester.pumpAndSettle();

    expect(find.text('هذا بوست بعد التعديل'), findsNothing);
  });

  testWidgets('home room card routes to room screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('الشكاوي والاقتراحات'), findsOneWidget);

    await tester.ensureVisible(find.text('الشكاوي والاقتراحات'));
    await tester.tap(
      find.ancestor(
        of: find.text('الشكاوي والاقتراحات'),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('محمد أحمد'), findsOneWidget);
    expect(find.text('أريد أن أسمع صوتك'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('room settings button routes to room settings screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.bySemanticsLabel('room-settings'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('room-settings'));
    await tester.pumpAndSettle();

    expect(find.text('اعدادات الغرفة العامة'), findsOneWidget);
    expect(find.text('قفل الغرفة'), findsOneWidget);
    expect(find.text('Teen Patti'), findsOneWidget);
    expect(find.text('تصغير الشاشة'), findsOneWidget);
  });

  testWidgets('room general settings action routes to detailed modal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomSettings,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('اعدادات الغرفة').first, findsOneWidget);

    await tester.tap(find.text('اعدادات الغرفة').first);
    await tester.pumpAndSettle();

    expect(find.text('غرفة محمد احمد'), findsOneWidget);
    expect(find.text('دردشة عامة'), findsOneWidget);
    expect(find.text('Photo.PNG'), findsOneWidget);
    expect(find.text('حفظ التغيرات'), findsOneWidget);
  });

  testWidgets('room background screen saves selected background asset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomGeneralSettings,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('صورة الخلفية'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('room-backdrop-action-صورة الخلفية')),
    );
    await tester.pumpAndSettle();

    expect(find.text('الخلفية'), findsOneWidget);
    expect(find.text('تم الشراء'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('room-background-option-4')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('room-background-save')));
    await tester.pumpAndSettle();

    expect(
      RoomBackgroundController.instance.selectedBackgroundAsset.value,
      'assets/images/room_background_option_2.jpg',
    );
    expect(find.text('غرفة محمد احمد'), findsOneWidget);
  });

  testWidgets('room background selection switches active tab to purchased', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomBackgroundSelection,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    Text purchasedTabLabel() => tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('room-background-tab-purchased')),
        matching: find.byType(Text),
      ),
    );

    Text backgroundTabLabel() => tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('room-background-tab-background')),
        matching: find.byType(Text),
      ),
    );

    expect(backgroundTabLabel().style?.color, const Color(0xFF285F98));
    expect(purchasedTabLabel().style?.color, Colors.white);

    await tester.tap(
      find.byKey(const ValueKey('room-background-tab-purchased')),
    );
    await tester.pumpAndSettle();

    expect(purchasedTabLabel().style?.color, const Color(0xFF285F98));
    expect(backgroundTabLabel().style?.color, Colors.white);
    expect(
      find.byKey(const ValueKey('room-background-option-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('room-background-save')), findsOneWidget);
  });

  testWidgets('room mic quantity action routes to mic quantity modal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomSettings,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('كمية الميكروفون'), findsOneWidget);

    await tester.tap(find.text('كمية الميكروفون'));
    await tester.pumpAndSettle();

    expect(find.text('كمية المايكات'), findsOneWidget);
    expect(find.text('9 ميكروفون'), findsOneWidget);
    expect(find.text('5 ميكروفون'), findsOneWidget);
    expect(find.text('12 ميكروفون'), findsOneWidget);
    expect(find.text('15 ميكروفون'), findsOneWidget);

    await tester.tap(find.text('حفظ التغيرات'));
    await tester.pumpAndSettle();

    expect(find.text('اعدادات الغرفة العامة'), findsOneWidget);
  });

  testWidgets('room music action routes to empty playlist screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomSettings,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('موسيقي'), findsOneWidget);

    await tester.tap(find.text('موسيقي'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('room-music-playlist-handle')),
      findsOneWidget,
    );
    expect(find.text('قائمة تشغيل فارغة'), findsOneWidget);
    expect(find.text('اضافة الموسيقي'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('room-music-playlist-handle')));
    await tester.pumpAndSettle();

    expect(find.text('اعدادات الغرفة العامة'), findsOneWidget);
  });

  testWidgets('room music add button opens source selection sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomMusicPlaylist,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('قائمة تشغيل فارغة'), findsOneWidget);
    expect(find.text('اضافة الموسيقي'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('room-music-add-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('room-music-source-picker-handle')),
      findsOneWidget,
    );
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('الاصدقاء'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('room-music-source-picker-handle')),
    );
    await tester.pumpAndSettle();

    expect(find.text('قائمة تشغيل فارغة'), findsOneWidget);
    expect(find.text('اضافة الموسيقي'), findsOneWidget);
  });

  testWidgets('room music source adds track to playlist list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomMusicPlaylist,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('room-music-add-button')));
    await tester.pumpAndSettle();

    final sourceButton = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('room-music-source-friends')),
    );
    sourceButton.onTap!.call();
    await tester.pumpAndSettle();

    expect(find.text('قائمة التشغيل'), findsOneWidget);
    expect(find.text('Friends Beat 01'), findsOneWidget);
    expect(find.text('DJ Nona • الاصدقاء'), findsOneWidget);
    expect(find.text('قائمة تشغيل فارغة'), findsNothing);
  });

  testWidgets('room music playlist entry can be removed', (
    WidgetTester tester,
  ) async {
    final repository = RoomMusicRepository.instance as FakeRoomMusicRepository;
    await repository.addFirstTrackFromSource(
      roomId: 1,
      sourceType: RoomMusicSourceType.whatsapp,
    );

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.roomMusicPlaylist,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WhatsApp Voice Mix'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('room-music-remove-1')));
    await tester.pumpAndSettle();

    expect(find.text('قائمة تشغيل فارغة'), findsOneWidget);
    expect(find.text('WhatsApp Voice Mix'), findsNothing);
  });

  testWidgets('selected mic count updates visible room seats', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.bySemanticsLabel('room-seat-8'), findsOneWidget);

    RoomSessionController.instance.updateMicCount(5);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('room-seat-1'), findsOneWidget);
    expect(find.bySemanticsLabel('room-seat-4'), findsOneWidget);
    expect(find.bySemanticsLabel('room-seat-5'), findsNothing);
    expect(find.bySemanticsLabel('room-seat-8'), findsNothing);
  });

  testWidgets('tapping room seat opens seat actions sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-seat-1'));
    await tester.pumpAndSettle();

    expect(find.text('حظر المايك'), findsOneWidget);
    expect(find.text('طرد المايك'), findsOneWidget);
    expect(find.text('كتم الصوت'), findsOneWidget);
    expect(find.text('دعوه لهذه الميك'), findsOneWidget);
    expect(find.text('دعوه شخص ما إلى الميك'), findsOneWidget);
    expect(find.text('بدل هذه المقعد'), findsOneWidget);
    expect(find.text('الغاء'), findsOneWidget);

    await tester.tap(find.text('الغاء'));
    await tester.pumpAndSettle();

    expect(find.text('حظر المايك'), findsNothing);
  });

  testWidgets('member tapping room seat sees member seat actions', (
    WidgetTester tester,
  ) async {
    RoomSessionController.instance.updateUserRole(RoomUserRole.member);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-seat-1'));
    await tester.pumpAndSettle();

    expect(find.text('تقرير'), findsOneWidget);
    expect(find.text('موسيقي'), findsOneWidget);
    expect(find.text('مشاركة الغرفة'), findsOneWidget);
    expect(find.text('الالغاء'), findsOneWidget);
    expect(find.text('طلب المايك'), findsOneWidget);
    expect(find.text('حظر المايك'), findsNothing);

    await tester.tap(find.bySemanticsLabel('seat-action-cancel-member'));
    await tester.pumpAndSettle();

    expect(find.text('طلب المايك'), findsNothing);
  });

  testWidgets('member request mic opens confirmation sheet and stores seat', (
    WidgetTester tester,
  ) async {
    RoomSessionController.instance.updateUserRole(RoomUserRole.member);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-seat-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('seat-action-request-mic'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('room-request-mic-sheet'), findsOneWidget);
    expect(find.text('تقدم بطلب للحصول علي المايك'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('room-request-mic-confirm'));
    await tester.pumpAndSettle();

    expect(RoomSessionController.instance.pendingMicRequestSeatNumber.value, 1);
    expect(find.bySemanticsLabel('room-request-mic-sheet'), findsNothing);
  });

  testWidgets('member report action routes to room report screen', (
    WidgetTester tester,
  ) async {
    RoomSessionController.instance.updateUserRole(RoomUserRole.member);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-seat-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('seat-action-report-member'));
    await tester.pumpAndSettle();

    expect(find.text('ابلاغ'), findsOneWidget);
    expect(find.text('لماذا تريد الابلغ عن هذه الغرفة؟'), findsOneWidget);
    expect(find.text('خطاب الكراهية'), findsOneWidget);
  });

  testWidgets('room info badge opens received gifts sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-info-badge'));
    await tester.pumpAndSettle();

    expect(find.text('الهدايا المستلمة من الروم'), findsOneWidget);
    expect(find.text('Mohammed Ahmed'), findsWidgets);
    expect(find.text('الغاء'), findsOneWidget);
  });

  testWidgets('admin tapping requested seat opens join requests sheet', (
    WidgetTester tester,
  ) async {
    RoomSessionController.instance.requestMic(1);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-seat-1'));
    await tester.pumpAndSettle();

    expect(find.text('طلب الانضمام الي المقعد'), findsOneWidget);
    expect(find.text('Mohammed Ahmed'), findsWidgets);
    expect(find.text('الغاء'), findsOneWidget);
  });

  testWidgets('tapping room games button opens games sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-games'));
    await tester.pumpAndSettle();

    expect(find.text('العاب الحظ'), findsOneWidget);
    expect(find.text('العاب اللوح'), findsOneWidget);
    expect(find.text('عجلة الحظ'), findsOneWidget);
    expect(find.text('لودو'), findsOneWidget);
    expect(find.text('دومينو'), findsOneWidget);
  });

  testWidgets('tapping room game opens game lobby screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-games'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('room-game-wheel_of_fortune'));
    await tester.pumpAndSettle();

    expect(find.text('جلسة اللعبة'), findsOneWidget);
    expect(find.text('عجلة الحظ'), findsOneWidget);
    expect(find.bySemanticsLabel('room-game-join'), findsOneWidget);
  });

  testWidgets('joining then leaving room game updates lobby state', (
    WidgetTester tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const SizedBox.shrink(),
      ),
    );
    navigatorKey.currentState!.pushNamed(
      AppRoutes.roomGameLobby,
      arguments: const RoomGameLobbyScreenArgs(roomId: 1, gameId: 1),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('room-game-join'), findsOneWidget);
    await tester.ensureVisible(find.bySemanticsLabel('room-game-join'));
    await tester.tap(find.bySemanticsLabel('room-game-join'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('المستخدم الحالي'), findsOneWidget);
    expect(find.bySemanticsLabel('room-game-leave'), findsOneWidget);

    await tester.ensureVisible(find.bySemanticsLabel('room-game-leave'));
    await tester.tap(find.bySemanticsLabel('room-game-leave'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('room-game-join'), findsOneWidget);
    expect(find.text('لا توجد جلسة نشطة حاليًا'), findsOneWidget);
  });

  testWidgets('tapping room gift button opens gift panel sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-gift'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('room-gift-panel'), findsOneWidget);
    expect(find.text('الهداية عادية'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('المحظوظ'), findsOneWidget);
    expect(find.text('1235 \$'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('room-gift-quantity-trigger')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('room-gift-quantity-picker')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('room-gift-item-0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('room-gift-quantity-trigger')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('room-gift-quantity-picker')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('room-gift-quantity-trigger')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('room-gift-quantity-picker')),
      findsOneWidget,
    );

    await tester.tap(find.text('x'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('room-gift-panel'), findsNothing);
  });

  testWidgets('sending selected room gift updates wallet balance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.room,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.bySemanticsLabel('room-gift'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('room-gift-item-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('room-gift-send')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('room-gift-send')));
    await tester.pumpAndSettle();

    expect(find.text('تم ارسال الهدية'), findsOneWidget);
    expect(find.text('1225 \$'), findsOneWidget);
  });

  testWidgets('chat inbox message tab routes to chat messages screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.chatInbox,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('رسالة'), findsOneWidget);

    await tester.tap(find.text('رسالة'));
    await tester.pumpAndSettle();

    expect(find.text('خدمه العملاء'), findsOneWidget);
    expect(find.text('الاشعارات'), findsOneWidget);
    expect(find.text('ممكن تعيطي هديه'), findsOneWidget);
  });

  testWidgets('chat messages thread routes to conversation screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.chatMessages,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('محمد احمد'), findsWidgets);

    await tester.tap(find.text('محمد احمد').first);
    await tester.pumpAndSettle();

    expect(find.text('محمد احمد'), findsWidgets);
    expect(find.text('Good morning!'), findsOneWidget);
    expect(
      find.text('الرجاء الالتزام بالقوانين والحفاظ علي الالفاظ'),
      findsOneWidget,
    );
  });

  testWidgets('chat search button routes to chat search screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.chatInbox,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('chat-search-button'));
    await tester.pumpAndSettle();

    expect(find.text('عمليات البحث الأخيرة'), findsOneWidget);
    expect(find.text('Abdullahman Mohamed'), findsOneWidget);
    expect(find.text('Youssef Sherif'), findsOneWidget);
  });

  testWidgets('chat messages edit routes to selection screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.chatMessages,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعديل'), findsOneWidget);

    await tester.tap(find.text('تعديل'));
    await tester.pumpAndSettle();

    expect(find.text('موافقة'), findsOneWidget);
    expect(find.text('قرائة الكل'), findsOneWidget);
    expect(find.text('مسح'), findsOneWidget);
  });

  testWidgets('sign up screen routes back to email login from sign in link', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.authEntry,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create an account 👩‍💻'), findsOneWidget);
    expect(
      find.text(
        'Create your account in seconds. We’ll help you\nfind your perfect match.',
      ),
      findsOneWidget,
    );
    expect(find.text('Privacy Policy.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back 👋'), findsOneWidget);
    expect(
      find.text('Please enter your email & password to sign in.'),
      findsOneWidget,
    );
  });

  testWidgets('sign up submit routes to check email screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.signUp,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('Create an account 👩‍💻'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'new@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.tap(find.text('I agree to Soul '));
    await tester.pump();
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Check Your Email'), findsOneWidget);
    expect(find.text('Resend email'), findsOneWidget);
    expect(find.text('I’ve verified my email'), findsOneWidget);
  });

  testWidgets('verified email continues to identity setup screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.checkEmail,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('I’ve verified my email'), findsOneWidget);

    await tester.ensureVisible(find.text('I’ve verified my email'));
    await tester.tap(find.text('I’ve verified my email'));
    await tester.pumpAndSettle();

    expect(find.text('Your datify identity'), findsOneWidget);
    expect(find.text('Nickname'), findsOneWidget);
    expect(find.text('Your Number'), findsOneWidget);
    expect(find.text('Birthdate'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('identity setup continues to otp verification screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.identitySetup,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('Your datify identity'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('OTP code verification 🔐'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Didn’t receive phone?'), findsOneWidget);
    expect(find.text('5'), findsAtLeastNWidgets(2));
    expect(find.text('2'), findsAtLeastNWidgets(2));
    expect(find.text('6'), findsAtLeastNWidgets(2));
  });

  testWidgets('otp verification continue routes to home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.otpVerification,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('OTP code verification 🔐'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.byKey(const ValueKey('numeric-key-7')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('numeric-key-8')));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('الالعاب'), findsOneWidget);
    expect(find.text('الملف'), findsOneWidget);
  });

  testWidgets('forgot password routes to reset password request screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );

    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password 🔑'), findsOneWidget);
    expect(
      find.text(
        'Please enter your email and we will send an\nOTP code in the next step to reset your\npassword.',
      ),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('mohamedahmed958@gmail.com'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets(
    'reset password request continues to create new password screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.resetPasswordRequest,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );

      expect(find.text('Reset your password 🔑'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Create new password 🔒'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Save New Password'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    },
  );

  testWidgets('profile logout routes back to auth entry screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الخروج'), findsOneWidget);

    await tester.ensureVisible(find.text('تسجيل الخروج'));
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-logout-dialog')), findsOneWidget);
    expect(find.text('هل انت متاكد انك تريد تسجيل الخروج'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-logout-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Let’s dive into your account!'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('compact phone renders login screen without overflow', (
    WidgetTester tester,
  ) async {
    await _pumpRouteAtSize(
      tester,
      route: AppRoutes.login,
      size: const Size(320, 568),
    );

    expect(find.text('Welcome back 👋'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact phone renders chat inbox without overflow', (
    WidgetTester tester,
  ) async {
    await _pumpRouteAtSize(
      tester,
      route: AppRoutes.chatInbox,
      size: const Size(320, 568),
    );

    expect(find.text('المحادثات'), findsOneWidget);
    expect(find.text('الاصدقاء'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact phone renders post screen without overflow', (
    WidgetTester tester,
  ) async {
    await _pumpRouteAtSize(
      tester,
      route: AppRoutes.post,
      size: const Size(320, 568),
    );

    expect(find.text('الجميع'), findsOneWidget);
    expect(find.bySemanticsLabel('post-compose-button'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact phone renders wallet and shipping screens without overflow',
    (WidgetTester tester) async {
      await _pumpRouteAtSize(
        tester,
        route: AppRoutes.profileWallet,
        size: const Size(320, 568),
      );

      expect(find.text('محفظتي'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const ValueKey('profile-wallet-contact')),
      );
      await tester.tap(find.byKey(const ValueKey('profile-wallet-contact')));
      await tester.pumpAndSettle();

      expect(find.text('وكالة الشحن'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tablet width renders live screen without overflow', (
    WidgetTester tester,
  ) async {
    await _pumpRouteAtSize(
      tester,
      route: AppRoutes.live,
      size: const Size(800, 1280),
    );

    expect(find.text('بث مباشر'), findsOneWidget);
    expect(find.byKey(const ValueKey('live-room-card-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
