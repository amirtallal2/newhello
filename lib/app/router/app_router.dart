import 'package:flutter/material.dart';

import '../../core/widgets/app_placeholder_screen.dart';
import '../../features/auth/presentation/screens/auth_entry_screen.dart';
import '../../features/auth/presentation/screens/check_email_screen.dart';
import '../../features/auth/presentation/screens/create_new_password_screen.dart';
import '../../features/auth/presentation/screens/identity_setup_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/number_login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/reset_password_request_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/bootstrap/presentation/screens/project_bootstrap_screen.dart';
import '../../features/chat/presentation/screens/chat_conversation_screen.dart';
import '../../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../../features/chat/presentation/screens/chat_messages_screen.dart';
import '../../features/chat/presentation/screens/chat_search_screen.dart';
import '../../features/chat/presentation/screens/chat_selection_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/live_room_screen.dart';
import '../../features/home/presentation/screens/live_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_first_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_second_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_third_screen.dart';
import '../../features/post/presentation/screens/post_create_screen.dart';
import '../../features/post/presentation/screens/post_screen.dart';
import '../../features/profile/presentation/screens/profile_agency_link_screen.dart';
import '../../features/profile/presentation/screens/profile_connections_screen.dart';
import '../../features/profile/presentation/screens/profile_bag_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/profile_income_history_screen.dart';
import '../../features/profile/presentation/screens/profile_income_screen.dart';
import '../../features/profile/presentation/screens/profile_join_agency_screen.dart';
import '../../features/profile/presentation/screens/profile_open_agency_screen.dart';
import '../../features/profile/presentation/screens/profile_shipping_agency_screen.dart';
import '../../features/profile/presentation/screens/profile_store_animated_frames_screen.dart';
import '../../features/profile/presentation/screens/profile_store_backgrounds_screen.dart';
import '../../features/profile/presentation/screens/profile_store_chat_frames_screen.dart';
import '../../features/profile/presentation/screens/profile_store_entry_effects_screen.dart';
import '../../features/profile/presentation/screens/profile_store_frames_screen.dart';
import '../../features/profile/presentation/screens/profile_store_send_frame_screen.dart';
import '../../features/profile/presentation/screens/profile_store_screen.dart';
import '../../features/profile/presentation/screens/profile_support_center_screen.dart';
import '../../features/profile/presentation/screens/profile_wallet_screen.dart';
import '../../features/profile/presentation/screens/profile_wallet_records_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/room/presentation/screens/room_general_settings_screen.dart';
import '../../features/room/presentation/screens/room_background_selection_screen.dart';
import '../../features/room/presentation/screens/room_mic_quantity_screen.dart';
import '../../features/room/presentation/screens/room_music_playlist_screen.dart';
import '../../features/room/presentation/screens/room_report_screen.dart';
import '../../features/room/presentation/screens/room_screen.dart';
import '../../features/room/presentation/screens/room_settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboardingFirst = '/onboarding/1';
  static const String onboardingSecond = '/onboarding/2';
  static const String onboardingThird = '/onboarding/3';
  static const String authEntry = '/auth/entry';
  static const String login = '/auth/login';
  static const String numberLogin = '/auth/login/number';
  static const String signUp = '/auth/sign-up';
  static const String checkEmail = '/auth/check-email';
  static const String identitySetup = '/auth/identity-setup';
  static const String otpVerification = '/auth/otp-verification';
  static const String resetPasswordRequest = '/auth/reset-password/request';
  static const String createNewPassword = '/auth/reset-password/create-new';
  static const String home = '/home';
  static const String live = '/live';
  static const String liveRoom = '/live/room';
  static const String chatInbox = '/chat/inbox';
  static const String chatMessages = '/chat/messages';
  static const String chatConversation = '/chat/conversation';
  static const String chatSearch = '/chat/search';
  static const String chatSelection = '/chat/selection';
  static const String post = '/post';
  static const String postCreate = '/post/create';
  static const String profile = '/profile';
  static const String profileAgencyLink = '/profile/agency-link';
  static const String profileConnections = '/profile/connections';
  static const String profileBag = '/profile/bag';
  static const String profileEdit = '/profile/edit';
  static const String profileStore = '/profile/store';
  static const String profileStoreAnimatedFrames =
      '/profile/store/animated-frames';
  static const String profileStoreBackgrounds = '/profile/store/backgrounds';
  static const String profileStoreChatFrames = '/profile/store/chat-frames';
  static const String profileStoreEntryEffects = '/profile/store/entry-effects';
  static const String profileStoreFrames = '/profile/store/frames';
  static const String profileStoreSendFrame = '/profile/store/frames/send';
  static const String profileWallet = '/profile/wallet';
  static const String profileWalletRecords = '/profile/wallet/records';
  static const String profileIncome = '/profile/income';
  static const String profileIncomeHistory = '/profile/income/history';
  static const String profileJoinAgency = '/profile/join-agency';
  static const String profileOpenAgency = '/profile/open-agency';
  static const String profileSupportCenter = '/profile/support-center';
  static const String profileShippingAgency = '/profile/shipping-agency';
  static const String room = '/room';
  static const String roomSettings = '/room/settings';
  static const String roomGeneralSettings = '/room/settings/general';
  static const String roomBackgroundSelection = '/room/settings/background';
  static const String roomMicQuantity = '/room/settings/mic-quantity';
  static const String roomMusicPlaylist = '/room/settings/music';
  static const String roomReport = '/room/report';
  static const String bootstrap = '/bootstrap';
}

