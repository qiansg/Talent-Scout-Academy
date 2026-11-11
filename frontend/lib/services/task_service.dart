import 'dart:convert';
import '../services/api_client.dart';

/// 学科与任务 API
class TaskService {
  final _dio = ApiClient().dio;

  Future<List<dynamic>> getSubjects() async {
    final response = await _dio.get('/subjects');
    return response.data['subjects'] ?? [];
  }

  Future<List<dynamic>> getSubjectTasks(String subject) async {
    final response = await _dio.get('/subjects/$subject/tasks');
    final tasks = response.data['tasks'] ?? [];
    // 解析 scene_data JSON 字符串
    for (var t in tasks) {
      if (t['scene_data'] is String) {
        try {
          t['scene_data'] = jsonDecode(t['scene_data']);
        } catch (_) {}
      }
    }
    return tasks;
  }

  Future<Map<String, dynamic>> getTaskDetail(String taskId) async {
    final response = await _dio.get('/tasks/$taskId');
    final task = Map<String, dynamic>.from(response.data['task']);
    if (task['scene_data'] is String) {
      try {
        task['scene_data'] = jsonDecode(task['scene_data']);
      } catch (_) {}
    }
    return task;
  }

  Future<Map<String, dynamic>> startTask(String taskId) async {
    final response = await _dio.post('/tasks/$taskId/start');
    return response.data;
  }

  Future<Map<String, dynamic>> submitTask({
    required String taskId,
    required int answer,
    int durationSeconds = 0,
    String emotion = 'neutral',
  }) async {
    final response = await _dio.post(
      '/tasks/$taskId/submit',
      data: {
        'answer': answer,
        'duration_seconds': durationSeconds,
        'emotion': emotion,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/stats/overview');
    return response.data;
  }

  Future<List<dynamic>> getBadges() async {
    final response = await _dio.get('/badges');
    return response.data['badges'] ?? [];
  }
}
