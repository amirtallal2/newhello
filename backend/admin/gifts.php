<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/GiftService.php';

admin_require_auth();
$pdo = admin_pdo();
$giftService = new GiftService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$flash = null;
$error = null;

function gift_admin_upload_path(string $field, string $kind, string $fallback = ''): string
{
    if (!isset($_FILES[$field]) || !is_array($_FILES[$field])) {
        return trim($fallback);
    }

    $file = $_FILES[$field];
    $error = (int) ($file['error'] ?? UPLOAD_ERR_NO_FILE);

    if ($error === UPLOAD_ERR_NO_FILE) {
        return trim($fallback);
    }

    if ($error !== UPLOAD_ERR_OK) {
        throw new ApiException('فشل رفع الملف: ' . $field, 422);
    }

    $originalName = basename((string) ($file['name'] ?? 'gift-file'));
    $extension = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
    $allowed = match ($kind) {
        'sound' => ['mp3', 'mpeg', 'wav', 'ogg'],
        'animation' => ['gif', 'webp', 'png', 'jpg', 'jpeg'],
        default => ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    };

    if (!in_array($extension, $allowed, true)) {
        throw new ApiException('نوع الملف غير مدعوم في ' . $field, 422);
    }

    $tmpName = (string) ($file['tmp_name'] ?? '');
    if ($tmpName === '' || !is_uploaded_file($tmpName)) {
        throw new ApiException('ملف غير صالح في ' . $field, 422);
    }

    $directory = dirname(__DIR__) . '/storage/gifts';
    if (!is_dir($directory) && !mkdir($directory, 0775, true) && !is_dir($directory)) {
        throw new ApiException('تعذر إنشاء مجلد الهدايا.', 500);
    }

    $safeName = preg_replace('/[^a-zA-Z0-9._-]+/', '-', pathinfo($originalName, PATHINFO_FILENAME)) ?: 'gift';
    $filename = $kind . '-' . $safeName . '-' . bin2hex(random_bytes(6)) . '.' . $extension;
    $destination = $directory . '/' . $filename;

    if (!move_uploaded_file($tmpName, $destination)) {
        throw new ApiException('تعذر حفظ ملف الهدية.', 500);
    }

    return '/storage/gifts/' . $filename;
}

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? 'update');

        if ($action === 'save_monetization') {
            $giftService->updateGiftMonetizationSettings((float) ($_POST['commission_percent'] ?? 50));
            $flash = 'تم تحديث نسبة عمولة الهدايا.';
        } elseif ($action === 'delete') {
            $giftService->hideGiftAdmin((int) ($_POST['gift_id'] ?? 0));
            $flash = 'تم حذف الهدية من التطبيق مع الحفاظ على سجل المعاملات.';
        } else {
            $assetPath = gift_admin_upload_path(
                'asset_file',
                'image',
                trim((string) ($_POST['asset_path'] ?? ''))
            );
            $animationPath = gift_admin_upload_path(
                'animation_file',
                'animation',
                trim((string) ($_POST['animation_path'] ?? ''))
            );
            $soundPath = gift_admin_upload_path(
                'sound_file',
                'sound',
                trim((string) ($_POST['sound_path'] ?? ''))
            );

            $payload = [
                'name' => trim((string) ($_POST['name'] ?? '')),
                'category' => trim((string) ($_POST['category'] ?? '')),
                'asset_path' => $assetPath,
                'animation_path' => $animationPath,
                'sound_path' => $soundPath,
                'is_animated' => isset($_POST['is_animated']),
                'effect_duration_ms' => (int) ($_POST['effect_duration_ms'] ?? 1800),
                'price_coins' => (int) ($_POST['price_coins'] ?? 0),
                'display_order' => (int) ($_POST['display_order'] ?? 0),
                'status' => (string) ($_POST['status'] ?? 'active'),
            ];

            if ($action === 'create') {
                $giftService->createGiftAdmin(
                    $payload['name'],
                    $payload['category'],
                    $payload['asset_path'],
                    $payload['animation_path'],
                    $payload['sound_path'],
                    $payload['is_animated'],
                    $payload['effect_duration_ms'],
                    $payload['price_coins'],
                    $payload['display_order'],
                    $payload['status']
                );
                $flash = 'تمت إضافة الهدية.';
            } else {
                $giftService->updateGiftAdmin(
                    (int) ($_POST['gift_id'] ?? 0),
                    $payload['name'],
                    $payload['category'],
                    $payload['asset_path'],
                    $payload['animation_path'],
                    $payload['sound_path'],
                    $payload['is_animated'],
                    $payload['effect_duration_ms'],
                    $payload['price_coins'],
                    $payload['display_order'],
                    $payload['status']
                );
                $flash = 'تم تحديث الهدية.';
            }
        }
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$gifts = $giftService->adminListGifts($search);
$monetizationSettings = $giftService->adminGiftMonetizationSettings();
$giftStats = $giftService->adminGiftStats();

