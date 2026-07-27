CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE user_role AS ENUM ('user', 'admin');
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE training_goal_type AS ENUM ('weight_loss', 'muscle_gain', 'endurance', 'strength', 'general_fitness');
CREATE TYPE fitness_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE exercise_category AS ENUM ('chest', 'back', 'legs', 'shoulders', 'arms', 'abs');
CREATE TYPE difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE media_type AS ENUM ('photo', 'gif');
CREATE TYPE workout_session_status AS ENUM ('in_progress', 'completed', 'cancelled');
CREATE TYPE meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
CREATE TYPE subscription_plan_code AS ENUM ('free', 'premium');
CREATE TYPE subscription_status AS ENUM ('active', 'trialing', 'past_due', 'cancelled', 'expired');
CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'refunded');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(120),
    photo_url TEXT,
    password_hash TEXT,
    email_verified_at TIMESTAMPTZ,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    last_password_changed_at TIMESTAMPTZ,
    token_version INTEGER NOT NULL DEFAULT 0,
    age INTEGER CHECK (age IS NULL OR age BETWEEN 10 AND 100),
    gender gender_type,
    height_cm NUMERIC(5,2) CHECK (height_cm IS NULL OR height_cm BETWEEN 80 AND 250),
    weight_kg NUMERIC(5,2) CHECK (weight_kg IS NULL OR weight_kg BETWEEN 25 AND 300),
    training_goal training_goal_type,
    role user_role NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash CHAR(64) NOT NULL UNIQUE,
    device_id VARCHAR(120),
    user_agent TEXT,
    ip_address INET,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash CHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notification_device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    device_id VARCHAR(120),
    app_version VARCHAR(40),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    workout_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    workout_reminder_time TIME NOT NULL DEFAULT '09:00',
    payment_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    premium_expiration_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    premium_expiration_days_before INTEGER NOT NULL DEFAULT 3 CHECK (
        premium_expiration_days_before BETWEEN 1 AND 30
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(40) NOT NULL CHECK (
        type IN (
            'workout_reminder',
            'payment_succeeded',
            'payment_failed',
            'premium_expiring',
            'premium_expired',
            'system'
        )
        OR type LIKE 'payment_%'
    ),
    title VARCHAR(160) NOT NULL,
    body TEXT NOT NULL,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'queued' CHECK (
        status IN ('queued', 'sent', 'failed', 'skipped', 'read')
    ),
    fcm_message_id TEXT,
    error_message TEXT,
    sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ai_fitness_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal training_goal_type NOT NULL,
    weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg BETWEEN 25 AND 300),
    height_cm NUMERIC(5,2) NOT NULL CHECK (height_cm BETWEEN 80 AND 250),
    fitness_level fitness_level NOT NULL,
    prompt_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    summary TEXT NOT NULL,
    workout_plan JSONB NOT NULL,
    nutrition_recommendations JSONB NOT NULL,
    safety_notes JSONB NOT NULL DEFAULT '[]'::jsonb,
    raw_ai_response JSONB NOT NULL DEFAULT '{}'::jsonb,
    model VARCHAR(80) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'generated' CHECK (
        status IN ('generated', 'failed')
    ),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(160) NOT NULL,
    media_url TEXT,
    media_type media_type,
    description TEXT NOT NULL,
    category exercise_category NOT NULL,
    muscle_group VARCHAR(120) NOT NULL,
    equipment VARCHAR(160),
    difficulty difficulty_level NOT NULL,
    created_by_admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(160) NOT NULL,
    description TEXT,
    goal training_goal_type,
    is_template BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workout_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
    order_index INTEGER NOT NULL DEFAULT 0,
    target_sets INTEGER NOT NULL CHECK (target_sets > 0),
    target_reps INTEGER CHECK (target_reps IS NULL OR target_reps > 0),
    target_weight_kg NUMERIC(6,2) CHECK (target_weight_kg IS NULL OR target_weight_kg >= 0),
    rest_seconds INTEGER CHECK (rest_seconds IS NULL OR rest_seconds >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (workout_id, exercise_id, order_index)
);

CREATE TABLE workout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,
    status workout_session_status NOT NULL DEFAULT 'in_progress',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workout_session_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
    order_index INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workout_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_exercise_id UUID NOT NULL REFERENCES workout_session_exercises(id) ON DELETE CASCADE,
    set_number INTEGER NOT NULL CHECK (set_number > 0),
    weight_kg NUMERIC(6,2) CHECK (weight_kg IS NULL OR weight_kg >= 0),
    reps INTEGER CHECK (reps IS NULL OR reps >= 0),
    duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    rest_seconds INTEGER CHECK (rest_seconds IS NULL OR rest_seconds >= 0),
    is_completed BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (session_exercise_id, set_number)
);

