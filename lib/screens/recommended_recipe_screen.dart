import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodeatsai/constants/constants.dart';
import 'package:page_transition/page_transition.dart';
import 'package:moodeatsai/screens/screens.dart';

class RecommendedRecipeScreen extends StatefulWidget {
  final String title;
  final List<String>? allergies;

  const RecommendedRecipeScreen({
    Key? key,
    required this.title,
    this.allergies,
  }) : super(key: key);

  @override
  RecommendedRecipeScreenState createState() => RecommendedRecipeScreenState();
}

class RecommendedRecipeScreenState extends State<RecommendedRecipeScreen> {
  late Stream<List<DocumentSnapshot>> _filteredRecipesStream;

  @override
  void initState() {
    super.initState();
    _filteredRecipesStream = _getFilteredRecipesStream();
  }

  Stream<List<DocumentSnapshot>> _getFilteredRecipesStream() {
    CollectionReference recipesRef =
        FirebaseFirestore.instance.collection('recipe');

    Query filteredQuery = recipesRef;

    // Filter by allergy items matching with category
    if (widget.allergies != null && widget.allergies!.isNotEmpty) {
      filteredQuery =
          filteredQuery.where('category', whereNotIn: widget.allergies);
    }

    return filteredQuery.snapshots().map((querySnapshot) {
      List<DocumentSnapshot> allRecipes = querySnapshot.docs;
      List<DocumentSnapshot> randomRecipes = [];

      // Divide the documents into groups
      int groupSize = (allRecipes.length / 3).ceil();

      // Shuffle each group separately
      allRecipes.shuffle();
      List<DocumentSnapshot> firstGroup = allRecipes.take(groupSize).toList();
      allRecipes.shuffle();
      List<DocumentSnapshot> secondGroup = allRecipes.take(groupSize).toList();
      allRecipes.shuffle();
      List<DocumentSnapshot> thirdGroup = allRecipes.take(groupSize).toList();

      // Randomly select a certain number of documents from each group
      randomRecipes.addAll(firstGroup.take(2));
      randomRecipes.addAll(secondGroup.take(2));
      randomRecipes.addAll(thirdGroup.take(1));

      // Shuffle the final list to ensure randomness
      randomRecipes.shuffle();

      return randomRecipes;
    });
  }

  Widget _buildRecipeList(BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    if (snapshot.data == null || snapshot.data!.isEmpty) {
      return const Center(child: Text('No recipes found.'));
    }

    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) {
        var recipeData =
            snapshot.data![index].data() as Map<String, dynamic>;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              color: AppColors.brownShade,
              child: createListTile(
                recipeData['name'],
                recipeData['time'],
                recipeData['ingredient'],
                recipeData['instruction'],
                snapshot.data![index].id,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Recommended Recipes'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 15, top: 15),
              child: Text(
                widget.title,
                style:
                    const TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _filteredRecipesStream,
              builder: _buildRecipeList,
            ),
          ),
        ],
      ),
    );
  }

  Widget createListTile(String title, String time, String ingredient,
      String instruction, String uid) {
    return ListTile(
      title: Text(title),
      subtitle: Text(time),
      onTap: () {
        // Navigate to recipe details screen
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            child: RecipeDetailScreen(
              name: title,
              time: time,
              ingredient: ingredient,
              instructions: instruction,
              uid: uid,
              isNavFromRecommended: true,
            ),
          ),
        );
      },
    );
  }
}
