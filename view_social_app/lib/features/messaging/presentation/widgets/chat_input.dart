import 'package:flutter/material.dart';
import '../../../../core/theme/responsive.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final VoidCallback onSendImage;
  final VoidCallback onSendPayment;
  final Function(bool) onTypingChanged;
  
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onSendPayment,
    required this.onTypingChanged,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isTyping = false;
  bool _showAttachments = false;
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
  
  void _onTextChanged() {
    final isTyping = widget.controller.text.trim().isNotEmpty;
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      widget.onTypingChanged(isTyping);
    }
  }
  
  void _sendMessage() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
    }
  }
  
  void _toggleAttachments() {
    setState(() {
      _showAttachments = !_showAttachments;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Attachment Options
        if (_showAttachments) _buildAttachmentOptions(context, theme),
        
        // Input Row
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isMobile(context) ? 8 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Attachment Button
                IconButton(
                  icon: Icon(
                    _showAttachments ? Icons.close : Icons.add,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: _toggleAttachments,
                ),
                
                // Text Input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: Responsive.getFontSize(context, 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send Button
                Container(
                  decoration: BoxDecoration(
                    color: _isTyping 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isTyping ? Icons.send : Icons.mic,
                      color: _isTyping 
                          ? Colors.white 
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: _isTyping 
                        ? _sendMessage 
                        : () {
                            // TODO: Implement voice recording
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Voice messages coming soon!'),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAttachmentOptions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            context,
            theme,
            Icons.photo_library,
            'Gallery',
            widget.onSendImage,
          ),
          _buildAttachmentOption(
            context,
            theme,
            Icons.camera_alt,
            'Camera',
            () {
              // TODO: Implement camera capture
              widget.onSendImage();
            },
          ),
          _buildAttachmentOption(
            context,
            theme,
            Icons.payment,
            'Payment',
            widget.onSendPayment,
          ),
          _buildAttachmentOption(
            context,
            theme,
            Icons.location_on,
            'Location',
            () {
              // TODO: Implement location sharing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location sharing coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttachmentOption(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        _toggleAttachments(); // Close attachments
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: Responsive.getFontSize(context, 12),
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}