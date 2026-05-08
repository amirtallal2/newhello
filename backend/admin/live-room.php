<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/LiveService.php';

admin_require_auth();
$pdo = admin_pdo();
$liveService = new LiveService($pdo);
$roomId = (int) ($_GET['id'] ?? 0);
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? 'save_room');
        if ($action === 'end_pk') {
            $liveService->adminEndPkBattle($roomId);
            $flash = 'تم إنهاء PK لهذه الغرفة.';
        } else {
            $liveService->updateRoomAdmin(
                $roomId,
                trim((string) ($_POST['title'] ?? '')),
                trim((string) ($_POST['host_name'] ?? '')),
                trim((string) ($_POST['host_id_label'] ?? '')),
                isset($_POST['host_user_id']) && (int) $_POST['host_user_id'] > 0 ? (int) $_POST['host_user_id'] : null,
                isset($_POST['video_enabled']),
                trim((string) ($_POST['agora_channel_name'] ?? '')),
                (int) ($_POST['viewer_count'] ?? 0),
                (int) ($_POST['coin_count'] ?? 0),
                (string) ($_POST['listing_scope'] ?? 'live'),
                (string) ($_POST['status'] ?? 'active'),
                (int) ($_POST['contribution_diamonds_total'] ?? 0),
                (int) ($_POST['contribution_sender_count'] ?? 0),
                (string) ($_POST['pk_talk_permission'] ?? 'عند الطلب'),
                (string) ($_POST['pk_party_invite_permission'] ?? 'عند الطلب'),
                (string) ($_POST['pk_voice_room_invite_permission'] ?? 'عند الطلب'),
                (string) ($_POST['pk_chat_permission'] ?? 'عند الطلب'),
                (string) ($_POST['pk_battle_duration'] ?? '30د')
            );
            $flash = 'تم حفظ بيانات اللايف.';
        }
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$room = $liveService->getRoom($roomId);
$viewers = $liveService->adminViewers($roomId);
$comments = $liveService->adminComments($roomId);
$notifications = $liveService->adminRoomNotifications($roomId);
$reports = $liveService->adminRoomReports($roomId);
$giftTransactions = $liveService->adminRoomGiftTransactions($roomId);
$pkInvites = $liveService->adminRoomPkInvites($roomId);
$pk = $room['pk_settings'];
$pkState = $room['pk_state'];

admin_render_header('تفاصيل اللايف', 'live-rooms');
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
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="save_room">
        <label>
            <span>عنوان اللايف</span>
            <input type="text" name="title" value="<?= htmlspecialchars((string) $room['title']) ?>" required>
        </label>
        <label>
            <span>اسم المضيف</span>
            <input type="text" name="host_name" value="<?= htmlspecialchars((string) $room['host_name']) ?>" required>
        </label>
        <label>
            <span>معرف المضيف</span>
            <input type="text" name="host_id_label" value="<?= htmlspecialchars((string) $room['host_id_label']) ?>" required>
        </label>
        <label>
            <span>Host User ID للبث الحقيقي</span>
            <input type="number" name="host_user_id" value="<?= htmlspecialchars((string) ($room['host_user_id'] ?? '')) ?>" min="1" placeholder="اتركه فارغًا للمشاهدين فقط">
        </label>
        <label>
            <span>Agora Channel Name</span>
            <input type="text" name="agora_channel_name" value="<?= htmlspecialchars((string) ($room['agora_channel_name'] ?? '')) ?>" placeholder="live-room-<?= (int) $room['id'] ?>">
        </label>
        <label class="check-row">
            <input type="checkbox" name="video_enabled" value="1" <?= ((bool) ($room['video_enabled'] ?? true)) ? 'checked' : '' ?>>
            <span>تشغيل فيديو Agora الحقيقي</span>
        </label>
        <label>
            <span>المشاهدون</span>
            <input type="number" name="viewer_count" value="<?= (int) $room['viewer_count'] ?>" min="0">
        </label>
        <label>
            <span>الداعمون/الكوينز</span>
            <input type="number" name="coin_count" value="<?= (int) $room['coin_count'] ?>" min="0">
        </label>
        <label>
            <span>قائمة الظهور</span>
            <select name="listing_scope">
                <?php foreach (['live' => 'بث مباشر', 'newest' => 'جديد', 'friends' => 'اصدقاء'] as $value => $label): ?>
                    <option value="<?= $value ?>" <?= $value === $room['listing_scope'] ? 'selected' : '' ?>><?= $label ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>الحالة</span>
            <select name="status">
                <option value="active" <?= ($room['status'] ?? 'active') === 'active' ? 'selected' : '' ?>>نشط</option>
                <option value="hidden" <?= ($room['status'] ?? 'active') === 'hidden' ? 'selected' : '' ?>>مخفي</option>
            </select>
        </label>
        <label>
            <span>إجمالي الهدايا</span>
            <input type="number" name="contribution_diamonds_total" value="<?= (int) $room['contribution_diamonds_total'] ?>" min="0">
        </label>
        <label>
            <span>عدد المرسلين</span>
            <input type="number" name="contribution_sender_count" value="<?= (int) $room['contribution_sender_count'] ?>" min="0">
        </label>
        <label>
            <span>من يستطيع التحدث</span>
            <select name="pk_talk_permission">
                <?php foreach (['عند الطلب', 'شبكتي'] as $option): ?>
                    <option value="<?= $option ?>" <?= $pk['talk_permission'] === $option ? 'selected' : '' ?>><?= $option ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>دعوات Party</span>
            <select name="pk_party_invite_permission">
                <?php foreach (['عند الطلب', 'شبكتي'] as $option): ?>
                    <option value="<?= $option ?>" <?= $pk['party_invite_permission'] === $option ? 'selected' : '' ?>><?= $option ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>دعوات الغرف الصوتية</span>
            <select name="pk_voice_room_invite_permission">
                <?php foreach (['عند الطلب', 'شبكتي'] as $option): ?>
                    <option value="<?= $option ?>" <?= $pk['voice_room_invite_permission'] === $option ? 'selected' : '' ?>><?= $option ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>الدردشة</span>
            <select name="pk_chat_permission">
                <?php foreach (['عند الطلب', 'شبكتي'] as $option): ?>
                    <option value="<?= $option ?>" <?= $pk['chat_permission'] === $option ? 'selected' : '' ?>><?= $option ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>مدة المعركة</span>
            <select name="pk_battle_duration">
                <?php foreach (['3د', '5د', '15د', '30د', '60د'] as $option): ?>
                    <option value="<?= $option ?>" <?= $pk['battle_duration'] === $option ? 'selected' : '' ?>><?= $option ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">حفظ اللايف</button>
            <a class="btn btn-secondary" href="/admin/live-rooms.php">رجوع</a>
        </div>
    </form>
