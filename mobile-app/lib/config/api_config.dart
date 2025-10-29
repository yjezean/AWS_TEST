class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://0v20ej3gcf.execute-api.us-east-1.amazonaws.com/prod',
  );

  static const Duration timeout = Duration(seconds: 20);
}
