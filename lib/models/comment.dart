class Comment {
  final String id;
  final String articleId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.articleId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  // Create a Comment object from a Firestore document
  factory Comment.fromFirestore(Map<String, dynamic> data, String id) {
    return Comment(
      id: id,
      articleId: data['articleId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert a Comment object to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'articleId': articleId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