admin_render_header('إدارة الهدايا', 'gifts');
?>
<?php if ($flash !== null): ?>
    <section class="panel">
        <div class="pill pill-success"><?= htmlspecialchars($flash) ?></div>
    </section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel">
        <div class="pill pill-danger"><?= htmlspecialchars($error) ?></div>
    </section>
<?php endif; ?>

<section class="panel">
    <div class="panel-title">أرباح الهدايا وعمولة المنصة</div>
    <p class="panel-copy">عند إرسال هدية يتم خصم الكوينز من المرسل، تحويل عمولة المنصة حسب النسبة، والباقي يضاف كألماس في محفظة مستقبل الهدية.</p>
    <form method="post" class="form-grid gift-create-grid">
        <input type="hidden" name="action" value="save_monetization">
        <label>
            نسبة عمولتك من الهدايا %
            <input type="number" min="0" max="95" step="0.01" name="commission_percent" value="<?= htmlspecialchars((string) $monetizationSettings['commission_percent']) ?>" required>
        </label>
        <label>
            ربح المستخدم
            <input type="text" value="الباقي يضاف كألماس للمستقبل" disabled>
        </label>
        <div class="metric-card">
            <div class="metric-label">إجمالي أرباح المستخدمين</div>
            <div class="metric-copy"><?= (int) ($giftStats['creator_earnings_diamonds'] ?? 0) ?> Diamond</div>
        </div>
        <div class="metric-card">
            <div class="metric-label">إجمالي عمولة المنصة</div>
            <div class="metric-copy"><?= (int) ($giftStats['platform_fees_coins'] ?? 0) ?> Coin</div>
        </div>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">حفظ العمولة</button>
        </div>
    </form>
</section>

<section class="panel">
    <div class="panel-title">إضافة هدية جديدة</div>
    <p class="panel-copy">الصورة الأساسية تظهر في كتالوج الهدايا. ملف الحركة يمكن أن يكون GIF/WebP/PNG، والصوت MP3/WAV/OGG.</p>
    <form method="post" enctype="multipart/form-data" class="form-grid gift-create-grid">
        <input type="hidden" name="action" value="create">
        <label>
            اسم الهدية
            <input type="text" name="name" placeholder="مثال: وردة ذهبية" required>
        </label>
        <label>
            الفئة
            <input type="text" name="category" placeholder="VIP / متحرك / الهداية عادية" required>
        </label>
        <label>
            السعر بالعملات
            <input type="number" min="1" name="price_coins" value="10" required>
        </label>
        <label>
            الترتيب
            <input type="number" min="0" name="display_order" value="0">
        </label>
        <label class="span-2">
            مسار الصورة أو ارفع ملف
            <input type="text" name="asset_path" placeholder="assets/images/room_gift_1.png أو /storage/gifts/...">
            <input type="file" name="asset_file" accept="image/png,image/jpeg,image/webp,image/gif">
        </label>
        <label class="span-2">
            مسار الحركة أو ارفع ملف
            <input type="text" name="animation_path" placeholder="/storage/gifts/effect.gif">
            <input type="file" name="animation_file" accept="image/png,image/jpeg,image/webp,image/gif">
        </label>
        <label class="span-2">
            صوت الهدية MP3
            <input type="text" name="sound_path" placeholder="/storage/gifts/gift.mp3">
            <input type="file" name="sound_file" accept="audio/mpeg,audio/mp3,audio/wav,audio/ogg">
        </label>
        <label>
            مدة التأثير ms
            <input type="number" min="600" max="8000" name="effect_duration_ms" value="1800">
        </label>
        <label>
            الحالة
            <select name="status">
                <option value="active">نشطة</option>
                <option value="hidden">مخفية</option>
            </select>
        </label>
        <label class="checkbox-card">
            <input type="checkbox" name="is_animated" value="1">
            هدية متحركة
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">إضافة الهدية</button>
        </div>
    </form>
