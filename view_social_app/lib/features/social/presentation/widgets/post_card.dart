import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/models/post_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/responsive.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onUserTap;
  
  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onUserTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.isMobile(context) ? 8 : 0,
        vertical: 4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            _buildUserHeader(context, theme),
            
            const SizedBox(height: 12),
            
            // Post Content
            if (post.textContent != null && post.textContent!.isNotEmpty)
              _buildTextContent(context, theme),
            
            // Media Content
            if (post.mediaUrls.isNotEmpty)
              _buildMediaContent(context),
            
            const SizedBox(height: 12),
            
            // Engagement Actions
            _buildEngagementActions(context, theme),
            
            // Engagement Stats
            if (post.likeCount > 0 || post.commentCount > 0)
              _buildEngagementStats(context, theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserHeader(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: onUserTap,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: post.user?.avatarUrl != null
                ? CachedNetworkImageProvider(post.user!.avatarUrl!)
                : null,
            child: post.user?.avatarUrl == null
                ? Text(
                    post.user?.displayName?.substring(0, 1).toUpperCase() ??
                        post.user?.username.substring(0, 1).toUpperCase() ??
                        'U',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.user?.displayName ?? post.user?.username ?? 'Unknown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.getFontSize(context, 14),
                      ),
                    ),
                    if (post.user?.isVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                Text(
                  '@${post.user?.username ?? 'unknown'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: Responsive.getFontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Time and Menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(post.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: Responsive.getFontSize(context, 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                iconSize: 20,
                onPressed: () => _showPostMenu(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        post.textContent!,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: Responsive.getFontSize(context, 16),
          height: 1.4,
        ),
      ),
    );
  }
  
  Widget _buildMediaContent(BuildContext context) {
    if (post.mediaUrls.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: post.mediaUrls.length == 1
            ? _buildSingleMedia(post.mediaUrls.first)
            : _buildMultipleMedia(),
      ),
    );
  }
  
  Widget _buildSingleMedia(MediaAttachment media) {
    if (media.type == 'image') {
      return CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error),
        ),
      );
    } else if (media.type == 'video') {
      return Stack(
        alignment: Alignment.center,
        children: [
          if (media.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: media.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      );
    }
    
    return const Center(
      child: Icon(Icons.attachment),
    );
  }
  
  Widget _buildMultipleMedia() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: post.mediaUrls.length > 2 ? 2 : post.mediaUrls.length,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: post.mediaUrls.length > 4 ? 4 : post.mediaUrls.length,
      itemBuilder: (context, index) {
        if (index == 3 && post.mediaUrls.length > 4) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildSingleMedia(post.mediaUrls[index]),
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Text(
                    '+${post.mediaUrls.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        
        return _buildSingleMedia(post.mediaUrls[index]);
      },
    );
  }
  
  Widget _buildEngagementActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Like Button
        _buildActionButton(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          color: post.isLiked ? AppTheme.likeColor : null,
          onTap: onLike,
        ),
        
        const SizedBox(width: 24),
        
        // Comment Button
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          color: AppTheme.commentColor,
          onTap: onComment,
        ),
        
        const SizedBox(width: 24),
        
        // Share Button
        _buildActionButton(
          icon: Icons.share_outlined,
          color: AppTheme.shareColor,
          onTap: onShare,
        ),
        
        const Spacer(),
        
        // Bookmark Button
        _buildActionButton(
          icon: Icons.bookmark_border,
          onTap: () {
            // TODO: Implement bookmark functionality
          },
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 22,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildEngagementStats(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (post.likeCount > 0) ...[
            Text(
              '${_formatCount(post.likeCount)} likes',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: Responsive.getFontSize(context, 12),
              ),
            ),
            if (post.commentCount > 0) ...[
              const SizedBox(width: 16),
              Text(
                '${_formatCount(post.commentCount)} comments',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: Responsive.getFontSize(context, 12),
                ),
              ),
            ],
          ] else if (post.commentCount > 0) ...[
            Text(
              '${_formatCount(post.commentCount)} comments',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: Responsive.getFontSize(context, 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
  
  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
  
  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Save Post'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement save functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Post'),
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}