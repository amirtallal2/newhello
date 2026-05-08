<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ChatService.php';

admin_require_auth();
$pdo = admin_pdo();
$chatService = new ChatService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$group = (string) ($_GET['group'] ?? 'all');
$status = (string) ($_GET['status'] ?? 'all');
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $thread = $chatService->adminGetThread((int) ($_POST['thread_id'] ?? 0));
        $chatService->adminUpdateThread(
            (int) ($_POST['thread_id'] ?? 0),
            (string) $thread['title'],
            (string) $thread['preview_text'],
            (string) $thread['avatar_asset'],
            (string) $thread['status_color_hex'],
            (string) $thread['read_style'],
            (int) $thread['unread_count'],
            (string) ($_POST['status'] ?? 'active')
        );
        $flash = 'تم تحديث حالة المحادثة.';
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$threads = $chatService->adminListThreads($search, $group, $status);

admin_render_header('إدارة المحادثات', 'chat-threads');
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
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بعنوان المحادثة أو البريد أو المعاينة">
        <select name="group">
            <option value="all" <?= $group === 'all' ? 'selected' : '' ?>>كل الأقسام</option>
            <option value="friends" <?= $group === 'friends' ? 'selected' : '' ?>>الاصدقاء</option>
            <option value="messages" <?= $group === 'messages' ? 'selected' : '' ?>>الرسائل</option>
        </select>
        <select name="status">
            <option value="all" <?= $status === 'all' ? 'selected' : '' ?>>كل الحالات</option>
            <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>نشط</option>
            <option value="archived" <?= $status === 'archived' ? 'selected' : '' ?>>مؤرشف</option>
            <option value="hidden" <?= $status === 'hidden' ? 'selected' : '' ?>>مخفي</option>
        </select>
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>الصورة</th>
                <th>العنوان</th>
                <th>المالك</th>
            <th>المعاينة</th>
            <th>النوع</th>
            <th>غير مقروء</th>
            <th>الحالة</th>
            <th>التفاصيل</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($threads as $thread): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="thread_id" value="<?= (int) $thread['id'] ?>">
                    <td>#<?= (int) $thread['id'] ?></td>
                    <td><?= admin_render_media_preview((string) $thread['avatar_asset'], (string) $thread['title']) ?></td>
                    <td>
                        <div><?= htmlspecialchars((string) $thread['title']) ?></div>
                        <div class="muted-copy"><?= htmlspecialchars((string) $thread['listing_group']) ?> / <?= htmlspecialchars((string) $thread['thread_type']) ?></div>
                    </td>
                    <td>
                        <div><?= htmlspecialchars((string) ($thread['owner_nickname'] ?: 'بدون اسم')) ?></div>
                        <div class="muted-copy"><?= htmlspecialchars((string) ($thread['owner_email'] ?: 'بدون بريد')) ?></div>
                    </td>
                    <td><?= htmlspecialchars(mb_strimwidth((string) $thread['preview_text'], 0, 80, '...')) ?></td>
                    <td><?= (int) $thread['is_system'] === 1 ? 'system' : 'direct' ?></td>
                    <td><?= (int) $thread['unread_count'] ?></td>
                    <td>
                        <div class="stack">
                            <select name="status">
                                <option value="active" <?= $thread['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                                <option value="archived" <?= $thread['status'] === 'archived' ? 'selected' : '' ?>>مؤرشف</option>
                                <option value="hidden" <?= $thread['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
                            </select>
                            <button class="btn btn-primary" type="submit">حفظ</button>
                        </div>
                    </td>
                    <td>
                        <a class="btn btn-secondary" href="/admin/chat-thread.php?id=<?= (int) $thread['id'] ?>">عرض</a>
                    </td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
