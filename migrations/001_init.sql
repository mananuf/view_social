-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table with profile and authentication fields
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for users table
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone_number ON users(phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX idx_users_created_at ON users(created_at);

-- Constraints for users table
ALTER TABLE users ADD CONSTRAINT chk_username_length CHECK (LENGTH(username) >= 3);
ALTER TABLE users ADD CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
ALTER TABLE users ADD CONSTRAINT chk_phone_format CHECK (phone_number IS NULL OR phone_number ~* '^\+?[1-9]\d{1,14}$');

-- Posts table with content and engagement fields
CREATE TYPE post_content_type AS ENUM ('text', 'image', 'video', 'mixed');
CREATE TYPE post_visibility AS ENUM ('public', 'followers', 'private');

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type post_content_type NOT NULL,
    text_content TEXT,
    media_attachments JSONB DEFAULT '[]'::jsonb,
    is_reel BOOLEAN DEFAULT FALSE,
    visibility post_visibility DEFAULT 'public',
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    reshare_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comments table with threading support
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Follows table for user relationships
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- Post likes table for engagement tracking
CREATE TABLE post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- Comment likes table for engagement tracking
CREATE TABLE comment_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(comment_id, user_id)
);

-- Indexes for posts table
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_visibility ON posts(visibility);
CREATE INDEX idx_posts_is_reel ON posts(is_reel);
CREATE INDEX idx_posts_content_type ON posts(content_type);

-- Indexes for comments table
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_comment_id) WHERE parent_comment_id IS NOT NULL;
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);

-- Indexes for follows table
CREATE INDEX idx_follows_follower_id ON follows(follower_id);
CREATE INDEX idx_follows_following_id ON follows(following_id);
CREATE INDEX idx_follows_created_at ON follows(created_at);

-- Indexes for post_likes table
CREATE INDEX idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);
CREATE INDEX idx_post_likes_created_at ON post_likes(created_at);

-- Indexes for comment_likes table
CREATE INDEX idx_comment_likes_comment_id ON comment_likes(comment_id);
CREATE INDEX idx_comment_likes_user_id ON comment_likes(user_id);

-- Materialized view for feed optimization
CREATE MATERIALIZED VIEW user_feed_cache AS
SELECT 
    f.follower_id as user_id,
    p.id as post_id,
    p.user_id as post_author_id,
    p.content_type,
    p.text_content,
    p.media_attachments,
    p.is_reel,
    p.visibility,
    p.like_count,
    p.comment_count,
    p.reshare_count,
    p.created_at,
    u.username as author_username,
    u.display_name as author_display_name,
    u.avatar_url as author_avatar_url,
    u.is_verified as author_is_verified
FROM follows f
JOIN posts p ON f.following_id = p.user_id
JOIN users u ON p.user_id = u.id
WHERE p.visibility IN ('public', 'followers')
ORDER BY p.created_at DESC;

-- Index for materialized view
CREATE INDEX idx_user_feed_cache_user_id ON user_feed_cache(user_id);
CREATE INDEX idx_user_feed_cache_created_at ON user_feed_cache(created_at DESC);
CREATE INDEX idx_user_feed_cache_is_reel ON user_feed_cache(is_reel);

-- Constraints for posts table
ALTER TABLE posts ADD CONSTRAINT chk_text_or_media CHECK (
    text_content IS NOT NULL OR jsonb_array_length(media_attachments) > 0
);
ALTER TABLE posts ADD CONSTRAINT chk_reel_video_only CHECK (
    NOT is_reel OR content_type IN ('video', 'mixed')
);

-- Constraints for follows table
ALTER TABLE follows ADD CONSTRAINT chk_no_self_follow CHECK (follower_id != following_id);
-- Conversations table for message threads
CREATE TYPE conversation_type AS ENUM ('direct', 'group');

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_type conversation_type DEFAULT 'direct',
    title VARCHAR(255),
    description TEXT,
    avatar_url TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Conversation participants table