</section>

<section class="panel">
    <div class="panel-title">حالة PK الحالية</div>
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-label">الحالة</div>
            <div class="stat-value"><?= htmlspecialchars((string) ($pkState['status'] ?? 'idle')) ?></div>
        </div>
        <div class="stat-card">
            <div class="stat-label">ضيف PK</div>
            <div class="stat-value"><?= htmlspecialchars((string) ($pkState['guest_name'] ?: 'لا يوجد')) ?></div>
        </div>
        <div class="stat-card">
            <div class="stat-label">ينتهي في</div>
            <div class="stat-value"><?= htmlspecialchars((string) ($pkState['ends_at'] ?: '-')) ?></div>
        </div>
    </div>
    <?php if (($pkState['status'] ?? 'idle') !== 'idle'): ?>
        <form method="post" class="action-row">
            <input type="hidden" name="action" value="end_pk">
            <button class="btn btn-danger" type="submit">إنهاء PK الآن</button>
        </form>
    <?php endif; ?>
</section>

<section class="panel table-panel">
    <div class="panel-title">المشاهدون</div>
    <table class="table">
        <thead>
            <tr>
                <th>الترتيب</th>
                <th>الصورة</th>
                <th>الاسم</th>
                <th>أفضل داعم</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($viewers as $viewer): ?>
            <tr>
                <td><?= (int) $viewer['rank_order'] ?></td>
                <td><?= admin_render_media_preview((string) ($viewer['avatar_asset'] ?? ''), (string) $viewer['viewer_name']) ?></td>
                <td><?= htmlspecialchars((string) $viewer['viewer_name']) ?></td>
                <td><?= ((int) $viewer['is_top_supporter']) === 1 ? 'نعم' : 'لا' ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">تعليقات اللايف</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>الصورة</th>
                <th>الاسم</th>
                <th>التعليق</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($comments as $comment): ?>
            <tr>
                <td><?= (int) $comment['display_order'] ?></td>
                <td><?= admin_render_media_preview((string) ($comment['avatar_asset'] ?? ''), (string) $comment['commenter_name']) ?></td>
                <td><?= htmlspecialchars((string) $comment['commenter_name']) ?></td>
                <td><?= htmlspecialchars((string) $comment['message_text']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">إشعارات اللايف</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>العنوان</th>
                <th>المحتوى</th>
                <th>الحالة</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($notifications as $notification): ?>
            <tr>
                <td>#<?= (int) $notification['id'] ?></td>
                <td><?= htmlspecialchars((string) $notification['title_text']) ?></td>
                <td><?= htmlspecialchars((string) $notification['body_text']) ?></td>
                <td><?= htmlspecialchars((string) $notification['status']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">هدايا اللايف</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>صورة المرسل</th>
                <th>المرسل</th>
                <th>صورة الهدية</th>
                <th>الهدية</th>
                <th>الكمية</th>
                <th>الإجمالي</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($giftTransactions as $transaction): ?>
            <tr>
                <td>#<?= (int) $transaction['id'] ?></td>
                <td><?= admin_render_media_preview((string) ($transaction['sender_avatar_asset'] ?? ''), (string) $transaction['sender_name']) ?></td>
                <td><?= htmlspecialchars((string) $transaction['sender_name']) ?></td>
                <td><?= admin_render_media_preview((string) ($transaction['asset_path'] ?? ''), (string) $transaction['gift_name_snapshot']) ?></td>
                <td><?= htmlspecialchars((string) $transaction['gift_name_snapshot']) ?></td>
                <td><?= (int) $transaction['quantity'] ?></td>
                <td><?= (int) $transaction['total_price_coins'] ?> Coin</td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">بلاغات اللايف</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>المبلغ</th>
                <th>السبب</th>
                <th>الحالة</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($reports as $report): ?>
            <tr>
                <td>#<?= (int) $report['id'] ?></td>
                <td><?= htmlspecialchars((string) $report['reporter_name']) ?></td>
                <td><?= htmlspecialchars((string) $report['reason_text']) ?></td>
                <td><?= htmlspecialchars((string) $report['status']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">دعوات PK</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>المرسل</th>
                <th>المستلم</th>
                <th>الحالة</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($pkInvites as $invite): ?>
            <tr>
                <td>#<?= (int) $invite['id'] ?></td>
                <td><?= htmlspecialchars((string) $invite['sender_name']) ?></td>
                <td><?= htmlspecialchars((string) $invite['recipient_name_snapshot']) ?></td>
                <td><?= htmlspecialchars((string) $invite['status']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
