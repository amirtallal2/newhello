<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ChatService.php';

admin_require_auth();
$pdo = admin_pdo();
$chatService = new ChatService($pdo);
$threadId = (int) ($_GET['id'] ?? $_POST['thread_id'] ?? 0);
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (isset($_POST['send_message'])) {
            $chatService->adminSendMessage(
                $threadId,
                (string) ($_POST['body_text'] ?? ''),
                'Admin Panel'
            );
            $flash = 'تم إرسال الرسالة.';
        } else {
            $chatService->adminUpdateThread(
                $threadId,
                trim((string) ($_POST['title'] ?? '')),
                trim((string) ($_POST['preview_text'] ?? '')),
                trim((string) ($_POST['avatar_asset'] ?? '')),
                trim((string) ($_POST['status_color_hex'] ?? '')),
                (string) ($_POST['read_style'] ?? 'single'),
                (int) ($_POST['unread_count'] ?? 0),
                (string) ($_POST['status'] ?? 'active')
            );
            $flash = 'تم تحديث بيانات المحادثة.';
        }
    }

    $thread = $chatService->adminGetThread($threadId);
    $messages = $chatService->adminListMessages($threadId);
} catch (ApiException $exception) {
    $error = $exception->getMessage();
    $thread = null;
    $messages = [];
}

admin_render_header('تفاصيل المحادثة', 'chat-threads');
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

<?php if ($thread !== null): ?>
    <section class="panel">
        <div class="detail-grid">
            <div><?= admin_render_media_preview((string) $thread['avatar_asset'], (string) $thread['title'], 'media-thumb') ?></div>
            <div><strong>العنوان:</strong> <?= htmlspecialchars((string) $thread['title']) ?></div>
            <div><strong>المالك:</strong> <?= htmlspecialchars((string) ($thread['owner_nickname'] ?: 'بدون اسم')) ?></div>
            <div><strong>البريد:</strong> <?= htmlspecialchars((string) ($thread['owner_email'] ?: 'بدون بريد')) ?></div>
            <div><strong>القسم:</strong> <?= htmlspecialchars((string) $thread['listing_group']) ?></div>
            <div><strong>النوع:</strong> <?= htmlspecialchars((string) $thread['thread_type']) ?></div>
            <div><strong>غير مقروء:</strong> <?= (int) $thread['unread_count'] ?></div>
            <div><strong>لون الحالة:</strong> <?= htmlspecialchars((string) $thread['status_color_hex']) ?></div>
            <div><strong>نمط القراءة:</strong> <?= htmlspecialchars((string) $thread['read_style']) ?></div>
        </div>
    </section>

    <section class="panel">
        <form method="post" class="form-grid">
            <input type="hidden" name="thread_id" value="<?= (int) $thread['id'] ?>">
            <label>
                العنوان
                <input type="text" name="title" value="<?= htmlspecialchars((string) $thread['title']) ?>">
            </label>
            <label>
                صورة المحادثة
                <div class="media-stack">
                    <?= admin_render_media_preview((string) $thread['avatar_asset'], (string) $thread['title']) ?>
                    <input type="text" name="avatar_asset" value="<?= htmlspecialchars((string) $thread['avatar_asset']) ?>" placeholder="assets/... أو /storage/...">
                </div>
            </label>
            <label>
                لون الحالة
                <input type="text" name="status_color_hex" value="<?= htmlspecialchars((string) $thread['status_color_hex']) ?>" placeholder="#6F7C8F">
            </label>
            <label>
                نمط القراءة
                <select name="read_style">
                    <option value="none" <?= $thread['read_style'] === 'none' ? 'selected' : '' ?>>none</option>
                    <option value="single" <?= $thread['read_style'] === 'single' ? 'selected' : '' ?>>single</option>
                    <option value="double" <?= $thread['read_style'] === 'double' ? 'selected' : '' ?>>double</option>
                </select>
            </label>
            <label>
                الحالة
                <select name="status">
                    <option value="active" <?= $thread['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                    <option value="archived" <?= $thread['status'] === 'archived' ? 'selected' : '' ?>>مؤرشف</option>
                    <option value="hidden" <?= $thread['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
                </select>
            </label>
            <label>
                غير مقروء
                <input type="number" min="0" name="unread_count" value="<?= (int) $thread['unread_count'] ?>">
            </label>
            <label class="span-2">
                نص المعاينة
                <textarea name="preview_text" rows="3"><?= htmlspecialchars((string) $thread['preview_text']) ?></textarea>
            </label>
            <div class="action-row span-2">
                <button class="btn btn-primary" type="submit">حفظ المحادثة</button>
                <a class="btn btn-ghost" href="/admin/chat-threads.php">العودة</a>
            </div>
        </form>
    </section>

    <section class="panel table-panel">
        <table class="table">
            <thead>
            <tr>
                <th>ID</th>
                <th>الاتجاه</th>
                <th>المرسل</th>
                <th>النوع</th>
                <th>المرفق</th>
                <th>المحتوى</th>
                <th>الوقت</th>
                <th>التاريخ</th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($messages as $message): ?>
                <tr>
                    <td>#<?= (int) $message['id'] ?></td>
                    <td><?= htmlspecialchars((string) $message['direction']) ?></td>
                    <td><?= htmlspecialchars((string) $message['sender_name']) ?></td>
                    <td><?= htmlspecialchars((string) $message['message_type']) ?></td>
                    <td>
                        <?php if (!empty($message['attachment_path'])): ?>
                            <?= admin_render_media_preview((string) $message['attachment_path'], (string) ($message['attachment_name'] ?? $message['body_text'])) ?>
                        <?php else: ?>
                            <span class="muted-copy">لا يوجد</span>
                        <?php endif; ?>
                    </td>
                    <td><?= htmlspecialchars((string) $message['body_text']) ?></td>
                    <td><?= htmlspecialchars((string) $message['time_label']) ?></td>
                    <td><?= htmlspecialchars((string) $message['created_at']) ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </section>

    <section class="panel">
        <form method="post" class="form-grid">
            <input type="hidden" name="thread_id" value="<?= (int) $thread['id'] ?>">
            <label style="grid-column: 1 / -1;">
                <span>إرسال رسالة إدارية</span>
                <textarea name="body_text" placeholder="اكتب رسالة لإضافتها داخل المحادثة"></textarea>
            </label>
            <div class="action-row">
                <button class="btn btn-primary" type="submit" name="send_message" value="1">إرسال الآن</button>
            </div>
        </form>
    </section>
<?php endif; ?>
<?php admin_render_footer(); ?>
