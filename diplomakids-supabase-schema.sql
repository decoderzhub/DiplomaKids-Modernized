-- DiplomaKids Database Schema for Supabase
-- Educational Savings Social Platform

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE contribution_type AS ENUM ('one_time', 'recurring', 'birthday', 'holiday', 'milestone');
CREATE TYPE achievement_category AS ENUM ('academic', 'sports', 'arts', 'community', 'financial', 'other');
CREATE TYPE notification_type AS ENUM ('contribution', 'milestone', 'achievement', 'message', 'system');
CREATE TYPE privacy_level AS ENUM ('public', 'family', 'private');

-- Families table (main account holders)
CREATE TABLE families (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    family_name VARCHAR(100) NOT NULL,
    profile_photo_url TEXT,
    cover_photo_url TEXT,
    bio TEXT,
    location JSONB,
    social_links JSONB,
    stripe_customer_id VARCHAR(255),
    stripe_connect_account_id VARCHAR(255),
    plan_529_provider VARCHAR(100),
    plan_529_account_number VARCHAR(100),
    settings JSONB DEFAULT '{}',
    onboarding_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Children profiles
CREATE TABLE children (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),
    nickname VARCHAR(50),
    date_of_birth DATE NOT NULL,
    grade_level VARCHAR(20),
    school_name VARCHAR(200),
    interests TEXT[],
    college_goals TEXT,
    profile_photo_url TEXT,
    bio TEXT,
    savings_goal DECIMAL(12, 2),
    current_savings DECIMAL(12, 2) DEFAULT 0,
    target_college_year INTEGER,
    privacy_settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Contributions table
CREATE TABLE contributions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE,
    contributor_family_id UUID REFERENCES families(id),
    contributor_name VARCHAR(200),
    contributor_email VARCHAR(255),
    amount DECIMAL(10, 2) NOT NULL,
    type contribution_type NOT NULL,
    message TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    thank_you_sent BOOLEAN DEFAULT FALSE,
    thank_you_video_url TEXT,
    stripe_payment_intent_id VARCHAR(255),
    stripe_charge_id VARCHAR(255),
    tax_receipt_url TEXT,
    recurring_subscription_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Milestones/Posts table
CREATE TABLE milestones (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    media_urls TEXT[],
    media_types TEXT[],
    category achievement_category,
    grade_received VARCHAR(10),
    privacy privacy_level DEFAULT 'family',
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Achievements/Badges table
CREATE TABLE achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE,
    badge_id VARCHAR(100) NOT NULL,
    badge_name VARCHAR(200) NOT NULL,
    badge_description TEXT,
    badge_icon_url TEXT,
    category achievement_category,
    points INTEGER DEFAULT 0,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Savings Goals table
CREATE TABLE goals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE,
    goal_name VARCHAR(200) NOT NULL,
    target_amount DECIMAL(12, 2) NOT NULL,
    current_amount DECIMAL(12, 2) DEFAULT 0,
    target_date DATE,
    description TEXT,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Social interactions table
CREATE TABLE interactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    milestone_id UUID REFERENCES milestones(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    interaction_type VARCHAR(20) NOT NULL, -- 'like', 'comment', 'share'
    comment_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documents table (tax forms, statements, etc.)
CREATE TABLE documents (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    child_id UUID REFERENCES children(id),
    document_type VARCHAR(50) NOT NULL,
    document_name VARCHAR(200) NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    tax_year INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gift Registry table
CREATE TABLE gift_registries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL, -- 'birthday', 'holiday', 'graduation', etc.
    event_date DATE,
    target_amount DECIMAL(10, 2),
    current_amount DECIMAL(10, 2) DEFAULT 0,
    message TEXT,
    qr_code_url TEXT,
    share_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Challenges table (for gamification)
CREATE TABLE challenges (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    target_amount DECIMAL(10, 2),
    prize_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Challenge Participants table
CREATE TABLE challenge_participants (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    child_id UUID REFERENCES children(id),
    current_amount DECIMAL(10, 2) DEFAULT 0,
    rank INTEGER,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(challenge_id, family_id)
);

-- Financial Literacy Progress table
CREATE TABLE literacy_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    child_id UUID REFERENCES children(id) ON DELETE CASCADE,
    module_id VARCHAR(100) NOT NULL,
    module_name VARCHAR(200),
    completion_percentage INTEGER DEFAULT 0,
    score INTEGER,
    badges_earned TEXT[],
    last_accessed TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Family Connections (social graph)
CREATE TABLE connections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    connected_family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    connection_type VARCHAR(50), -- 'family', 'friend', 'following'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(family_id, connected_family_id)
);

-- Create indexes for better performance
CREATE INDEX idx_children_family ON children(family_id);
CREATE INDEX idx_contributions_child ON contributions(child_id);
CREATE INDEX idx_contributions_contributor ON contributions(contributor_family_id);
CREATE INDEX idx_milestones_child ON milestones(child_id);
CREATE INDEX idx_milestones_family ON milestones(family_id);
CREATE INDEX idx_milestones_created ON milestones(created_at DESC);
CREATE INDEX idx_achievements_child ON achievements(child_id);
CREATE INDEX idx_notifications_family ON notifications(family_id, is_read);
CREATE INDEX idx_documents_family ON documents(family_id);
CREATE INDEX idx_interactions_milestone ON interactions(milestone_id);

-- Row Level Security (RLS) Policies
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (example for families table)
CREATE POLICY "Users can view their own family data" ON families
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update their own family data" ON families
    FOR UPDATE USING (auth.uid()::text = id::text);

-- Create functions for complex operations
CREATE OR REPLACE FUNCTION update_child_savings()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE children
    SET current_savings = (
        SELECT COALESCE(SUM(amount), 0)
        FROM contributions
        WHERE child_id = NEW.child_id
    )
    WHERE id = NEW.child_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update savings automatically
CREATE TRIGGER update_savings_on_contribution
AFTER INSERT ON contributions
FOR EACH ROW
EXECUTE FUNCTION update_child_savings();

-- Function to calculate savings progress
CREATE OR REPLACE FUNCTION get_savings_progress(child_uuid UUID)
RETURNS TABLE(
    current_savings DECIMAL,
    savings_goal DECIMAL,
    progress_percentage INTEGER,
    projected_completion DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.current_savings,
        c.savings_goal,
        CASE 
            WHEN c.savings_goal > 0 THEN 
                CAST((c.current_savings / c.savings_goal * 100) AS INTEGER)
            ELSE 0
        END as progress_percentage,
        CASE 
            WHEN c.savings_goal > 0 AND c.current_savings > 0 THEN
                CURRENT_DATE + INTERVAL '1 day' * 
                    CAST((c.savings_goal - c.current_savings) / 
                    (c.current_savings / EXTRACT(DAY FROM NOW() - c.created_at)) AS INTEGER)
            ELSE NULL
        END as projected_completion
    FROM children c
    WHERE c.id = child_uuid;
END;
$$ LANGUAGE plpgsql;
