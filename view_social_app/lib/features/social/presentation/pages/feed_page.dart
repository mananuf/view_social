import 'package:flutter/material.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../core/theme/responsive.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_fab.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ScrollController _scrollController = ScrollController();
  final List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMorePosts();
      }
    }
  }
  
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual API call with BLoC
      await Future.delayed(const Duration(seconds: 1));
      
      final newPosts = _generateMockPosts(20);
      
      setState(() {
        _posts.clear();
        _posts.addAll(newPosts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load posts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadMorePosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual API call with BLoC
      await Future.delayed(const Duration(seconds: 1));
      
      final newPosts = _generateMockPosts(10);
      
      setState(() {
        _posts.addAll(newPosts);
        _isLoading = false;
        
        // Simulate end of data after 50 posts
        if (_posts.length >= 50) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _onRefresh() async {
    await _loadPosts();
  }
  
  List<PostModel> _generateMockPosts(int count) {
    return List.generate(count, (index) {
      final postIndex = _posts.length + index;
      return PostModel(
        id: 'post_$postIndex',
        userId: 'user_${postIndex % 5}',
        user: UserModel(
          id: 'user_${postIndex % 5}',
          username: 'user${postIndex % 5}',
          email: 'user${postIndex % 5}@example.com',
          displayName: 'User ${postIndex % 5}',
          avatarUrl: null,
          isVerified: postIndex % 10 == 0,
          followerCount: (postIndex % 5) * 100,
          followingCount: (postIndex % 3) * 50,
          createdAt: DateTime.now().subtract(Duration(days: postIndex)),
        ),
        contentType: PostContentType.text,
        textContent: _generateMockContent(postIndex),
        mediaUrls: [],
        isReel: false,
        visibility: PostVisibility.public,
        likeCount: postIndex * 5,
        commentCount: postIndex * 2,
        reshareCount: postIndex,
        isLiked: postIndex % 3 == 0,
        createdAt: DateTime.now().subtract(Duration(hours: postIndex)),
      );
    });
  }
  
  String _generateMockContent(int index) {
    final contents = [
      'Just had an amazing day exploring the city! 🌟',
      'Working on some exciting new projects. Can\'t wait to share! 💻',
      'Beautiful sunset today. Nature never fails to amaze me 🌅',
      'Coffee and coding - the perfect combination ☕️',
      'Grateful for all the wonderful people in my life ❤️',
      'New week, new opportunities! Let\'s make it count 💪',
      'Sometimes the best moments are the quiet ones 🌸',
      'Learning something new every day keeps life interesting 📚',
      'Good vibes only! Spreading positivity wherever I go ✨',
      'Weekend adventures are the best kind of therapy 🏞️',
    ];
    
    return contents[index % contents.length];
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.visibility,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('VIEW'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search page
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications page
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _posts.isEmpty && _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _posts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.isMobile(context) ? 0 : 16,
                    ),
                    itemCount: _posts.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      return PostCard(
                        post: _posts[index],
                        onLike: () => _handleLike(_posts[index]),
                        onComment: () => _handleComment(_posts[index]),
                        onShare: () => _handleShare(_posts[index]),
                        onUserTap: () => _handleUserTap(_posts[index].user!),
                      );
                    },
                  ),
      ),
      floatingActionButton: const CreatePostFab(),
    );
  }
  
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow some users or create your first post!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleLike(PostModel post) {
    // TODO: Implement like functionality with BLoC
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post.copyWith(
          isLiked: !post.isLiked,
          likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
        );
      }
    });
  }
  
  void _handleComment(PostModel post) {
    // TODO: Navigate to post detail page with comments
  }
  
  void _handleShare(PostModel post) {
    // TODO: Implement share functionality
  }
  
  void _handleUserTap(UserModel user) {
    // TODO: Navigate to user profile page
  }
}