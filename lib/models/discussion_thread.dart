import 'package:cloud_firestore/cloud_firestore.dart';

class DiscussionThread {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int replyCount;
  
  const DiscussionThread({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.replyCount = 0,
  });
  
  // Convert from Firestore document
  factory DiscussionThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiscussionThread(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      replyCount: data['replyCount'] ?? 0,
    );
  }
  
  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'replyCount': replyCount,
    };
  }
  
  // Create a copy with updated fields
  DiscussionThread copyWith({
    String? title,
    String? content,
    int? replyCount,
  }) {
    return DiscussionThread(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId,
      authorName: authorName,
      createdAt: createdAt,
      replyCount: replyCount ?? this.replyCount,
    );
  }
}
