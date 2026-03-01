import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_rakkha/core/api_client.dart';
import 'package:gram_rakkha/core/entities.dart';

final alertRepoProvider = Provider((ref) => AlertRepository(ref.read(apiClientProvider)));

class AlertRepository {
  final ApiClient _client;
  AlertRepository(this._client);

  Future<AlertEntity> triggerAlert({
    required String type,
    required double lat,
    required double lng,
  }) async {
    final response = await _client.post('/emergency/', data: {
      'type': type,
      'lat': lat,
      'lng': lng,
    });
    return AlertEntity.fromJson(response.data);
  }

  Future<List<AlertEntity>> getRecentAlerts() async {
    final response = await _client.get('/emergency/recent');
    return (response.data as List).map((e) => AlertEntity.fromJson(e)).toList();
  }
}
