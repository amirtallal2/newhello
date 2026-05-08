<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/SupportService.php';

admin_require_auth();
$pdo = admin_pdo();
$supportService = new SupportService($pdo);
$ticketId = (int) ($_GET['id'] ?? 0);
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $supportService->adminUpdateSupportTicket(
            $ticketId,
            (string) ($_POST['status'] ?? 'new'),
            trim((string) ($_POST['admin_note'] ?? ''))
        );
        $flash = 'تم تحديث التذكرة.';
    }
    $ticket = $supportService->adminGetSupportTicket($ticketId);
} catch (ApiException $exception) {
    $error = $exception->getMessage();
    $ticket = null;
}

admin_render_header('تفاصيل تذكرة الدعم', 'support-tickets');
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

<?php if ($ticket !== null): ?>
    <section class="panel">
        <div class="detail-grid">
            <div><strong>رقم التذكرة:</strong> <?= htmlspecialchars((string) $ticket['ticket_code']) ?></div>
            <div><strong>الفئة:</strong> <?= htmlspecialchars((string) $ticket['category']) ?></div>
            <div><strong>الاسم:</strong> <?= htmlspecialchars((string) $ticket['sender_name']) ?></div>
            <div><strong>البريد:</strong> <?= htmlspecialchars((string) ($ticket['sender_email'] ?: '-')) ?></div>
            <div><strong>الهاتف:</strong> <?= htmlspecialchars((string) ($ticket['sender_phone'] ?: '-')) ?></div>
            <div><strong>الحالة:</strong> <?= htmlspecialchars((string) $ticket['status']) ?></div>
            <div><strong>عدد المرفقات:</strong> <?= (int) $ticket['attachment_count'] ?></div>
            <div><strong>تاريخ الإنشاء:</strong> <?= htmlspecialchars((string) $ticket['created_at']) ?></div>
        </div>
    </section>

    <section class="panel">
        <div class="panel-title">وصف المشكلة</div>
        <p class="panel-copy"><?= nl2br(htmlspecialchars((string) $ticket['description'])) ?></p>
    </section>

    <section class="panel">
        <div class="panel-title">المرفقات</div>
        <?php if (($ticket['attachments'] ?? []) === []): ?>
            <p class="panel-copy">لا توجد مرفقات لهذه التذكرة.</p>
        <?php else: ?>
            <div class="attachment-grid">
                <?php foreach ($ticket['attachments'] as $attachment): ?>
                    <?php $attachmentUrl = admin_media_url((string) $attachment['file_path']); ?>
                    <a class="attachment-card" href="<?= htmlspecialchars((string) $attachmentUrl) ?>" target="_blank" rel="noreferrer">
                        <img src="<?= htmlspecialchars((string) $attachmentUrl) ?>" alt="<?= htmlspecialchars((string) $attachment['original_name']) ?>">
                        <div class="attachment-name"><?= htmlspecialchars((string) $attachment['original_name']) ?></div>
                    </a>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </section>

    <section class="panel">
        <div class="panel-title">إجراء الأدمن</div>
        <form method="post" class="form-grid">
            <label>
                الحالة
                <select name="status">
                    <option value="new" <?= $ticket['status'] === 'new' ? 'selected' : '' ?>>جديد</option>
                    <option value="in_progress" <?= $ticket['status'] === 'in_progress' ? 'selected' : '' ?>>قيد المتابعة</option>
                    <option value="resolved" <?= $ticket['status'] === 'resolved' ? 'selected' : '' ?>>تم الحل</option>
                    <option value="closed" <?= $ticket['status'] === 'closed' ? 'selected' : '' ?>>مغلق</option>
                </select>
            </label>
            <label style="grid-column: 1 / -1;">
                ملاحظة الإدارة
                <textarea name="admin_note" rows="5"><?= htmlspecialchars((string) ($ticket['admin_note'] ?? '')) ?></textarea>
            </label>
            <div class="action-row">
                <button class="btn btn-primary" type="submit">حفظ</button>
                <a class="btn btn-ghost" href="/admin/support-tickets.php">العودة للقائمة</a>
            </div>
        </form>
    </section>
<?php endif; ?>
<?php admin_render_footer(); ?>
