import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/search_bar_widget.dart';
import '../widgets/chat_tile.dart';
import 'chat_detail_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedChats = {};
  bool _isSelectionMode = false;
  List<ChatData> _filteredChats = [];

  // Dummy chat data
  final List<ChatData> _dummyChats = [
    ChatData(
      id: 1,
      name: 'Avicii Ronaldo',
      lastMessage: 'Heyo',
      time: '5:15',
      hasStatus: true,
      unreadCount: 3,
    ),
    ChatData(
      id: 2,
      name: 'Netia Horaan',
      lastMessage: 'Heyo',
      time: '5:15',
      hasStatus: false,
      unreadCount: 0,
    ),
    ChatData(
      id: 3,
      name: 'Segam Holland',
      lastMessage: 'Heyo',
      time: '5:15',
      hasStatus: true,
      unreadCount: 0,
    ),
    ChatData(
      id: 4,
      name: 'Natia Horaan',
      lastMessage: 'Heyo',
      time: '5:15',
      hasStatus: false,
      unreadCount: 1,
    ),
    ChatData(
      id: 5,
      name: 'John Doe',
      lastMessage: 'See you tomorrow!',
      time: '4:30',
      hasStatus: true,
      unreadCount: 0,
    ),
    ChatData(
      id: 6,
      name: 'Sarah Smith',
      lastMessage: 'Thanks for the help',
      time: '3:45',
      hasStatus: false,
      unreadCount: 5,
    ),
    ChatData(
      id: 7,
      name: 'Mike Johnson',
      lastMessage: 'Let\'s meet at 6',
      time: '2:20',
      hasStatus: true,
      unreadCount: 0,
    ),
    ChatData(
      id: 8,
      name: 'Emma Wilson',
      lastMessage: 'Great idea!',
      time: '1:15',
      hasStatus: false,
      unreadCount: 2,
    ),
    ChatData(
      id: 9,
      name: 'David Brown',
      lastMessage: 'I\'ll send you the files',
      time: 'Yesterday',
      hasStatus: true,
      unreadCount: 0,
    ),
    ChatData(
      id: 10,
      name: 'Lisa Anderson',
      lastMessage: 'Perfect timing',
      time: 'Yesterday',
      hasStatus: false,
      unreadCount: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredChats = List.from(_dummyChats);
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChats = List.from(_dummyChats);
      } else {
        _filteredChats = _dummyChats
            .where(
              (chat) =>
                  chat.name.toLowerCase().contains(query) ||
                  chat.lastMessage.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _toggleSelection(int chatId) {
    setState(() {
      if (_selectedChats.contains(chatId)) {
        _selectedChats.remove(chatId);
        if (_selectedChats.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedChats.add(chatId);
      }
    });
  }

  void _enterSelectionMode(int chatId) {
    setState(() {
      _isSelectionMode = true;
      _selectedChats.add(chatId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedChats.clear();
    });
  }

  void _deleteSelectedChats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chats'),
        content: Text(
          'Are you sure you want to delete ${_selectedChats.length} chat(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _dummyChats.removeWhere(
                  (chat) => _selectedChats.contains(chat.id),
                );
                _filterChats();
                _exitSelectionMode();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Chats deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _archiveSelectedChats() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedChats.length} chat(s) archived')),
    );
    _exitSelectionMode();
  }

  void _deleteChat(int chatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _dummyChats.removeWhere((chat) => chat.id == chatId);
                _filterChats();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _archiveChat(int chatId) {
    final chat = _dummyChats.firstWhere((c) => c.id == chatId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${chat.name} archived')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFFAFAFC),
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: theme.colorScheme.primary,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exitSelectionMode,
              ),
              title: Text(
                '${_selectedChats.length} selected',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.archive, color: Colors.white),
                  onPressed: _archiveSelectedChats,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteSelectedChats,
                ),
              ],
            )
          : AppBar(
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              elevation: 0,
              title: Text(
                'Messages',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
                  onPressed: () {
                    // Show more options
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: SearchBarWidget(
              hintText: 'Search chats...',
              controller: _searchController,
            ),
          ),
          // Chat list
          Expanded(
            child: _filteredChats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No chats yet'
                              : 'No chats found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = _filteredChats[index];
                      final isSelected = _selectedChats.contains(chat.id);

                      return ChatTile(
                        name: chat.name,
                        lastMessage: chat.lastMessage,
                        time: chat.time,
                        unreadCount: chat.unreadCount,
                        hasStatus: chat.hasStatus,
                        isSelected: isSelected,
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(chat.id);
                          } else {
                            // Navigate to chat detail
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailPage(
                                  name: chat.name,
                                  isOnline: chat.hasStatus,
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _enterSelectionMode(chat.id);
                          }
                        },
                        onDelete: () => _deleteChat(chat.id),
                        onArchive: () => _archiveChat(chat.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: () {
                // Start new chat
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Start new chat')));
              },
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.edit, color: Colors.white),
            )
          : null,
    );
  }
}

class ChatData {
  final int id;
  final String name;
  final String lastMessage;
  final String time;
  final bool hasStatus;
  final int unreadCount;

  ChatData({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.hasStatus = false,
    this.unreadCount = 0,
  });
}
