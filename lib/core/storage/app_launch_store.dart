import 'package:shared_preferences/shared_preferences.dart';

final class AppLaunchStore {
  AppLaunchStore._();

  static final AppLaunchStore instance = AppLaunchStore._();

  static const String _hasSeenOnboardingKey = 'app.has_seen_onboarding';

  SharedPreferences? _preferences;
  bool _hasSeenOnboarding = false;

  bool get hasSeenOnboarding => _hasSeenOnboarding;

  Future<void> initialize() async {
    final preferences = await _prefs();
    _hasSeenOnboarding = preferences.getBool(_hasSeenOnboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    _hasSeenOnboarding = true;
    final preferences = await _prefs();
    await preferences.setBool(_hasSeenOnboardingKey, true);
  }

  Future<void> reset() async {
    _hasSeenOnboarding = false;
    final preferences = await _prefs();
    await preferences.remove(_hasSeenOnboardingKey);
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }
}
