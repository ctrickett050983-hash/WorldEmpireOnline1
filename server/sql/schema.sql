CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player','moderator','dev')),
  cash NUMERIC(14,2) NOT NULL DEFAULT 25000,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS cities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  owner_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  treasury NUMERIC(14,2) NOT NULL DEFAULT 100000,
  population INTEGER NOT NULL DEFAULT 50000,
  happiness NUMERIC(5,2) NOT NULL DEFAULT 65,
  safety NUMERIC(5,2) NOT NULL DEFAULT 70,
  infrastructure NUMERIC(5,2) NOT NULL DEFAULT 60,
  business_tax NUMERIC(5,2) NOT NULL DEFAULT 8,
  property_tax NUMERIC(5,2) NOT NULL DEFAULT 4,
  rent_index NUMERIC(8,2) NOT NULL DEFAULT 100,
  demand_index NUMERIC(8,2) NOT NULL DEFAULT 100,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS properties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  city_id UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
  owner_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  tenant_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  kind TEXT NOT NULL CHECK (kind IN ('home','shop','office','warehouse','factory','bank_branch')),
  name TEXT NOT NULL,
  value NUMERIC(14,2) NOT NULL,
  rent NUMERIC(14,2) NOT NULL,
  upkeep NUMERIC(14,2) NOT NULL,
  condition NUMERIC(5,2) NOT NULL DEFAULT 85,
  is_for_sale BOOLEAN NOT NULL DEFAULT true,
  is_for_rent BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS businesses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  city_id UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('retail','restaurant','factory','logistics','bank','real_estate')),
  name TEXT NOT NULL,
  cash NUMERIC(14,2) NOT NULL DEFAULT 10000,
  stock INTEGER NOT NULL DEFAULT 100,
  price NUMERIC(12,2) NOT NULL DEFAULT 20,
  wage NUMERIC(12,2) NOT NULL DEFAULT 80,
  employees INTEGER NOT NULL DEFAULT 1,
  reputation NUMERIC(5,2) NOT NULL DEFAULT 50,
  is_open BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS banks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID UNIQUE NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  reserve_cash NUMERIC(14,2) NOT NULL DEFAULT 50000,
  loan_rate NUMERIC(5,2) NOT NULL DEFAULT 8,
  deposit_rate NUMERIC(5,2) NOT NULL DEFAULT 2,
  frozen_by_dev BOOLEAN NOT NULL DEFAULT false,
  dev_note TEXT
);

CREATE TABLE IF NOT EXISTS loans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bank_id UUID NOT NULL REFERENCES banks(id) ON DELETE CASCADE,
  borrower_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  principal NUMERIC(14,2) NOT NULL,
  balance NUMERIC(14,2) NOT NULL,
  interest_rate NUMERIC(5,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','defaulted','paid')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  offer JSONB NOT NULL,
  request JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  city_id UUID REFERENCES cities(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS economy_ticks (
  id BIGSERIAL PRIMARY KEY,
  ticked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  summary JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city_id);
CREATE INDEX IF NOT EXISTS idx_businesses_city ON businesses(city_id);
CREATE INDEX IF NOT EXISTS idx_chat_city_created ON chat_messages(city_id, created_at DESC);
