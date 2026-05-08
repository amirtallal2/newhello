abstract final class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String productionBaseUrl = 'https://halloparty.online/api';

  static String primaryBaseUrl() {
    final fromEnv = _envBaseUrl.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }

    return productionBaseUrl;
  }

  static String origin() {
    return primaryBaseUrl().replaceFirst(RegExp(r'/api$'), '');
  }

  static List<String> candidateBaseUrls() {
    return <String>[primaryBaseUrl()];
  }
}
