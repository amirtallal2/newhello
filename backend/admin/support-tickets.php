<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/SupportService.php';

admin_require_auth();
$pdo = admin_pdo();
$supportService = new SupportService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$status = (string) ($_GET['status'] ?? 'all');
$tickets = $supportService->adminListSupportTickets($search, $status);

admin_render_header('تذاكر الدعم', 'support-tickets');
?>
<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث برقم التذكرة أو الاسم أو البريد أو الوصف">
        <select name="status">
            <option value="all" <?= $status === 'all' ? 'selected' : '' ?>>كل الحالات</option>
            <option value="new" <?= $status === 'new' ? 'selected' : '' ?>>جديد</option>
            <option value="in_progress" <?= $status === 'in_progress' ? 'selected' : '' ?>>قيد المتابعة</option>
            <option value="resolved" <?= $status === 'resolved' ? 'selected' : '' ?>>تم الحل</option>
            <option value="closed" <?= $status === 'closed' ? 'selected' : '' ?>>مغلق</option>
        </select>
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>رقم التذكرة</th>
            <th>المرسل</th>
            <th>الفئة</th>
            <th>الحالة</th>
            <th>المرفقات</th>
            <th>تاريخ الإنشاء</th>
            <th>التفاصيل</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($tickets as $ticket): ?>
            <tr>
                <td><?= htmlspecialchars((string) $ticket['ticket_code']) ?></td>
                <td>
                    <div><?= htmlspecialchars((string) $ticket['sender_name']) ?></div>
                    <?php if (!empty($ticket['sender_email'])): ?>
                        <div class="muted-copy"><?= htmlspecialchars((string) $ticket['sender_email']) ?></div>
                    <?php endif; ?>
                </td>
                <td><?= htmlspecialchars((string) $ticket['category']) ?></td>
                <td>
                    <?php $pillClass = match ((string) $ticket['status']) {
                        'resolved' => 'pill-success',
                        'closed' => 'pill-danger',
                        default => 'pill-warning',
                    }; ?>
                    <span class="pill <?= $pillClass ?>">
                        <?= htmlspecialchars((string) $ticket['status']) ?>
                    </span>
                </td>
                <td><?= (int) $ticket['attachment_count'] ?></td>
                <td><?= htmlspecialchars((string) $ticket['created_at']) ?></td>
                <td>
                    <a href="/admin/support-ticket.php?id=<?= (int) $ticket['id'] ?>">فتح</a>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
