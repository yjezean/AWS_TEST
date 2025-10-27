import 'dart:async';
import 'package:dio/dio.dart';
import '../models/processing_models.dart';
import 'api_client.dart';

class ProcessingService {
  final ApiClient _api = ApiClient();

  Future<SubmitJobResponse> submitProcessing(
      {required String imageKeyOrUrl}) async {
    final resp = await _api.post<Map<String, dynamic>>('/process', data: {
      'image': imageKeyOrUrl,
    });
    return SubmitJobResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<JobStatusResponse> getJobStatus(String jobId) async {
    final resp = await _api.get<Map<String, dynamic>>('/process/$jobId');
    return JobStatusResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Stream<JobStatusResponse> pollJobStatus(String jobId,
      {Duration interval = const Duration(seconds: 2)}) async* {
    while (true) {
      final status = await getJobStatus(jobId);
      yield status;
      if (status.status == 'COMPLETED' || status.status == 'FAILED') {
        break;
      }
      await Future.delayed(interval);
    }
  }
}
