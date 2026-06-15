import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../multilingual/data/models/language_option.dart';
import '../bloc/translation_bloc.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Translation')),
      body: BlocConsumer<TranslationBloc, TranslationState>(
        listenWhen: (p, c) => c.status == TranslationStatus.error,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<TranslationBloc>();
          return Column(
            children: [
              _LanguageBar(state: state),
              if (state.status == TranslationStatus.listening)
                _Banner(
                    text: state.partialTranscript.isEmpty
                        ? 'Listening…'
                        : state.partialTranscript),
              if (state.status == TranslationStatus.translating)
                const _Banner(text: 'Translating…'),
              Expanded(
                child: state.results.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Speak or type to translate between languages.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final r = state.results[i];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.sourceText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(r.translatedText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.volume_up),
                                        onPressed: () => bloc.add(
                                            TranslationSpeakRequested(
                                                r.translatedText)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              _InputBar(controller: _controller, state: state),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageBar extends StatelessWidget {
  final TranslationState state;
  const _LanguageBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TranslationBloc>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _LangDropdown(
              value: state.sourceLanguage,
              onChanged: (l) =>
                  bloc.add(TranslationSourceLanguageChanged(l)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => bloc.add(const TranslationLanguagesSwapped()),
          ),
          Expanded(
            child: _LangDropdown(
              value: state.targetLanguage,
              onChanged: (l) =>
                  bloc.add(TranslationTargetLanguageChanged(l)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangDropdown extends StatelessWidget {
  final LanguageOption value;
  final ValueChanged<LanguageOption> onChanged;
  const _LangDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<LanguageOption>(
      value: value,
      isExpanded: true,
      items: LanguageOption.supported
          .map((l) =>
              DropdownMenuItem(value: l, child: Text(l.nativeName)))
          .toList(),
      onChanged: (l) => l == null ? null : onChanged(l),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  const _Banner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(8),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final TranslationState state;
  const _InputBar({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TranslationBloc>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  bloc.add(TranslationTextSubmitted(v));
                  controller.clear();
                },
                decoration:
                    const InputDecoration(hintText: 'Type text to translate…'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: state.isListening
                  ? () => bloc.add(const TranslationListenStopped())
                  : () => bloc.add(const TranslationListenRequested()),
              icon: Icon(state.isListening ? Icons.mic : Icons.mic_none),
            ),
          ],
        ),
      ),
    );
  }
}
