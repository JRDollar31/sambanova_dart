import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model.dart';

class SNChatStream {
  SNApiClient client;
  SambaConfiguration configuration;
  final SambaMessages _messages = SambaMessages(messages:[]);

  // Callback functions
  void Function()? _onDone;
  void Function(Object error)? _onError;
  void Function(SambaResponseDelta response)? _onData;

  SNChatStream({
    required this.client,
    required this.configuration,
    required String systemMessage,
  }) {
    setSystemMessage(systemMessage);
  }

  SNChatStream.from({
    required String apiKey,
    required String modelName,
    required String systemMessage,
  }): 
    client = SNApiClient(apiKey: apiKey),
    configuration = SambaConfiguration(model: modelName, stream: true) {
    setSystemMessage(systemMessage); 
  }

  void setSystemMessage(String content) {
    final systemMessage = SambaMessage(role: 'system', content: content);
    _messages.isEmpty ? _messages.add(systemMessage) : _messages.first = systemMessage;
  }

  void clear() => _messages.removeRange(1, _messages.length);
  
  void listen({
    void Function()? onDone,
    void Function(Object error)? onError,
    void Function(SambaResponseDelta response)? onData,
  }) {
    _onDone = onDone;
    _onError = onError;
    _onData = onData;
  }

  Future<void> sendMessage(String content) async {
    _messages.add(SambaMessage(role: 'user', content: content));
    final request = SambaRequest(
      messages: _messages,
      configuration: configuration,
    );

    try {
      final message = SambaMessage(role: 'assistant', content: '');
      final responseStream = client.sendRequestForStream(request: request);

      await for (final responseDelta in responseStream) {
        message.append(responseDelta);
        _onData?.call(responseDelta);
      }
      _messages.add(message);
      _onDone?.call();
    } catch (e) {
      _onError?.call(e);
    }
  }

}

final class SNApiClient {
  final _client = http.Client();
  final Uri _uri = Uri.parse('https://api.sambanova.ai/v1/chat/completions');
  final Map<String, String> _headers;

  SNApiClient({required String apiKey})
      : _headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };

  Stream<SambaResponseDelta> sendRequestForStream({required SambaRequest request}) async* {
    try {
      final response = await _client.send(
        http.Request('POST', _uri)
        ..headers.addAll(_headers)
        ..body = jsonEncode(request)
      );
      final stream = response.stream.transform(utf8.decoder).transform(LineSplitter());

      var respondData = '';
      await for (final value in stream.where((event) => event.isNotEmpty)) {
        final data = value;
        respondData += data;
        final dataLines = data.split('\n').where((element) => element.isNotEmpty).toList();
        for (final line in dataLines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') break;
            final decoded = jsonDecode(data) as Map<String, dynamic>;
            yield SambaResponseDelta.fromJson(decoded);
            continue;
          }

          var responseBody = <String, dynamic>{};
          try {
            responseBody = jsonDecode(respondData) as Map<String, dynamic>;
          } catch (error) { 
            if (respondData.trim().isNotEmpty) {
              print('$respondData');
              throw Exception('${respondData}');
            } 
          }

          if (responseBody['error'] != null) {
            throw Exception('${response.statusCode}: ${responseBody['error']}');
          }
        }
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
}
