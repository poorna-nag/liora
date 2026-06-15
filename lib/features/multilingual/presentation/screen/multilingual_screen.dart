import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/message_bubble.dart';
import '../../data/models/language_option.dart';
import '../bloc/multilingual_bloc.dart';

class MultilingualScreen extends StatefulWidget {
  const MultilingualScreen({super.key});

  @override
  State<MultilingualScreen> createState() => _MultilingualScreenState();
}

class _MultilingualScreenState extends State<MultilingualScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<MultilingualBloc>().add(MultilingualMessageSent(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multilingual Chat'),
        actions: [
          BlocBuilder<MultilingualBloc, MultilingualState>(
            buildWhen: (p, c) => p.language != c.language,
            builder: (context, state) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<LanguageOption>(
                value: state.language,
                underline: const SizedBox.shrink(),
                items: LanguageOption.supported
                    .map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.nativeName),
                        ))
                    .toList(),
                onChanged: (l) => l == null
                    ? null
                    : context
                        .read<MultilingualBloc>()
                        .add(MultilingualLanguageChanged(l)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<MultilingualBloc, MultilingualState>(
              listenWhen: (p, c) => c.status == MultilingualStatus.error,
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage!)),
                  );
                }
              },
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                        'Chat in ${state.language.nativeName}. Type in any '
                        'language and I will reply in '
                        '${state.language.name}.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.messages.length,
                  itemBuilder: (context, i) {
                    final m = state.messages[i];
                    return MessageBubble(text: m.content, isUser: m.isUser);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(context),
                      decoration:
                          const InputDecoration(hintText: 'Type a message…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(context),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
