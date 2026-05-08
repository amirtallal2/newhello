-- HalloParty profile economy update
-- Date: 2026-05-07
-- Purpose: add the initial aristocracy store item for existing MySQL databases.

INSERT INTO store_items (
    category_key,
    name,
    preview_asset_path,
    dialog_icon_asset_path,
    dialog_preview_asset_path,
    price_3_days,
    price_7_days,
    price_15_days,
    price_30_days,
    discount_3_days,
    discount_7_days,
    discount_15_days,
    discount_30_days,
    currency_type,
    status,
    display_order,
    created_at,
    updated_at
)
SELECT
    'aristocracy',
    'شارة الاستقراطية',
    'assets/images/profile_store_aristocracy_icon.png',
    'assets/images/profile_store_aristocracy_icon.png',
    'assets/images/profile_store_aristocracy_icon.png',
    120,
    240,
    450,
    720,
    '10% Off',
    '22% Off',
    '27% Off',
    '27% Off',
    'coins',
    'active',
    COALESCE((SELECT MAX(existing_items.display_order) FROM store_items AS existing_items), 0) + 1,
    UTC_TIMESTAMP(),
    UTC_TIMESTAMP()
WHERE NOT EXISTS (
    SELECT 1
    FROM store_items
    WHERE category_key = 'aristocracy'
      AND name = 'شارة الاستقراطية'
);
