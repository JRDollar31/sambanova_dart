import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:sambanova/sambanova.dart';

void main() => runApp(const SNStreamApp());

class SNStreamApp extends StatelessWidget {
  const SNStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Theme.of(context).cardColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  String _buffer = '';

  final _snStream = SNChatStream.from(
    apiKey: const String.fromEnvironment('sambanovaAPIKey'), // Please put the API key here. Get it from https://cloud.sambanova.ai/apis.
    modelName: 'Meta-Llama-3.1-70B-Instruct',
    systemMessage: '',
  );

  @override
  void initState() {
    super.initState();
    _snStream.listen(
      onData: _handleResponseDelta,
      onDone: () {},
      onError: _handleResponseError,
    );
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _buffer = '';
    _textController.clear();
    _messages.add(ChatMessage(text: text, isUserMessage: true));
    setState(() {});
    _scrollToBottom();
    await _sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('SN'),
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        actions: [_buildClearButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length + 1,
                itemBuilder: (_, index) => index == _messages.length
                    ? _buildFooter()
                    : ChatMessageWidget(key: ValueKey(_messages[index].id), message: _messages[index]),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: Theme.of(context).cardColor,
              child: _buildTextComposer(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() => IconButton(
        onPressed: () {
          setState(() => _messages.clear());
          _snStream.clear();
        },
        icon: const Icon(Icons.delete, color: Colors.black),
      );



  Widget _buildFooter() => SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'SambaNova',
            style: TextStyle(fontSize: 24, color: Colors.grey.shade400),
          ),
        ),
      );

  Widget _buildTextComposer() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(100.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.black,
                child: Icon(Icons.arrow_upward_rounded, color: Theme.of(context).cardColor),
              ),
              onPressed: () {
                _handleSubmitted(_textController.text);
                FocusScope.of(context).unfocus();
              },
            ),
          ],
        ),
      );

  Future<void> _sendMessage(String text) async {
    try {
      await _snStream.sendMessage(text);
    } catch (e) {
      _handleResponseError(e);
    }
  }

  void _handleResponseDelta(SambaResponseDelta response) {
    final delta = response.choices?.first.message.content;
    if (delta != null) {
      _buffer += delta;

      if (_scrollController.hasClients && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _updateMessageBuffer();
      } else if (!(_debounceTimer?.isActive ?? false)) {
        _debounceTimer = Timer(const Duration(milliseconds: 500), _updateMessageBuffer);
      }
    }
  }

  void _handleResponseError(Object error) {
    _messages.add(ChatMessage(text: error.toString(), isError: true));
    setState(() {});
  }

  void _updateMessageBuffer() {
    if (_messages.isEmpty || _messages.last.isUserMessage) {
      _messages.add(ChatMessage(text: _buffer, isUserMessage: false));
    } else {
      _messages.last.updateText(_buffer);
    }
    setState(() {});
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 0));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }
}

class ChatMessage {
  final String id = UniqueKey().toString();
  String text;
  final bool isUserMessage;
  final bool isError;

  ChatMessage({required this.text, this.isUserMessage = false, this.isError = false});

  void updateText(String newText) => text = newText;
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = message.isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = message.isUserMessage ? Colors.grey.shade200 : theme.cardColor;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: message.isError
              ? Text(message.text, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error))
              : message.isUserMessage 
              ? Text(message.text, style: theme.textTheme.titleMedium,)
              : MarkdownBody(
                  bulletBuilder: (parameters) {
                    if (parameters.style == BulletStyle.orderedList) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "${parameters.index + 1}.",
                          // style: MarkdownFonts.body,
                          maxLines: 1,
                        ),
                      );
                    } else {
                      return Transform.translate(
                        offset: const Offset(20, 0),
                        child: const Text(
                          "•",
                          style: TextStyle(fontSize: 24),
                        ),
                      );
                    }
                  },
                  data: message.text,
                  styleSheet: createCustomMarkdownStyleSheet(context),
                  builders: {
                    'code': CodeElementBuilder(),
                    'latex': LatexElementBuilder(),
                  },
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubWeb.blockSyntaxes,
                    [md.EmojiSyntax(), md.InlineHtmlSyntax(), LatexInlineSyntax()], // Add LaTeX syntax support
                  ),
                ),
        ),
      ],
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return HighlightView(
      element.textContent,
      language: element.attributes['class']?.split('-').last ?? 'plaintext',
      theme: myCodeTheme,
      padding: const EdgeInsets.all(8.0),
      // textStyle: const TextStyle(
      //   fontFamily: 'monospace',
      //   fontSize: 14.0,
      // ),
    );
  }
}

