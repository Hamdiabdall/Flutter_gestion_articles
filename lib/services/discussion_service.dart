import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/discussion_thread.dart';
import '../services/firebase_service.dart';

class DiscussionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new discussion thread
  Future<String> createDiscussionThread({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
  }) async {
    // Verify user is authenticated first
    final currentUser = FirebaseService.auth!.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to create a discussion');
    }
    
    // Verify the authorId matches the current user's UID
    if (currentUser.uid != authorId) {
      throw Exception('Author ID must match the current user');
    }
    
    try {
      // Create a complete thread object matching the Firestore rules requirements
      final now = DateTime.now();
      final threadData = {
        'title': title.trim(),
        'content': content.trim(),
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': Timestamp.fromDate(now),
        'replyCount': 0,
      };

      // Add the document to Firestore
      final docRef = await _firestore.collection('discussions').add(threadData);
      print('Successfully created discussion with ID: ${docRef.id}');
      return docRef.id;
    } catch (error) {
      print('Error creating discussion thread: $error');
      throw Exception('Failed to create discussion: $error');
    }
  }

  // Get all discussion threads
  Stream<List<DiscussionThread>> getDiscussionThreads() {
    try {
      return _firestore
          .collection('discussions')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => DiscussionThread.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      // Log the error and rethrow
      print('Error getting discussion threads: $e');
      rethrow;
    }
  }

  // Get a single discussion thread by ID
  Stream<DiscussionThread?> getDiscussionThreadById(String threadId) {
    return _firestore
        .collection('discussions')
        .doc(threadId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return DiscussionThread.fromFirestore(doc);
          }
          return null;
        });
  }

  // Update a discussion thread
  Future<void> updateDiscussionThread(DiscussionThread thread) async {
    // Verify user is authenticated first
    final currentUser = FirebaseService.auth!.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to update a discussion');
    }
    
    // Verify the current user is the author of the thread
    if (currentUser.uid != thread.authorId) {
      throw Exception('You can only update your own discussions');
    }
    
    try {
      await _firestore.collection('discussions').doc(thread.id).update({
        'title': thread.title,
        'content': thread.content,
        'updatedAt': FieldValue.serverTimestamp(), // Track when it was updated
      });
    } catch (error) {
      print('Error updating discussion thread: $error');
      throw Exception('Failed to update discussion: $error');
    }
  }

  // Delete a discussion thread
  Future<void> deleteDiscussionThread(String threadId) async {
    try {
      // Verify user is authenticated first
      final currentUser = FirebaseService.auth!.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to delete a discussion');
      }
      
      // Get the thread to verify ownership
      final threadDoc = await _firestore.collection('discussions').doc(threadId).get();
      if (!threadDoc.exists) {
        throw Exception('Discussion thread not found');
      }
      
      // Verify the current user is the author of the thread
      final threadData = threadDoc.data() as Map<String, dynamic>;
      if (threadData['authorId'] != currentUser.uid) {
        throw Exception('You can only delete your own discussions');
      }
      
      // First delete all replies (using a transaction for atomic operations)
      final repliesQuery = await _firestore
          .collection('discussions')
          .doc(threadId)
          .collection('replies')
          .get();

      final batch = _firestore.batch();
      for (var doc in repliesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the thread itself
      batch.delete(_firestore.collection('discussions').doc(threadId));
      
      await batch.commit();
    } catch (error) {
      print('Error deleting discussion thread: $error');
      throw Exception('Failed to delete discussion: $error');
    }
  }

  // Add a reply to a discussion thread
  Future<void> addReply({
    required String threadId,
    required String content,
    required String authorId,
    required String authorName,
  }) async {
    try {
      // Verify user is authenticated first
      final currentUser = FirebaseService.auth!.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to add a reply');
      }
      
      // Verify the authorId matches the current user
      if (currentUser.uid != authorId) {
        throw Exception('Author ID must match the current user');
      }
      
      // First check if the thread exists
      final threadDoc = await _firestore.collection('discussions').doc(threadId).get();
      if (!threadDoc.exists) {
        throw Exception('Discussion thread not found');
      }
      
      // Create reply data that exactly matches our security rules
      final replyData = {
        'content': content.trim(),
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': Timestamp.now(),
      };

      // Use a transaction to add the reply and update the reply count
      await _firestore.runTransaction((transaction) async {
        // Get a new document reference for the reply
        final replyRef = _firestore
            .collection('discussions')
            .doc(threadId)
            .collection('replies')
            .doc();
        
        // Set the reply data
        transaction.set(replyRef, replyData);

        // Update the discussion thread's reply count
        final threadRef = _firestore.collection('discussions').doc(threadId);
        transaction.update(threadRef, {
          'replyCount': FieldValue.increment(1),
        });
      });
      
      print('Reply added successfully to thread: $threadId');
    } catch (error) {
      print('Error adding reply: $error');
      throw Exception('Failed to add reply: $error');
    }
  }

  // Delete a reply from a discussion thread
  Future<void> deleteReply({
    required String threadId,
    required String replyId,
  }) async {
    // Use a transaction to delete the reply and update the thread's reply count
    await _firestore.runTransaction((transaction) async {
      // Delete the reply
      final replyRef = _firestore
          .collection('discussions')
          .doc(threadId)
          .collection('replies')
          .doc(replyId);
      transaction.delete(replyRef);
      
      // Update the discussion thread's reply count
      final threadRef = _firestore.collection('discussions').doc(threadId);
      transaction.update(threadRef, {
        'replyCount': FieldValue.increment(-1),
      });
    });
  }

  // Get all replies for a discussion thread
  Stream<List<Map<String, dynamic>>> getReplies(String threadId) {
    return _firestore
        .collection('discussions')
        .doc(threadId)
        .collection('replies')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'content': data['content'] ?? '',
              'authorId': data['authorId'] ?? '',
              'authorName': data['authorName'] ?? 'Anonymous',
              'createdAt': (data['createdAt'] as Timestamp).toDate(),
            };
          }).toList();
        });
  }
}
