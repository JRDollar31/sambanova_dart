import 'package:collection/collection.dart';

class SambaRequest {
  SambaMessages messages;
  SambaConfiguration configuration;

  SambaRequest({
    required this.messages,
    required this.configuration,
  });

  factory SambaRequest.fromJson(Map<String, dynamic> json) => SambaRequest(
    messages: SambaMessages.fromJson(json),
    configuration: SambaConfiguration.fromJson(json),
  );

  Map<String, dynamic> toJson() => {
    ...messages.toJson(),
    ...configuration.toJson(),
  };
}

class SambaResponse {
  String id;
  String object;
  int created;
  String model;
  SambaChoices choices;
  SambaUsage usage;

  SambaResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  SambaMessage get message {
    return choices.first.message;
  }

  factory SambaResponse.fromJson(Map<String, dynamic> json) => SambaResponse(
    choices: SambaChoices.fromJson(json),
    created: json['created'] as int,
    id: json['id'] as String,
    model: json['model'] as String,
    object: json['object'] as String,
    usage: SambaUsage.fromJson(json['usage'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    ...choices.toJson(),
    'created': created,
    'id': id,
    'model': model,
    'object': object,
    'usage': usage.toJson(),
  };
}

class SambaResponseDelta {
  String? id;
  String? object;
  int? created;
  String? model;
  String? systemFingerprint;
  SambaDeltaChoices? choices;
  SambaUsage? usage;

  SambaResponseDelta({
    this.id,
    this.object,
    this.created,
    this.model,
    this.systemFingerprint,
    this.choices,
    this.usage,
  });

  factory SambaResponseDelta.fromJson(Map<String, dynamic> json) => SambaResponseDelta(
    id: json['id'] as String?,
    object: json['object'] as String?,
    created: json['created'] as int?,
    model: json['model'] as String?,
    systemFingerprint: json['system_fingerprint'] as String?,
    choices: SambaDeltaChoices.fromJson(json),
    usage: SambaUsage.fromJson(json),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'object': object,
    'created': created,
    'model': model,
    'system_fingerprint': systemFingerprint,
    ...?choices?.toJson(),
    'usage': usage?.toJson(),
  };
}

class SambaMessage {
  String? role = 'assistant';
  String content;
  
  SambaMessage({
    required this.role,
    required this.content,
  });

  void append(SambaResponseDelta delta) {
    content += delta.choices?.first.message.content ?? '';
  }

  factory SambaMessage.fromJson(Map<String, dynamic> json) => SambaMessage(
    role: json['role'] as String? ?? 'assistant',
    content: json['content'] as String,
  );

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}

class SambaMessages extends DelegatingList<SambaMessage> {
  final List<SambaMessage> messages;

  SambaMessages({
    required this.messages
  }) : super(messages);

  factory SambaMessages.fromJson(Map<String, dynamic> json) => SambaMessages(
    messages: List<SambaMessage>.from((
      json['messages'] as List<Object>).map((it) => 
        SambaMessage.fromJson(it as Map<String, dynamic>),
      ),
    )
  );

  Map<String, dynamic> toJson() => {
    'messages': messages.map((it) => it.toJson()).toList(),
  };
}

// class PersistentMessage
//   List<int> childrenId;
//   int parentId;
//   int selectedChildId;

class SambaChoice {
  int index;
  SambaMessage message;

  SambaChoice({
    required this.index,
    required this.message,
  });

  factory SambaChoice.fromJson(Map<String, dynamic> json) => SambaChoice(
    index: json['index'] as int,
    message: SambaMessage.fromJson(json['message'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'index': index,
    'message': message,
  };
}

class SambaChoices extends DelegatingList<SambaChoice> {
  final List<SambaChoice> choices;

  SambaChoices({
    required this.choices
  }) : super(choices);

  factory SambaChoices.fromJson(Map<String, dynamic> json) => SambaChoices(
    choices: List<SambaChoice>.from((
      json['choices'] as List<dynamic>).map((it) => 
        SambaChoice.fromJson(it as Map<String, dynamic>)
      ),
    )
  );

  Map<String, dynamic> toJson() => {
    'choices': choices.map((it) => it.toJson()).toList(),
  };
}

class SambaDeltaChoice {
  int index;
  SambaMessage message;

  SambaDeltaChoice({
    required this.index,
    required this.message,
  });

  factory SambaDeltaChoice.fromJson(Map<String, dynamic> json) => SambaDeltaChoice(
    index: json['index'] as int,
    message: SambaMessage.fromJson(json['delta'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'index': index,
    'message': message,
  };
}

class SambaDeltaChoices extends DelegatingList<SambaDeltaChoice> {
  final List<SambaDeltaChoice> choices;

  SambaDeltaChoices({
    required this.choices
  }) : super(choices);

  factory SambaDeltaChoices.fromJson(Map<String, dynamic> json) => SambaDeltaChoices(
    choices: List<SambaDeltaChoice>.from((
      json['choices'] as List<dynamic>).map((it) => 
        SambaDeltaChoice.fromJson(it as Map<String, dynamic>)
      ),
    )
  );

  Map<String, dynamic> toJson() => {
    'choices': choices.map((it) => it.toJson()).toList(),
  };
}

class SambaUsage {
  double startTime;
  double endTime;
  int totalTokens;
  int promptTokens;
  int completionTokens;
  double totalTokensPerSec;

  SambaUsage({
    required this.startTime,
    required this.endTime,
    required this.totalTokens,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokensPerSec,
  });

  factory SambaUsage.fromJson(Map<String, dynamic> json) => SambaUsage(
    startTime: (json['start_time'] as double?) ?? 0.0,
    endTime: (json['end_time'] as double?) ?? 0.0,
    totalTokens: (json['total_tokens'] as int?) ?? 0,
    promptTokens: (json['prompt_tokens'] as int?) ?? 0,
    completionTokens: (json['completion_tokens'] as int?) ?? 0,
    totalTokensPerSec: (json['total_tokens_per_sec'] as double?) ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'start_time': startTime,
    'end_time': endTime,
    'total_tokens': totalTokens,
    'prompt_tokens': promptTokens,
    'completion_tokens': completionTokens,
    'total_tokens_per_sec': totalTokensPerSec
  };
}

final class SambaConfiguration {
  final bool stream;
  final String model;
  final double temperature;
  final int maxTokens;
  final double topP;
  final String? stop;

  SambaConfiguration({
    this.model = 'Meta-Llama-3.1-70B-Instruct',
    this.temperature = 0.0,
    this.maxTokens = 1 << 14,
    this.topP = 0,
    this.stream = false,
    this.stop,
  });

  factory SambaConfiguration.fromJson(Map<String, dynamic> json) => SambaConfiguration(
    model: json['model'] as String,
    temperature: json['temperature'] as double,
    maxTokens: json['max_tokens'] as int,
    topP: json['top_p'] as double,
    stop: json['stop'] as String
  );

  Map<String, dynamic> toJson() => {
    'model': model,
    'temperature': temperature,
    'max_tokens': maxTokens,
    'top_p': topP,
    'stream': stream,
    'stop': stop,
  };
}