final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case AppRoutes.onboardingFirst:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingFirstScreen(),
          settings: settings,
        );
      case AppRoutes.onboardingSecond:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingSecondScreen(),
          settings: settings,
        );
      case AppRoutes.onboardingThird:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingThirdScreen(),
          settings: settings,
        );
      case AppRoutes.authEntry:
        return MaterialPageRoute<void>(
          builder: (_) => const AuthEntryScreen(),
          settings: settings,
        );
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case AppRoutes.numberLogin:
        return MaterialPageRoute<void>(
          builder: (_) => const NumberLoginScreen(),
          settings: settings,
        );
      case AppRoutes.signUp:
        return MaterialPageRoute<void>(
          builder: (_) => const SignUpScreen(),
          settings: settings,
        );
      case AppRoutes.checkEmail:
        return MaterialPageRoute<void>(
          builder: (_) => const CheckEmailScreen(),
          settings: settings,
        );
      case AppRoutes.identitySetup:
        return MaterialPageRoute<void>(
          builder: (_) => const IdentitySetupScreen(),
          settings: settings,
        );
      case AppRoutes.otpVerification:
        return MaterialPageRoute<void>(
          builder: (_) => const OtpVerificationScreen(),
          settings: settings,
        );
      case AppRoutes.resetPasswordRequest:
        return MaterialPageRoute<void>(
          builder: (_) => const ResetPasswordRequestScreen(),
          settings: settings,
        );
      case AppRoutes.createNewPassword:
        return MaterialPageRoute<void>(
          builder: (_) => const CreateNewPasswordScreen(),
          settings: settings,
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case AppRoutes.live:
        return MaterialPageRoute<void>(
          builder: (_) => const LiveScreen(),
          settings: settings,
        );
      case AppRoutes.liveRoom:
        return MaterialPageRoute<void>(
          builder: (_) => const LiveRoomScreen(),
          settings: settings,
        );
      case AppRoutes.chatInbox:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatInboxScreen(),
          settings: settings,
        );
      case AppRoutes.chatMessages:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatMessagesScreen(),
          settings: settings,
        );
      case AppRoutes.chatConversation:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatConversationScreen(),
          settings: settings,
        );
      case AppRoutes.chatSearch:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatSearchScreen(),
          settings: settings,
        );
      case AppRoutes.chatSelection:
        return MaterialPageRoute<void>(
          builder: (_) => const ChatSelectionScreen(),
          settings: settings,
        );
      case AppRoutes.post:
        return MaterialPageRoute<void>(
          builder: (_) => const PostScreen(),
          settings: settings,
        );
      case AppRoutes.postCreate:
        return MaterialPageRoute<void>(
          builder: (_) => const PostCreateScreen(),
          settings: settings,
        );
      case AppRoutes.profile:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      case AppRoutes.profileAgencyLink:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileAgencyLinkScreen(),
          settings: settings,
        );
      case AppRoutes.profileBag:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileBagScreen(),
          settings: settings,
        );
      case AppRoutes.profileConnections:
        final args = settings.arguments is ProfileConnectionsScreenArgs
            ? settings.arguments as ProfileConnectionsScreenArgs
            : const ProfileConnectionsScreenArgs();

        return MaterialPageRoute<void>(
          builder: (_) => ProfileConnectionsScreen(args: args),
          settings: settings,
        );
      case AppRoutes.profileEdit:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileEditScreen(),
          settings: settings,
        );
      case AppRoutes.profileStore:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileStoreScreen(),
          settings: settings,
        );
      case AppRoutes.profileStoreAnimatedFrames:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileStoreAnimatedFramesScreen(),
          settings: settings,
        );
      case AppRoutes.profileStoreBackgrounds:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileStoreBackgroundsScreen(),
          settings: settings,
        );
      case AppRoutes.profileStoreChatFrames:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileStoreChatFramesScreen(),
          settings: settings,
        );
      case AppRoutes.profileStoreEntryEffects:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileStoreEntryEffectsScreen(),
          settings: settings,
        );
      case AppRoutes.profileStoreFrames:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileStoreFramesScreen(),
          settings: settings,
        );
      case AppRoutes.profileStoreSendFrame:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileStoreSendFrameScreen(),
          settings: settings,
        );
      case AppRoutes.profileWallet:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileWalletScreen(),
          settings: settings,
        );
      case AppRoutes.profileWalletRecords:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileWalletRecordsScreen(),
          settings: settings,
        );
      case AppRoutes.profileIncome:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileIncomeScreen(),
          settings: settings,
        );
      case AppRoutes.profileIncomeHistory:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileIncomeHistoryScreen(),
          settings: settings,
        );
      case AppRoutes.profileJoinAgency:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileJoinAgencyScreen(),
          settings: settings,
        );
      case AppRoutes.profileOpenAgency:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileOpenAgencyScreen(),
          settings: settings,
        );
      case AppRoutes.profileSupportCenter:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileSupportCenterScreen(),
          settings: settings,
        );
      case AppRoutes.profileShippingAgency:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileShippingAgencyScreen(),
          settings: settings,
        );
      case AppRoutes.room:
        final args = settings.arguments is RoomScreenArgs
            ? settings.arguments as RoomScreenArgs
            : const RoomScreenArgs(roomId: 1);
        return MaterialPageRoute<void>(
          builder: (_) => RoomScreen(roomId: args.roomId),
          settings: settings,
        );
      case AppRoutes.roomSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const RoomSettingsScreen(),
          settings: settings,
        );
      case AppRoutes.roomGeneralSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const RoomGeneralSettingsScreen(),
          settings: settings,
        );
      case AppRoutes.roomBackgroundSelection:
        return MaterialPageRoute<void>(
          builder: (_) => const RoomBackgroundSelectionScreen(),
          settings: settings,
        );
      case AppRoutes.roomMicQuantity:
        return MaterialPageRoute<void>(
          builder: (_) => const RoomMicQuantityScreen(),
          settings: settings,
        );
      case AppRoutes.roomMusicPlaylist:
        return MaterialPageRoute<void>(
          builder: (_) => const RoomMusicPlaylistScreen(),
          settings: settings,
        );
      case AppRoutes.roomReport:
        return MaterialPageRoute<void>(
          builder: (_) => const RoomReportScreen(),
          settings: settings,
        );
      case AppRoutes.bootstrap:
        return MaterialPageRoute<void>(
          builder: (_) => const ProjectBootstrapScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const AppPlaceholderScreen(
            badge: 'Unknown Route',
            title: 'الصفحة المطلوبة غير موجودة',
            subtitle: 'المسار المطلوب غير مضاف داخل التطبيق حتى الآن.',
            highlights: [
              'راجِع اسم الـ route قبل التنقل إليها.',
              'أضف الشاشة الجديدة داخل AppRouter لما نبدأ تنفيذها.',
            ],
            footer:
                'أول ما تبعت الشاشة من الفيجما، هنوصلها بالراوتر ونخليها جزء من التدفق الحقيقي.',
          ),
          settings: settings,
        );
    }
  }
}
