import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class RecipeDbservice {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addRecipe({
    required String instruction,
    required String ingredient,
    required String time,
    required String name,
    required String mood,
    required String category,
  }) async {
    try {
      await _firestore.collection('recipe').doc(const Uuid().v4()).set({
        'instruction': instruction,
        'ingredient': ingredient,
        'time': time,
        'name': name,
        'mood': mood,
        'category': category,
      });
    } catch (e) {
      print('Error adding recipe: $e');
      throw e;
    }
  }
}
