import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/comment.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final String currentUserId;
  final VoidCallback onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAuthor = comment.authorId == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author and date
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(
                  comment.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  timeago.format(comment.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (isAuthor)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: onDelete,
                    color: Colors.red,
                    tooltip: 'Delete comment',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Comment content
            Text(
              comment.content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