CREATE TABLE conversation_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE,
    is_admin BOOLEAN DEFAULT FALSE,
    UNIQUE(conversation_id, user_id)
);

-- Messages table with different message types
CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'audio', 'payment', 'system');

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
    message_type message_type NOT NULL,
    content TEXT,
    media_url TEXT,
    payment_data JSONB,
    reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Message reads table for read receipts
CREATE TABLE message_reads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- Indexes for conversations table
CREATE INDEX idx_conversations_created_by ON conversations(created_by);
CREATE INDEX idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at DESC);
CREATE INDEX idx_conversations_type ON conversations(conversation_type);

-- Indexes for conversation_participants table
CREATE INDEX idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX idx_conversation_participants_joined_at ON conversation_participants(joined_at);
CREATE INDEX idx_conversation_participants_active ON conversation_participants(conversation_id, user_id) WHERE left_at IS NULL;

-- Indexes for messages table
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_messages_message_type ON messages(message_type);
CREATE INDEX idx_messages_reply_to_id ON messages(reply_to_id) WHERE reply_to_id IS NOT NULL;

-- Indexes for message_reads table
CREATE INDEX idx_message_reads_message_id ON message_reads(message_id);
CREATE INDEX idx_message_reads_user_id ON message_reads(user_id);
CREATE INDEX idx_message_reads_read_at ON message_reads(read_at);

-- Constraints for messages table
ALTER TABLE messages ADD CONSTRAINT chk_message_content CHECK (
    CASE 
        WHEN message_type = 'text' THEN content IS NOT NULL
        WHEN message_type IN ('image', 'video', 'audio') THEN media_url IS NOT NULL
        WHEN message_type = 'payment' THEN payment_data IS NOT NULL
        WHEN message_type = 'system' THEN content IS NOT NULL
        ELSE TRUE
    END
);

-- Constraints for conversation_participants table
ALTER TABLE conversation_participants ADD CONSTRAINT chk_valid_participation CHECK (
    left_at IS NULL OR left_at >= joined_at
);
-- Wallets table with balance and security fields
CREATE TYPE wallet_status AS ENUM ('active', 'suspended', 'locked');

CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'NGN',
    status wallet_status DEFAULT 'active',
    pin_hash VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transactions table with status tracking
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed', 'cancelled');
CREATE TYPE transaction_type AS ENUM ('transfer', 'deposit', 'withdrawal', 'refund');

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
    receiver_wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'NGN',
    transaction_type transaction_type NOT NULL,
    status transaction_status DEFAULT 'pending',
    description TEXT,
    reference VARCHAR(100) UNIQUE,
    message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for wallets table
CREATE INDEX idx_wallets_user_id ON wallets(user_id);
CREATE INDEX idx_wallets_status ON wallets(status);
CREATE INDEX idx_wallets_created_at ON wallets(created_at);

