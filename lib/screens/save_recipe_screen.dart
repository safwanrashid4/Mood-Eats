import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moodeatsai/constants/constants.dart';
import 'package:page_transition/page_transition.dart';
import 'package:moodeatsai/screens/screens.dart';

class SaveRecipeScreen extends StatefulWidget {
  final String title;
  final List<String>? allergies;

  const SaveRecipeScreen({Key? key, required this.title, this.allergies})
      : super(key: key);

  @override
  State<SaveRecipeScreen> createState() => _SaveRecipeScreenState();
}

class _SaveRecipeScreenState extends State<SaveRecipeScreen> {
  late Future<List<DocumentSnapshot>> _bookmarkedRecipes;

  Future<List<DocumentSnapshot>> fetchBookmarkedRecipes() async {
    final userData = await FirebaseFirestore.instance
        .collection('save_recipe')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    final bookmarkIds = List<String>.from(userData.get('bookmarks') ?? []);

    final List<DocumentSnapshot> bookmarkedRecipes = [];
    for (final id in bookmarkIds) {
      final docSnapshot =
          await FirebaseFirestore.instance.collection('recipe').doc(id).get();
      if (docSnapshot.exists) {
        bookmarkedRecipes.add(docSnapshot);
      }
    }

    return bookmarkedRecipes;
  }

  @override
  void initState() {
    super.initState();
    _bookmarkedRecipes = fetchBookmarkedRecipes();
    _bookmarkedRecipes.then((recipes) {
      log('Bookmarked Recipes: $recipes');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text(' Recipes'),
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
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _bookmarkedRecipes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CupertinoActivityIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final bookmarkedRecipes = snapshot.data!;
                  if (bookmarkedRecipes.isEmpty) {
                    return Center(
                      child: Text('No saved recipes'),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: bookmarkedRecipes.length,
                      itemBuilder: (context, index) {
                        final recipeData = bookmarkedRecipes[index].data()
                            as Map<String, dynamic>;

                        return createListTile(
                          recipeData['name'],
                          recipeData['time'],
                          recipeData['ingredient'],
                          recipeData['instruction'],
                          snapshot.data![index].id,
                        );
                      },
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget createListTile(String title, String time, String ingredient,
      String instruction, String uid) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: AppColors.brownShade,
          child: ListTile(
            leading: Image.asset(
              AppImages.recipeIcon,
              height: 50,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(time),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
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
                    isNavFromRecommended: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
