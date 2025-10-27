class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://your-api-gateway-id.execute-api.your-region.amazonaws.com/prod',
  );

  static const Duration timeout = Duration(seconds: 20);
}