-- Indexes for transactions table
CREATE INDEX idx_transactions_sender_wallet_id ON transactions(sender_wallet_id);
CREATE INDEX idx_transactions_receiver_wallet_id ON transactions(receiver_wallet_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX idx_transactions_reference ON transactions(reference);
CREATE INDEX idx_transactions_message_id ON transactions(message_id) WHERE message_id IS NOT NULL;
CREATE INDEX idx_transactions_type ON transactions(transaction_type);

-- Constraints for wallets table
ALTER TABLE wallets ADD CONSTRAINT chk_balance_non_negative CHECK (balance >= 0);
ALTER TABLE wallets ADD CONSTRAINT chk_currency_format CHECK (LENGTH(currency) = 3);

-- Constraints for transactions table
ALTER TABLE transactions ADD CONSTRAINT chk_amount_positive CHECK (amount > 0);
ALTER TABLE transactions ADD CONSTRAINT chk_currency_format_tx CHECK (LENGTH(currency) = 3);
ALTER TABLE transactions ADD CONSTRAINT chk_different_wallets CHECK (
    sender_wallet_id IS NULL OR receiver_wallet_id IS NULL OR sender_wallet_id != receiver_wallet_id
);
ALTER TABLE transactions ADD CONSTRAINT chk_completed_at_valid CHECK (
    (status = 'completed' AND completed_at IS NOT NULL) OR 
    (status != 'completed' AND completed_at IS NULL)
);

-- Database triggers for balance updates
CREATE OR REPLACE FUNCTION update_wallet_balances()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process completed transactions
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        -- Update sender wallet (decrease balance)
        IF NEW.sender_wallet_id IS NOT NULL THEN
            UPDATE wallets 
            SET balance = balance - NEW.amount,
                updated_at = NOW()
            WHERE id = NEW.sender_wallet_id;
        END IF;
        
        -- Update receiver wallet (increase balance)
        IF NEW.receiver_wallet_id IS NOT NULL THEN
            UPDATE wallets 
            SET balance = balance + NEW.amount,
                updated_at = NOW()
            WHERE id = NEW.receiver_wallet_id;
        END IF;
        
        -- Set completed_at timestamp
        NEW.completed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update wallet balances when transaction is completed
CREATE TRIGGER trigger_update_wallet_balances
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_wallet_balances();

-- Function to validate sufficient funds before transaction
CREATE OR REPLACE FUNCTION validate_sufficient_funds()
RETURNS TRIGGER AS $$
DECLARE
    sender_balance DECIMAL(15,2);
BEGIN
    -- Only check for pending transactions with sender wallet
    IF NEW.status = 'pending' AND NEW.sender_wallet_id IS NOT NULL THEN
        SELECT balance INTO sender_balance 
        FROM wallets 
        WHERE id = NEW.sender_wallet_id;
        
        IF sender_balance < NEW.amount THEN
            RAISE EXCEPTION 'Insufficient funds: wallet balance %.2f, required %.2f', 
                sender_balance, NEW.amount;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to validate sufficient funds before creating transaction
CREATE TRIGGER trigger_validate_sufficient_funds
    BEFORE INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION validate_sufficient_funds();
-- Notifications table for push notifications
CREATE TYPE notification_type AS ENUM (
    'message', 'like', 'comment', 'follow', 'payment_received', 
    'payment_sent', 'mention', 'system'
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- Contacts table for phone contact sync
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20),
    display_name VARCHAR(100),
    is_favorite BOOLEAN DEFAULT FALSE,
    is_blocked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Device tokens table for push notifications
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL, -- 'ios', 'android', 'web'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- Indexes for notifications table
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- Indexes for contacts table
CREATE INDEX idx_contacts_user_id ON contacts(user_id);
CREATE INDEX idx_contacts_contact_user_id ON contacts(contact_user_id) WHERE contact_user_id IS NOT NULL;
CREATE INDEX idx_contacts_phone_number ON contacts(phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX idx_contacts_is_favorite ON contacts(is_favorite) WHERE is_favorite = TRUE;
CREATE INDEX idx_contacts_is_blocked ON contacts(is_blocked) WHERE is_blocked = TRUE;

-- Indexes for device_tokens table
CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_platform ON device_tokens(platform);
CREATE INDEX idx_device_tokens_is_active ON device_tokens(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_device_tokens_token ON device_tokens(token);

-- Constraints for contacts table
ALTER TABLE contacts ADD CONSTRAINT chk_contact_info CHECK (
    contact_user_id IS NOT NULL OR phone_number IS NOT NULL
);
ALTER TABLE contacts ADD CONSTRAINT chk_no_self_contact CHECK (
    user_id != contact_user_id OR contact_user_id IS NULL
);

-- Constraints for device_tokens table
ALTER TABLE device_tokens ADD CONSTRAINT chk_platform_valid CHECK (
    platform IN ('ios', 'android', 'web')
);

-- Function to automatically mark notifications as read
CREATE OR REPLACE FUNCTION update_notification_read_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
        NEW.read_at = NOW();
    ELSIF NEW.is_read = FALSE THEN
        NEW.read_at = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update read_at timestamp when notification is marked as read
CREATE TRIGGER trigger_update_notification_read_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_notification_read_at();