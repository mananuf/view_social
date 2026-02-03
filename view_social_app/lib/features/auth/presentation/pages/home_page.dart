import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';
import 'welcome_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: DesignTokens.animationNormal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: DesignTokens.curveEaseOut,
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildExplorePage(),
            _buildMessagesPage(),
            _buildPaymentsPage(),
            _buildProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(color: AppTheme.lightBorderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Explore',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Messages',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                label: 'Payments',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: Container(
          padding: DesignTokens.paddingVerticalXs,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: DesignTokens.animationFast,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: DesignTokens.borderRadiusLg,
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.lightTextSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: DesignTokens.getCaptionStyle(
                  context,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.lightTextSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplorePage() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.white,
          elevation: 0,
          floating: true,
          snap: true,
          title: Text(
            'Explore',
            style: DesignTokens.getHeadingStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTextPrimary,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                // TODO: Implement search
              },
              icon: const Icon(Icons.search, color: AppTheme.lightTextPrimary),
            ),
            IconButton(
              onPressed: () {
                // TODO: Implement notifications
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: DesignTokens.paddingLg,
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildWelcomeCard(),
              SizedBox(height: DesignTokens.spaceLg),
              _buildQuickActions(),
              SizedBox(height: DesignTokens.spaceLg),
              _buildRecentActivity(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: DesignTokens.padding2xl,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.brightPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DesignTokens.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to VIEW!',
            style: DesignTokens.getHeadingStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
          ),
          SizedBox(height: DesignTokens.spaceSm),
          Text(
            'Connect, Share, and Pay with ease',
            style: DesignTokens.getBodyStyle(
              context,
              fontSize: 16,
              color: AppTheme.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: DesignTokens.getHeadingStyle(
            context,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTextPrimary,
          ),
        ),
        SizedBox(height: DesignTokens.spaceLg),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'Create Post',
                subtitle: 'Share your thoughts',
                onTap: () {
                  // TODO: Implement create post
                },
              ),
            ),
            SizedBox(width: DesignTokens.spaceLg),
            Expanded(
              child: _buildActionCard(
                icon: Icons.send_outlined,
                title: 'Send Money',
                subtitle: 'Quick transfer',
                onTap: () {
                  // TODO: Implement send money
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: DesignTokens.paddingLg,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: DesignTokens.borderRadiusXl,
          border: Border.all(color: AppTheme.lightBorderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: DesignTokens.borderRadiusLg,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: DesignTokens.iconLg,
              ),
            ),
            SizedBox(height: DesignTokens.spaceLg),
            Text(
              title,
              style: DesignTokens.getBodyStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTextPrimary,
              ),
            ),
            SizedBox(height: DesignTokens.spaceXs),
            Text(
              subtitle,
              style: DesignTokens.getBodyStyle(
                context,
                fontSize: 14,
                color: AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: DesignTokens.getHeadingStyle(
            context,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTextPrimary,
          ),
        ),
        SizedBox(height: DesignTokens.spaceLg),
        Container(
          padding: DesignTokens.padding2xl,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: DesignTokens.borderRadiusXl,
            border: Border.all(color: AppTheme.lightBorderColor, width: 1),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.timeline_outlined,
                  size: 48,
                  color: AppTheme.lightTextSecondary,
                ),
                SizedBox(height: DesignTokens.spaceLg),
                Text(
                  'No recent activity',
                  style: DesignTokens.getBodyStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTextPrimary,
                  ),
                ),
                SizedBox(height: DesignTokens.spaceXs),
                Text(
                  'Start connecting with friends to see activity here',
                  style: DesignTokens.getBodyStyle(
                    context,
                    fontSize: 14,
                    color: AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesPage() {
    return _buildPlaceholderPage(
      icon: Icons.chat_bubble_outline,
      title: 'Messages',
      subtitle: 'Your conversations will appear here',
    );
  }

  Widget _buildPaymentsPage() {
    return _buildPlaceholderPage(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Payments',
      subtitle: 'Manage your transactions and wallet',
    );
  }

  Widget _buildProfilePage() {
    return SafeArea(
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            // Navigate back to welcome page after logout
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const WelcomePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: DesignTokens.animationNormal,
              ),
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Logout failed: ${state.message}',
                  style: DesignTokens.getBodyStyle(
                    context,
                    fontSize: 14,
                    color: AppTheme.white,
                  ),
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: DesignTokens.borderRadiusLg,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: DesignTokens.paddingLg,
          child: Column(
            children: [
              // App Bar
              Row(
                children: [
                  Text(
                    'Profile',
                    style: DesignTokens.getHeadingStyle(
                      context,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement settings
                    },
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: DesignTokens.space2xl),

              // Profile Info
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: DesignTokens.borderRadius3xl,
                ),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),

              SizedBox(height: DesignTokens.spaceLg),

              Text(
                'Welcome User!',
                style: DesignTokens.getHeadingStyle(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTextPrimary,
                ),
              ),

              SizedBox(height: DesignTokens.spaceXs),

              Text(
                'Manage your account and settings',
                style: DesignTokens.getBodyStyle(
                  context,
                  fontSize: 16,
                  color: AppTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Logout Button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return CustomButton(
                    text: 'Logout',
                    onPressed: () {
                      context.read<AuthBloc>().add(const LogoutEvent());
                    },
                    isLoading: state is AuthLoading,
                    fullWidth: true,
                    size: ButtonSize.large,
                    type: ButtonType.outline,
                    customColor: AppTheme.errorColor,
                  );
                },
              ),

              SizedBox(height: DesignTokens.space2xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SafeArea(
      child: Padding(
        padding: DesignTokens.paddingLg,
        child: Column(
          children: [
            // App Bar
            Row(
              children: [
                Text(
                  title,
                  style: DesignTokens.getHeadingStyle(
                    context,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // TODO: Implement settings
                  },
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),

            // Content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: DesignTokens.borderRadius3xl,
                      ),
                      child: Icon(icon, size: 60, color: AppTheme.primaryColor),
                    ),
                    SizedBox(height: DesignTokens.space2xl),
                    Text(
                      'Coming Soon',
                      style: DesignTokens.getHeadingStyle(
                        context,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTextPrimary,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spaceLg),
                    Text(
                      subtitle,
                      style: DesignTokens.getBodyStyle(
                        context,
                        fontSize: 16,
                        color: AppTheme.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
