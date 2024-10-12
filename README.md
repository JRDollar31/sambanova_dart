# SambaNova Cloud Dart/Flutter SDK Documentation

The SambaNova Cloud SDK provides tools for interacting with SambaNova's chat model, offering classes for both **streaming** and **non-streaming** interactions. This guide covers the key classes and methods to help you integrate SambaNova Cloud with your application. A simple example project is available in the repository to demonstrate usage.

## 1. **Introduction**

The SambaNova Cloud SDK provides an easy-to-use interface for building applications that need interactive conversational capabilities. With classes such as `SambaResponseDelta`, `SambaResponse`, `SambaConfiguration`, `SNChatStream`, `SNApiClient`, `SNChatNonStream`, and `SNApiClientNonStream`, developers can efficiently manage conversations while customizing model behavior through various configuration settings.

### API Key Registration
To begin, you need to apply for your SambaNova Cloud API key at [https://cloud.sambanova.ai/apis](https://cloud.sambanova.ai/apis).

After obtaining the key, add the following import to the file that will use the SDK:

```dart
import 'package:sambanova/sambanova.dart';
```

This SDK will be published as a Dart package later. For now, you can add the following block to your `pubspec.yaml` if the library files are located in the same path:

```yaml
dependencies:
  sambanova:
    path: ../
```

The [**example project**](example) in the repository is already configured. You can compile it using Android Studio or VSCode with Flutter installed, and run it on Android, iOS, Linux, Windows, or macOS.

Here is a short demo video showing the example project running on an Android phone (using my API key):

[![Watch the Demo Video](https://img.youtube.com/vi/isG1NPw4xKs/maxresdefault.jpg)](https://youtu.be/isG1NPw4xKs)

As shown, the responses load token by token, since the example project uses the **`Stream API`**. This SDK defines both **`Non-Stream API`** and **`Stream API`** capabilities. The Non-Stream API offers a simple, high-level interface, while the Stream API has lower latency and allows for customized callbacks. The following sections explain these APIs in detail.

## 2. **SNChatNonStream**

The `SNChatNonStream` class provides non-streaming interaction with the SambaNova model, which is useful when you need the complete response in one go instead of incremental updates.

- **client**: An instance of `SNApiClientNonStream` that handles API requests.
- **configuration**: A `SambaConfiguration` instance defining model behavior.
- **sendMessageForResult()**: Sends a user message to the model and waits for the complete response.

#### Example:

```dart
final snNonStream = SNChatNonStream.from(
  apiKey: 'YOUR_API_KEY',
  modelName: 'Meta-Llama-3.1-70B-Instruct',
  systemMessage: 'You are a helpful assistant.'
);

final response = await snNonStream.sendMessageForResult('Tell me about SambaNova.');
print('Response: ${response.message.content}');
```

Alternatively, you can build the chat from lower-level components:

```dart
final client = SNApiClientNonStream(apiKey: 'YOUR_API_KEY');
final configuration = SambaConfiguration(temperature: 0.5, topP: 0, model: 'Meta-Llama-3.1-405B-Instruct');
final systemMessage = 'You are a helpful assistant.';

final snNonStream = SNChatNonStream(
    client: client,
    configuration: configuration,
    systemMessage: systemMessage,
);

final response = await snNonStream.sendMessageForResult('Tell me about SambaNova.');
print('Response: ${response.message.content}');
```

### - **SNApiClientNonStream**

The `SNApiClientNonStream` class manages non-streaming API requests to the SambaNova cloud, providing methods for sending requests and receiving data in a single response.

- **sendRequestForResult()**: Sends a request to the API and returns a `SambaResponse` object containing the complete response.

#### Example:

```dart
final apiClient = SNApiClientNonStream(apiKey: 'YOUR_API_KEY');
final response = await apiClient.sendRequestForResult(request: myRequest);

print('Response: ${response.choices?.first.message.content}');
```

## 3. **SNChatStream**

### - **SambaResponseDelta**

The `SambaResponseDelta` class represents incremental updates from the SambaNova model in streaming responses. It includes attributes such as:

- **id**: A unique identifier for the response.
- **object**: The object type, typically the response type.
- **created**: A Unix timestamp indicating when the response was created.
- **model**: The name of the model providing the response.
- **systemFingerprint**: Metadata about the system.
- **choices**: A collection of message deltas from the model.
- **usage**: Metadata related to resource usage.

#### Example:

```dart
SambaResponseDelta responseDelta = SambaResponseDelta.fromJson(jsonData);
print(responseDelta.model);
```

### - **SNChatStream**

The `SNChatStream` class enables interaction with the SambaNova model using streaming data. This is beneficial for applications that need continuous updates, such as chatbots. It includes:

- **listen()**: Registers callbacks to handle data, errors, and stream completion.
- **sendMessage()**: Sends user messages to the model to generate responses.

To create a chatbot using `SNChatStream`:

1. **Initialize the Stream**: Create an instance of `SNChatStream` with the appropriate configuration and API key.
2. **Listen for Responses**: Register callbacks to handle responses, errors, and stream completion.
3. **Send User Messages**: Use the `sendMessage()` function to interact with the model.

#### Example:

```dart
final snStream = SNChatStream.from(
  apiKey: 'YOUR_API_KEY',
  modelName: 'Meta-Llama-3.1-70B-Instruct',
  systemMessage: 'You are a helpful assistant.'
);

snStream.listen(
  onData: (response) => print('Received: ${response.choices?.message.content}'),
  onError: (error) => print('Error: $error'),
);

await snStream.sendMessage('Hello, SN!');
```

You can also use lower-level constructors similar to `SNChatNonStream`:

```dart
final client = SNApiClient(apiKey: 'YOUR_API_KEY');
final configuration = SambaConfiguration(model: 'Meta-Llama-3.1-70B-Instruct', stream: true);
final systemMessage = 'You are a helpful assistant.';

final snStream = SNChatStream(
    client: client,
    configuration: configuration,
    systemMessage: systemMessage,
);

snStream.listen(
  onData: (response) => print('Received: ${response.choices?.message.content}'),
  onError: (error) => print('Error: $error'),
);

await snStream.sendMessage('Hello, SN!');
```

### - **SNApiClient**

The `SNApiClient` class manages API requests for streaming data from SambaNova cloud. It provides methods to send requests and receive data incrementally in the form of `SambaResponseDelta` objects.

- **sendRequestForStream()**: Sends a request to the API and returns a stream of `SambaResponseDelta` objects.

#### Example:

```dart
final apiClient = SNApiClient(apiKey: 'YOUR_API_KEY');
final stream = apiClient.sendRequestForStream(request: myRequest);

await for (var delta in stream) {
  print('Delta: ${delta.choices?.first.message.content}');
}
```

---

This guide provides an overview of the main classes and their usage to help you build conversational capabilities in your applications with SambaNova Cloud SDK. For more detailed examples and advanced use cases, please refer to the example project or the official documentation.

