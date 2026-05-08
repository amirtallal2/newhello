ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS attachment_path VARCHAR(255) NULL AFTER message_type,
    ADD COLUMN IF NOT EXISTS attachment_mime_type VARCHAR(120) NULL AFTER attachment_path,
    ADD COLUMN IF NOT EXISTS attachment_name VARCHAR(190) NULL AFTER attachment_mime_type;
