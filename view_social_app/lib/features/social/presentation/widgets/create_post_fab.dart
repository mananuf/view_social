import 'package:flutter/material.dart';
import '../pages/create_post_page.dart';

class CreatePostFab extends StatelessWidget {
  const CreatePostFab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FloatingActionButton(
      onPressed: () => _navigateToCreatePost(context),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }
  
  void _navigateToCreatePost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreatePostPage(),
      ),
    );
  }
}