import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/message_bubble.dart';
import '../bloc/voice_conversation_bloc.dart';

class VoiceConversationScreen extends StatelessWidget {
  const VoiceConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Conversation')),
      body: BlocConsumer<VoiceConversationBloc, VoiceConversationState>(
        listenWhen: (p, c) => c.status == VoiceStatus.error,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? const Center(
                        child: Text('Tap the mic and start speaking.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, i) {
                          final m = state.messages[i];
                          return MessageBubble(
                              text: m.content, isUser: m.isUser);
                        },
                      ),
              ),
              _StatusBar(state: state),
              _MicButton(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final VoiceConversationState state;
  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    String label;
    switch (state.status) {
      case VoiceStatus.listening:
        label = state.partialTranscript.isEmpty
            ? 'Listening…'
            : state.partialTranscript;
      case VoiceStatus.processing:
        label = 'Thinking…';
      case VoiceStatus.speaking:
        label = 'Speaking…';
      default:
        label = 'Idle';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final VoiceConversationState state;
  const _MicButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VoiceConversationBloc>();
    final listening = state.isListening;
    final busy = state.isBusy;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: busy
              ? () => bloc.add(const VoiceSpeakingStopped())
              : () => bloc.add(listening
                  ? const VoiceListenStopped()
                  : const VoiceListenRequested()),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: listening
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            child: Icon(
              busy
                  ? Icons.stop
                  : (listening ? Icons.mic : Icons.mic_none),
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}