MarkdownStyleSheet createCustomMarkdownStyleSheet(BuildContext context) => MarkdownStyleSheet(
  h1: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent),
  h2: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent.shade700),
  h3: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent.shade400),
  p: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16.0, color: Colors.black87),
  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
  em: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
  code: TextStyle(
    fontFamily: 'monospace',
    fontSize: 14.0,
    color: Colors.grey.shade900,
    backgroundColor: const Color(0xFFF5F5F5),
  ),
  codeblockDecoration: BoxDecoration(
    color: const Color(0xFFF5F5F5),
    borderRadius: BorderRadius.circular(8.0),
    border: Border.all(color: Colors.grey.shade300, width: 1.0),
  ),
  blockquote: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
  blockquoteDecoration: BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(8.0),
    border: const Border(left: BorderSide(color: Colors.blueAccent, width: 4.0)),
  ),
  listBullet: TextStyle(color: Colors.blueAccent.shade400),
  horizontalRuleDecoration: BoxDecoration(
    border: Border(top: BorderSide(color: Colors.grey.shade400, width: 1.0)),
  ),
  a: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
  blockSpacing: 16.0,
  listIndent: 24.0,
  listBulletPadding: const EdgeInsets.only(right: 8.0),
  blockquotePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  codeblockPadding: const EdgeInsets.all(12.0),
);



const myCodeTheme = {
  'root':
  TextStyle(backgroundColor: Color(0xffffff), color: Color(0xff000000)),
  'comment': TextStyle(color: Color(0xff880000)),
  'quote': TextStyle(color: Color(0xff880000)),
  'keyword': TextStyle(color: Color(0xff000088)),
  'selector-tag': TextStyle(color: Color(0xff000088)),
  'section': TextStyle(color: Color(0xff000088)),
  'title': TextStyle(color: Color(0xff660066)),
  'name': TextStyle(color: Color(0xff000088)),
  'variable': TextStyle(color: Color(0xff666600)),
  'template-variable': TextStyle(color: Color(0xff666600)),
  'string': TextStyle(color: Color(0xff008800)),
  'selector-attr': TextStyle(color: Color(0xff008800)),
  'selector-pseudo': TextStyle(color: Color(0xff008800)),
  'regexp': TextStyle(color: Color(0xff008800)),
  'literal': TextStyle(color: Color(0xff006666)),
  'symbol': TextStyle(color: Color(0xff006666)),
  'bullet': TextStyle(color: Color(0xff006666)),
  'meta': TextStyle(color: Color(0xff006666)),
  'number': TextStyle(color: Color(0xff006666)),
  'link': TextStyle(color: Color(0xff006666)),
  'doctag': TextStyle(color: Color(0xff660066), fontWeight: FontWeight.bold),
  'type': TextStyle(color: Color(0xff660066)),
  'attr': TextStyle(color: Color(0xff660066)),
  'built_in': TextStyle(color: Color(0xff660066)),
  'builtin-name': TextStyle(color: Color(0xff660066)),
  'params': TextStyle(color: Color(0xff660066)),
  'attribute': TextStyle(color: Color(0xff000000)),
  'subst': TextStyle(color: Color(0xff000000)),
  'formula': TextStyle(
      backgroundColor: Color(0xffeeeeee), fontStyle: FontStyle.italic),
  'selector-id': TextStyle(color: Color(0xff9B703F)),
  'selector-class': TextStyle(color: Color(0xff9B703F)),
  'addition': TextStyle(backgroundColor: Color(0xffbaeeba)),
  'deletion': TextStyle(backgroundColor: Color(0xffffc8bd)),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
};
