import '../../../../core/storage/conversation_store.dart';
import '../models/conversation.dart';
import 'history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final ConversationStore _store;

  HistoryRepositoryImpl(this._store);

  @override
  List<Conversation> getAll() => _store.listConversations();

  @override
  Future<void> delete(String id) => _store.deleteConversation(id);
}