</section>

<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم الهدية أو الفئة أو مسار الملف">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>الصورة</th>
                <th>الحركة</th>
                <th>الصوت</th>
                <th>بيانات الهدية</th>
                <th>السعر/المدة</th>
                <th>الحالة</th>
                <th>الإجراءات</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($gifts as $gift): ?>
            <?php $formId = 'gift-form-' . (int) $gift['id']; ?>
            <tr>
                <td>
                    <form id="<?= htmlspecialchars($formId) ?>" method="post" enctype="multipart/form-data"></form>
                    #<?= (int) $gift['id'] ?>
                    <input form="<?= htmlspecialchars($formId) ?>" type="hidden" name="gift_id" value="<?= (int) $gift['id'] ?>">
                </td>
                <td>
                    <div class="media-stack">
                        <?= admin_render_media_preview((string) $gift['asset_path'], (string) $gift['name']) ?>
                        <input form="<?= htmlspecialchars($formId) ?>" type="text" name="asset_path" value="<?= htmlspecialchars((string) $gift['asset_path']) ?>" placeholder="مسار الصورة">
                        <input form="<?= htmlspecialchars($formId) ?>" type="file" name="asset_file" accept="image/png,image/jpeg,image/webp,image/gif">
                    </div>
                </td>
                <td>
                    <div class="media-stack">
                        <?= admin_render_media_preview((string) ($gift['animation_path'] ?? ''), (string) $gift['name']) ?>
                        <input form="<?= htmlspecialchars($formId) ?>" type="text" name="animation_path" value="<?= htmlspecialchars((string) ($gift['animation_path'] ?? '')) ?>" placeholder="مسار الحركة">
                        <input form="<?= htmlspecialchars($formId) ?>" type="file" name="animation_file" accept="image/png,image/jpeg,image/webp,image/gif">
                    </div>
                </td>
                <td>
                    <div class="media-stack">
                        <?= admin_render_audio_preview((string) ($gift['sound_path'] ?? '')) ?>
                        <input form="<?= htmlspecialchars($formId) ?>" type="text" name="sound_path" value="<?= htmlspecialchars((string) ($gift['sound_path'] ?? '')) ?>" placeholder="مسار mp3">
                        <input form="<?= htmlspecialchars($formId) ?>" type="file" name="sound_file" accept="audio/mpeg,audio/mp3,audio/wav,audio/ogg">
                    </div>
                </td>
                <td>
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="name" value="<?= htmlspecialchars((string) $gift['name']) ?>" placeholder="اسم الهدية">
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="category" value="<?= htmlspecialchars((string) $gift['category']) ?>" placeholder="الفئة">
                    <label class="checkbox-card">
                        <input form="<?= htmlspecialchars($formId) ?>" type="checkbox" name="is_animated" value="1" <?= ((int) ($gift['is_animated'] ?? 0)) === 1 ? 'checked' : '' ?>>
                        متحركة
                    </label>
                </td>
                <td>
                    <input form="<?= htmlspecialchars($formId) ?>" type="number" min="1" name="price_coins" value="<?= (int) $gift['price_coins'] ?>" placeholder="السعر">
                    <input form="<?= htmlspecialchars($formId) ?>" type="number" min="600" max="8000" name="effect_duration_ms" value="<?= (int) ($gift['effect_duration_ms'] ?? 1800) ?>" placeholder="مدة التأثير">
                    <input form="<?= htmlspecialchars($formId) ?>" type="number" min="0" name="display_order" value="<?= (int) $gift['display_order'] ?>" placeholder="الترتيب">
                </td>
                <td>
                    <select form="<?= htmlspecialchars($formId) ?>" name="status">
                        <option value="active" <?= $gift['status'] === 'active' ? 'selected' : '' ?>>نشطة</option>
                        <option value="hidden" <?= $gift['status'] === 'hidden' ? 'selected' : '' ?>>مخفية</option>
                    </select>
                </td>
                <td>
                    <div class="stack">
                        <button form="<?= htmlspecialchars($formId) ?>" class="btn btn-primary" type="submit" name="action" value="update">حفظ</button>
                        <button form="<?= htmlspecialchars($formId) ?>" class="btn btn-secondary" type="submit" name="action" value="delete" formnovalidate onclick="return confirm('حذف الهدية من التطبيق؟ سيتم إخفاؤها ولن تضيع معاملات الهدايا السابقة.');">حذف</button>
                    </div>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
