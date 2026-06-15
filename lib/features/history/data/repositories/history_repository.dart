import '../models/conversation.dart';

/// Lists and manages stored conversations for the history view.
abstract class HistoryRepository {
  List<Conversation> getAll();
  Future<void> delete(String id);
}
