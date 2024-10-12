import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model.dart';

class SNChatNonStream {
  SNApiClientNonStream client;
  SambaConfiguration configuration;
  final SambaMessages _messages = SambaMessages(messages:[]);

  SNChatNonStream({
    required this.client,
    required this.configuration,
    required String systemMessage,
  }) {
    setSystemMessage(systemMessage);
  }

  SNChatNonStream.from({
    required String apiKey,
    required String modelName,
    required String systemMessage,
  }): 
    client = SNApiClientNonStream(apiKey: apiKey),
    configuration = SambaConfiguration(model: modelName) {
    setSystemMessage(systemMessage); 
  }

  void setSystemMessage(String content) {
    final systemMessage = SambaMessage(role: 'system', content: content);
    _messages.isEmpty ? _messages.add(systemMessage) : _messages.first = systemMessage;
  }

  void clear() => _messages.removeRange(1, _messages.length);
  
  Future<SambaResponse> sendMessageForResult(String userMessage) async {
    _messages.add(SambaMessage(role: 'user', content: userMessage));
    final request = SambaRequest(
      messages: _messages,
      configuration: configuration,
    );
    final response = await client.sendRequestForResult(request: request);
    _messages.add(response.message);
    return response;
  }
}

final class SNApiClientNonStream {
  final Uri _uri = Uri.parse('https://api.sambanova.ai/v1/chat/completions');
  final Map<String, String> _headers;

  SNApiClientNonStream({required String apiKey})
      : _headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };

  Future<SambaResponse> sendRequestForResult({required SambaRequest request}) async {
    try {
      final response = await http.post(
        _uri,
        headers: _headers,
        body: jsonEncode(request),
      );
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody.containsKey('error')) {
          final error = responseBody['error'] as Map<String, dynamic>;
          throw Exception('Error: ${error['message']}');
        }
        return SambaResponse.fromJson(responseBody);
      }
      if (responseBody['error'] != null) {
        throw Exception('${response.statusCode}: ${responseBody['error']}');
      }
      throw Exception('${response.statusCode}: $responseBody');
    } catch (e) {
      throw Exception(e);
    }
  }
}
