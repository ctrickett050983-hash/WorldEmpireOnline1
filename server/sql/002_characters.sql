CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS characters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  first_name text NOT NULL CHECK (char_length(first_name) BETWEEN 2 AND 32),
  last_name text NOT NULL CHECK (char_length(last_name) BETWEEN 2 AND 32),
  date_of_birth date,
  nationality text NOT NULL DEFAULT 'Unknown',
  gender text NOT NULL DEFAULT 'Unspecified',
  starting_city_id uuid REFERENCES cities(id) ON DELETE SET NULL,
  hair text NOT NULL DEFAULT 'Short',
  beard text NOT NULL DEFAULT 'None',
  eyes text NOT NULL DEFAULT 'Brown',
  skin_tone text NOT NULL DEFAULT 'Medium',
  clothes text NOT NULL DEFAULT 'Casual',
  shoes text NOT NULL DEFAULT 'Trainers',
  position_x numeric NOT NULL DEFAULT 0,
  position_y numeric NOT NULL DEFAULT 0,
  position_z numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_characters_user_id ON characters(user_id);
CREATE INDEX IF NOT EXISTS idx_characters_starting_city_id ON characters(starting_city_id);