CREATE TABLE weight_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg BETWEEN 25 AND 300),
    measured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE nutrition_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    meal_type meal_type NOT NULL,
    product_name VARCHAR(180) NOT NULL,
    serving_size VARCHAR(80),
    calories INTEGER NOT NULL CHECK (calories >= 0),
    protein_g NUMERIC(6,2) NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
    fat_g NUMERIC(6,2) NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
    carbs_g NUMERIC(6,2) NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code subscription_plan_code NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    billing_interval VARCHAR(20),
    stripe_price_id VARCHAR(255),
    features JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id) ON DELETE RESTRICT,
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    status subscription_status NOT NULL DEFAULT 'active',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,
    plan subscription_plan_code NOT NULL DEFAULT 'premium',
    stripe_payment_intent_id VARCHAR(255),
    stripe_checkout_session_id VARCHAR(255),
    stripe_checkout_url TEXT,
    amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    status payment_status NOT NULL DEFAULT 'pending',
    provider VARCHAR(40) NOT NULL DEFAULT 'stripe',
    mode VARCHAR(10) NOT NULL DEFAULT 'test',
    description TEXT,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (mode = 'test')
);

CREATE TABLE payment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    old_status payment_status,
    new_status payment_status NOT NULL,
    event_type VARCHAR(80) NOT NULL,
    provider VARCHAR(40) NOT NULL DEFAULT 'stripe',
    mode VARCHAR(10) NOT NULL DEFAULT 'test',
    stripe_event_id VARCHAR(255),
    message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (mode = 'test')
);

CREATE TABLE admin_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(80) NOT NULL,
    entity_type VARCHAR(80) NOT NULL,
    entity_id UUID,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_tokens_token_hash ON email_verification_tokens(token_hash);
CREATE INDEX idx_notification_device_tokens_user_id ON notification_device_tokens(user_id);
CREATE INDEX idx_notification_device_tokens_fcm_token ON notification_device_tokens(fcm_token);
CREATE INDEX idx_notification_device_tokens_active ON notification_device_tokens(user_id, is_active);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, read_at);
CREATE INDEX idx_notifications_type_status ON notifications(type, status);
CREATE INDEX idx_ai_fitness_plans_user_created ON ai_fitness_plans(user_id, created_at DESC);
CREATE INDEX idx_ai_fitness_plans_goal ON ai_fitness_plans(goal);
CREATE INDEX idx_exercises_category ON exercises(category);
CREATE INDEX idx_exercises_difficulty ON exercises(difficulty);
CREATE INDEX idx_workouts_user_id ON workouts(user_id);
CREATE INDEX idx_workout_sessions_user_started ON workout_sessions(user_id, started_at DESC);
CREATE INDEX idx_weight_logs_user_measured ON weight_logs(user_id, measured_at DESC);
CREATE INDEX idx_nutrition_entries_user_date ON nutrition_entries(user_id, entry_date DESC);
CREATE INDEX idx_user_subscriptions_user_status ON user_subscriptions(user_id, status);
CREATE INDEX idx_payments_user_created ON payments(user_id, created_at DESC);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_stripe_checkout_session_id ON payments(stripe_checkout_session_id);
CREATE INDEX idx_payment_history_payment_created ON payment_history(payment_id, created_at DESC);
CREATE INDEX idx_payment_history_user_created ON payment_history(user_id, created_at DESC);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_notification_device_tokens_updated_at
BEFORE UPDATE ON notification_device_tokens
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_notification_preferences_updated_at
BEFORE UPDATE ON notification_preferences
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_notifications_updated_at
BEFORE UPDATE ON notifications
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_ai_fitness_plans_updated_at
BEFORE UPDATE ON ai_fitness_plans
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_exercises_updated_at
BEFORE UPDATE ON exercises
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_workouts_updated_at
BEFORE UPDATE ON workouts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_workout_exercises_updated_at
BEFORE UPDATE ON workout_exercises
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_workout_sessions_updated_at
BEFORE UPDATE ON workout_sessions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_nutrition_entries_updated_at
BEFORE UPDATE ON nutrition_entries
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_subscription_plans_updated_at
BEFORE UPDATE ON subscription_plans
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_subscriptions_updated_at
BEFORE UPDATE ON user_subscriptions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_payments_updated_at
BEFORE UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO subscription_plans (code, name, price_cents, currency, billing_interval, features)
VALUES
    ('free', 'Free', 0, 'USD', NULL, '["basic_exercises", "limited_workouts", "basic_stats"]'::jsonb),
    ('premium', 'Premium', 999, 'USD', 'month', '["unlimited_workouts", "advanced_stats", "full_history", "premium_exercises"]'::jsonb);
