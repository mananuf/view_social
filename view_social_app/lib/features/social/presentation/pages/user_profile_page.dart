import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/theme/responsive.dart';
import '../widgets/post_card.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;
  final bool isCurrentUser;
  
  const UserProfilePage({
    super.key,
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isFollowing = false;
  bool _isLoading = false;
  List<PostModel> _posts = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserPosts();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual API call with BLoC
      await Future.delayed(const Duration(seconds: 1));
      
      final posts = _generateMockUserPosts();
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<PostModel> _generateMockUserPosts() {
    return List.generate(10, (index) {
      return PostModel(
        id: 'user_post_$index',
        userId: widget.user.id,
        user: widget.user,
        contentType: PostContentType.text,
        textContent: 'This is a post from ${widget.user.displayName ?? widget.user.username} #$index',
        mediaUrls: [],
        isReel: false,
        visibility: PostVisibility.public,
        likeCount: index * 3,
        commentCount: index * 2,
        reshareCount: index,
        isLiked: index % 2 == 0,
        createdAt: DateTime.now().subtract(Duration(days: index)),
      );
    });
  }
  
  Future<void> _toggleFollow() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual follow/unfollow with BLoC
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isFollowing = !_isFollowing;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing 
                  ? 'Now following ${widget.user.displayName ?? widget.user.username}'
                  : 'Unfollowed ${widget.user.displayName ?? widget.user.username}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'} user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(context, theme),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Tab Bar
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Media'),
                  Tab(text: 'Likes'),
                ],
              ),
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(),
                  _buildMediaTab(),
                  _buildLikesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: Responsive.getPadding(context),
      child: Column(
        children: [
          const SizedBox(height: 60), // Account for status bar and app bar
          
          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: widget.user.avatarUrl != null
                ? CachedNetworkImageProvider(widget.user.avatarUrl!)
                : null,
            child: widget.user.avatarUrl == null
                ? Text(
                    widget.user.displayName?.substring(0, 1).toUpperCase() ??
                        widget.user.username.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(height: 16),
          
          // Name and Username
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.user.displayName ?? widget.user.username,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.getFontSize(context, 20),
                ),
              ),
              if (widget.user.isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ],
          ),
          
          Text(
            '@${widget.user.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: Responsive.getFontSize(context, 14),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Bio
          if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
            Text(
              widget.user.bio!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: Responsive.getFontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                context,
                '${_posts.length}',
                'Posts',
              ),
              _buildStatItem(
                context,
                '${widget.user.followerCount}',
                'Followers',
              ),
              _buildStatItem(
                context,
                '${widget.user.followingCount}',
                'Following',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          if (!widget.isCurrentUser) ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: _isFollowing ? 'Following' : 'Follow',
                    onPressed: _toggleFollow,
                    isLoading: _isLoading,
                    type: _isFollowing ? ButtonType.outline : ButtonType.primary,
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Message',
                  onPressed: () {
                    // TODO: Navigate to chat
                  },
                  type: ButtonType.outline,
                ),
              ],
            ),
          ] else ...[
            CustomButton(
              text: 'Edit Profile',
              onPressed: () {
                // TODO: Navigate to edit profile
              },
              type: ButtonType.outline,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String count, String label) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.getFontSize(context, 18),
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: Responsive.getFontSize(context, 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPostsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_posts.isEmpty) {
      return _buildEmptyState('No posts yet');
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isMobile(context) ? 0 : 16,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return PostCard(
          post: _posts[index],
          onLike: () => _handleLike(_posts[index]),
          onComment: () => _handleComment(_posts[index]),
          onShare: () => _handleShare(_posts[index]),
          onUserTap: () {}, // Already on user profile
        );
      },
    );
  }
  
  Widget _buildMediaTab() {
    final mediaPosts = _posts.where((post) => post.mediaUrls.isNotEmpty).toList();
    
    if (mediaPosts.isEmpty) {
      return _buildEmptyState('No media posts');
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.getCrossAxisCount(context),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: mediaPosts.length,
      itemBuilder: (context, index) {
        final post = mediaPosts[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: const Center(
            child: Icon(Icons.image),
          ),
        );
      },
    );
  }
  
  Widget _buildLikesTab() {
    return _buildEmptyState('Liked posts are private');
  }
  
  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleLike(PostModel post) {
    // TODO: Implement like functionality
  }
  
  void _handleComment(PostModel post) {
    // TODO: Navigate to post detail
  }
  
  void _handleShare(PostModel post) {
    // TODO: Implement share functionality
  }
}