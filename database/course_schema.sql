CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS fittrack_course;
SET search_path TO fittrack_course;

CREATE TYPE fittrack_auth_provider AS ENUM ('email_password', 'google');
CREATE TYPE fittrack_gender AS ENUM ('male', 'female', 'other');
CREATE TYPE fittrack_training_goal AS ENUM ('weight_loss', 'muscle_gain', 'strength', 'endurance', 'general_fitness');
CREATE TYPE fittrack_fitness_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE fittrack_media_type AS ENUM ('photo', 'gif');
CREATE TYPE fittrack_difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE fittrack_meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
CREATE TYPE fittrack_subscription_plan AS ENUM ('free', 'premium');
CREATE TYPE fittrack_subscription_status AS ENUM ('active', 'trialing', 'past_due', 'cancelled', 'expired');
CREATE TYPE fittrack_payment_status AS ENUM ('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'refunded');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    auth_provider fittrack_auth_provider NOT NULL DEFAULT 'email_password',
    password_hash TEXT,
    email_verified_at TIMESTAMPTZ,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    last_password_changed_at TIMESTAMPTZ,
    token_version INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(80) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    description TEXT,
    resource VARCHAR(80) NOT NULL,
    action VARCHAR(40) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (resource, action)
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE trainer_clients (
    trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (trainer_id, client_id),
    CHECK (trainer_id <> client_id),
    CHECK (status IN ('active', 'paused', 'archived'))
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
    goal fittrack_training_goal NOT NULL,
    weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg BETWEEN 25 AND 300),
    height_cm NUMERIC(5,2) NOT NULL CHECK (height_cm BETWEEN 80 AND 250),
    fitness_level fittrack_fitness_level NOT NULL,
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

CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(120) NOT NULL,
    age INTEGER CHECK (age IS NULL OR age BETWEEN 10 AND 100),
    gender fittrack_gender,
    height_cm NUMERIC(5,2) CHECK (height_cm IS NULL OR height_cm BETWEEN 80 AND 250),
    weight_kg NUMERIC(5,2) CHECK (weight_kg IS NULL OR weight_kg BETWEEN 25 AND 300),
    training_goal fittrack_training_goal,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE muscle_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    muscle_group_id UUID NOT NULL REFERENCES muscle_groups(id) ON DELETE RESTRICT,
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(160) NOT NULL,
    media_url TEXT,
    media_type fittrack_media_type,
    description TEXT NOT NULL,
    technique TEXT NOT NULL,
    common_mistakes TEXT,
    equipment VARCHAR(160),
    difficulty fittrack_difficulty_level NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(160) NOT NULL,
    description TEXT,
    training_goal fittrack_training_goal,
    scheduled_for DATE,
    estimated_duration_minutes INTEGER CHECK (
        estimated_duration_minutes IS NULL OR estimated_duration_minutes > 0
    ),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workout_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
    order_index INTEGER NOT NULL DEFAULT 0,
    sets_count INTEGER NOT NULL CHECK (sets_count > 0),
    reps_count INTEGER NOT NULL CHECK (reps_count > 0),
    weight_kg NUMERIC(6,2) CHECK (weight_kg IS NULL OR weight_kg >= 0),
    rest_seconds INTEGER CHECK (rest_seconds IS NULL OR rest_seconds >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (workout_id, order_index)
);

CREATE TABLE progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    progress_date DATE NOT NULL,
    weight_kg NUMERIC(5,2) CHECK (weight_kg IS NULL OR weight_kg BETWEEN 25 AND 300),
    body_fat_percent NUMERIC(5,2) CHECK (
        body_fat_percent IS NULL OR body_fat_percent BETWEEN 0 AND 100
    ),
    total_volume_kg NUMERIC(10,2) CHECK (total_volume_kg IS NULL OR total_volume_kg >= 0),
    workout_duration_minutes INTEGER CHECK (
        workout_duration_minutes IS NULL OR workout_duration_minutes >= 0
    ),
    calories_burned INTEGER CHECK (calories_burned IS NULL OR calories_burned >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_date DATE NOT NULL,
    meal_type fittrack_meal_type NOT NULL,
    name VARCHAR(160) NOT NULL,
    serving_size VARCHAR(80),
    calories INTEGER NOT NULL CHECK (calories >= 0),
    protein_g NUMERIC(6,2) NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
    fat_g NUMERIC(6,2) NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
    carbs_g NUMERIC(6,2) NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan fittrack_subscription_plan NOT NULL DEFAULT 'free',
    status fittrack_subscription_status NOT NULL DEFAULT 'active',
    price_cents INTEGER NOT NULL DEFAULT 0 CHECK (price_cents >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    plan fittrack_subscription_plan NOT NULL DEFAULT 'premium',
    amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    status fittrack_payment_status NOT NULL DEFAULT 'pending',
    provider VARCHAR(40) NOT NULL DEFAULT 'stripe',
    mode VARCHAR(10) NOT NULL DEFAULT 'test',
    stripe_payment_intent_id VARCHAR(255),
    stripe_checkout_session_id VARCHAR(255),
    stripe_checkout_url TEXT,
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
    old_status fittrack_payment_status,
    new_status fittrack_payment_status NOT NULL,
    event_type VARCHAR(80) NOT NULL,
    provider VARCHAR(40) NOT NULL DEFAULT 'stripe',
    mode VARCHAR(10) NOT NULL DEFAULT 'test',
    stripe_event_id VARCHAR(255),
    message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (mode = 'test')
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_roles_code ON roles(code);
CREATE INDEX idx_permissions_code ON permissions(code);
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);
CREATE INDEX idx_trainer_clients_trainer_id ON trainer_clients(trainer_id);
CREATE INDEX idx_trainer_clients_client_id ON trainer_clients(client_id);
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
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_muscle_groups_code ON muscle_groups(code);
CREATE INDEX idx_exercises_muscle_group_id ON exercises(muscle_group_id);
CREATE INDEX idx_workouts_user_id ON workouts(user_id);
CREATE INDEX idx_workout_exercises_workout_id ON workout_exercises(workout_id);
CREATE INDEX idx_workout_exercises_exercise_id ON workout_exercises(exercise_id);
CREATE INDEX idx_progress_user_date ON progress(user_id, progress_date DESC);
CREATE INDEX idx_meals_user_date ON meals(user_id, meal_date DESC);
CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, status);
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

CREATE TRIGGER trg_roles_updated_at
BEFORE UPDATE ON roles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_permissions_updated_at
BEFORE UPDATE ON permissions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
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

CREATE TRIGGER trg_muscle_groups_updated_at
BEFORE UPDATE ON muscle_groups
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

CREATE TRIGGER trg_progress_updated_at
BEFORE UPDATE ON progress
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_meals_updated_at
BEFORE UPDATE ON meals
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_subscriptions_updated_at
BEFORE UPDATE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_payments_updated_at
BEFORE UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO roles (code, name, description)
VALUES
    ('user', 'User', 'Base role for athletes who train, track progress, and pay for Premium'),
    ('trainer', 'Trainer', 'Role for coaches who create programs, add exercises, and review clients'),
    ('admin', 'Admin', 'System administrator with user, exercise, and payment management access')
ON CONFLICT (code) DO NOTHING;

INSERT INTO permissions (code, name, description, resource, action)
VALUES
    ('workouts:complete', 'Complete workouts', 'Allows completing assigned or personal workouts', 'workouts', 'complete'),
    ('exercises:read', 'Read exercises', 'Allows browsing the exercise library', 'exercises', 'read'),
    ('progress:manage', 'Manage progress', 'Allows creating and viewing personal progress records', 'progress', 'manage'),
    ('analytics:read', 'Read analytics dashboard', 'Allows viewing personal workout, weight, calorie and activity analytics', 'analytics', 'read'),
    ('premium:pay', 'Pay for Premium', 'Allows creating Premium checkout sessions and viewing own payments', 'premium', 'pay'),
    ('ai:generate', 'Generate AI fitness plans', 'Allows generating AI workout and nutrition recommendations', 'ai_assistant', 'generate'),
    ('programs:create', 'Create programs', 'Allows trainer workout program creation', 'programs', 'create'),
    ('exercises:create', 'Create exercises', 'Allows adding new exercises to the library', 'exercises', 'create'),
    ('clients:read', 'Read clients', 'Allows trainers to view assigned client profiles', 'clients', 'read'),
    ('users:manage', 'Manage users', 'Allows admins to view users and assign roles', 'users', 'manage'),
    ('exercises:update', 'Update exercises', 'Allows editing and disabling exercises', 'exercises', 'update'),
    ('payments:read', 'Read payments', 'Allows admins to view payment history', 'payments', 'read')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'workouts:complete',
    'exercises:read',
    'progress:manage',
    'analytics:read',
    'premium:pay',
    'ai:generate'
)
WHERE r.code = 'user'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'exercises:read',
    'programs:create',
    'exercises:create',
    'clients:read',
    'analytics:read',
    'ai:generate'
)
WHERE r.code = 'trainer'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'workouts:complete',
    'exercises:read',
    'progress:manage',
    'analytics:read',
    'premium:pay',
    'ai:generate',
    'programs:create',
    'exercises:create',
    'clients:read',
    'users:manage',
    'exercises:update',
    'payments:read'
)
WHERE r.code = 'admin'
ON CONFLICT DO NOTHING;

INSERT INTO muscle_groups (code, name, description)
VALUES
    ('chest', 'Груди', 'Вправи для грудних м''язів'),
    ('back', 'Спина', 'Вправи для найширших м''язів спини та розгиначів'),
    ('legs', 'Ноги', 'Вправи для квадрицепсів, біцепсів стегна та сідниць'),
    ('shoulders', 'Плечі', 'Вправи для дельтоподібних м''язів'),
    ('arms', 'Руки', 'Вправи для біцепса, трицепса та передпліч'),
    ('abs', 'Прес', 'Вправи для м''язів кора та преса');
