CREATE TABLE IF NOT EXISTS songs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  song_name    TEXT NOT NULL DEFAULT '',
  singers      TEXT[] DEFAULT '{}',
  karaoke_link TEXT DEFAULT '',
  position     INTEGER DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE songs ENABLE ROW LEVEL SECURITY;

-- 3. Allow all operations for anonymous users (anon key)
--    Since this is a family app with a shared key, we allow full CRUD
CREATE POLICY "Allow all for anon" ON songs
  FOR ALL
  USING (true)
  WITH CHECK (true);-- ============================================================
--  MIGRATION SCRIPT — Run this instead of supabase-setup.sql
--  if you already have songs data in your database.
--  Safe to run — does NOT delete any existing songs.
-- ============================================================

-- STEP 1: Create the programs table (new)
CREATE TABLE IF NOT EXISTS programs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL DEFAULT 'My Show',
  date        TEXT DEFAULT '',
  status      TEXT NOT NULL DEFAULT 'active',
  created_at  TIMESTAMPTZ DEFAULT now(),
  ended_at    TIMESTAMPTZ
);

ALTER TABLE programs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for anon" ON programs;
CREATE POLICY "Allow all for anon" ON programs
  FOR ALL USING (true) WITH CHECK (true);

-- STEP 2: Create a program record for your existing songs
-- We'll call it "Sparsh" dated June 13th 2026 — change these if needed
INSERT INTO programs (id, name, date, status, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000001',  -- fixed ID so we can reference it below
  'Sparsh',
  'June 13th, 2026',
  'active',
  now()
);

-- STEP 3: Add program_id column to existing songs table
ALTER TABLE songs
  ADD COLUMN IF NOT EXISTS program_id UUID REFERENCES programs(id) ON DELETE CASCADE;

-- STEP 4: Link ALL your existing songs to the Sparsh program above
UPDATE songs
SET program_id = '00000000-0000-0000-0000-000000000001'
WHERE program_id IS NULL;

-- STEP 5: Now make program_id NOT NULL (all rows are filled, safe to do)
ALTER TABLE songs
  ALTER COLUMN program_id SET NOT NULL;

-- STEP 6: Add index for performance
CREATE INDEX IF NOT EXISTS songs_program_id_idx ON songs(program_id);

-- STEP 7: Drop old app_settings table if it exists (no longer needed)
-- Uncomment the line below if you want to clean it up:
-- DROP TABLE IF EXISTS app_settings;

-- ============================================================
--  Done! Your existing songs are now linked to "Sparsh".
--  Verify with:
--    SELECT p.name, COUNT(s.id) as song_count
--    FROM programs p
--    LEFT JOIN songs s ON s.program_id = p.id
--    GROUP BY p.name;
-- ============================================================
ALTER TABLE songs ADD COLUMN IF NOT EXISTS is_new BOOLEAN DEFAULT false;
