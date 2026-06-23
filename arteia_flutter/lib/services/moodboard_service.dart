import 'package:uuid/uuid.dart';

class MoodBoard {
  final String id;
  final String title;
  final String description;
  final String userId;
  final List<String> imageUrls;
  final List<String> audioUrls;
  final List<String> textSnippets;
  final DateTime createdAt;

  MoodBoard({
    required this.id,
    required this.title,
    this.description = '',
    required this.userId,
    this.imageUrls = const [],
    this.audioUrls = const [],
    this.textSnippets = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class MoodBoardService {
  final List<MoodBoard> _moodBoards = [];
  final Uuid _uuid = const Uuid();

  List<MoodBoard> getBoards(String userId) =>
      _moodBoards.where((b) => b.userId == userId).toList();

  List<MoodBoard> get publicBoards => _moodBoards;

  MoodBoard createBoard({
    required String title,
    String description = '',
    required String userId,
    List<String> imageUrls = const [],
    List<String> audioUrls = const [],
    List<String> textSnippets = const [],
  }) {
    final board = MoodBoard(
      id: _uuid.v4(),
      title: title,
      description: description,
      userId: userId,
      imageUrls: imageUrls,
      audioUrls: audioUrls,
      textSnippets: textSnippets,
    );
    _moodBoards.add(board);
    return board;
  }

  void addToBoard(String boardId, {List<String>? images, List<String>? audios, List<String>? texts}) {
    final index = _moodBoards.indexWhere((b) => b.id == boardId);
    if (index == -1) return;

    final board = _moodBoards[index];
    _moodBoards[index] = MoodBoard(
      id: board.id,
      title: board.title,
      description: board.description,
      userId: board.userId,
      imageUrls: [...board.imageUrls, ...?images],
      audioUrls: [...board.audioUrls, ...?audios],
      textSnippets: [...board.textSnippets, ...?texts],
      createdAt: board.createdAt,
    );
  }
}