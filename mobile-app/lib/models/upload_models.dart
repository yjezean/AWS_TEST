class PresignRequest {
  final String filename;
  final String contentType;

  const PresignRequest({required this.filename, required this.contentType});

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'contentType': contentType,
      };
}

class PresignResponse {
  final String url;
  final String? key;
  final Map<String, dynamic>? fields; // if using POST form-data style

  const PresignResponse({required this.url, this.key, this.fields});

  factory PresignResponse.fromJson(Map<String, dynamic> json) {
    return PresignResponse(
      url: json['url']?.toString() ?? '',
      key: json['key']?.toString(),
      fields: json['fields'] is Map<String, dynamic>
          ? json['fields'] as Map<String, dynamic>
          : null,
    );
  }
}
