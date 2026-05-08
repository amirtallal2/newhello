ALTER TABLE live_rooms
  ADD COLUMN IF NOT EXISTS pk_status VARCHAR(20) NOT NULL DEFAULT 'idle' AFTER pk_battle_duration,
  ADD COLUMN IF NOT EXISTS active_pk_invite_id INT UNSIGNED NULL AFTER pk_status,
  ADD COLUMN IF NOT EXISTS pk_guest_user_id INT UNSIGNED NULL AFTER active_pk_invite_id,
  ADD COLUMN IF NOT EXISTS pk_guest_name VARCHAR(190) NULL AFTER pk_guest_user_id,
  ADD COLUMN IF NOT EXISTS pk_started_at DATETIME NULL AFTER pk_guest_name,
  ADD COLUMN IF NOT EXISTS pk_ends_at DATETIME NULL AFTER pk_started_at;

ALTER TABLE live_pk_invites
  MODIFY status VARCHAR(20) NOT NULL DEFAULT 'sent';

UPDATE live_rooms
SET pk_status = 'idle'
WHERE pk_status IS NULL OR pk_status = '';
