<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/GiftService.php';

admin_require_auth();
$pdo = admin_pdo();
$giftService = new GiftService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$transactions = $giftService->adminListTransactions($search);

admin_render_header('سجل الهدايا', 'gift-transactions');
?>
<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم المرسل أو الغرفة أو الهدية">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>المرسل</th>
                <th>الغرفة</th>
                <th>الهدية</th>
                <th>الكمية</th>
                <th>الإجمالي</th>
                <th>الوجهة</th>
                <th>الوقت</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($transactions as $transaction): ?>
            <tr>
                <td>#<?= (int) $transaction['id'] ?></td>
                <td><?= htmlspecialchars((string) $transaction['sender_name']) ?></td>
                <td><?= htmlspecialchars((string) $transaction['room_title']) ?></td>
                <td><?= htmlspecialchars((string) $transaction['gift_name_snapshot']) ?></td>
                <td><?= (int) $transaction['quantity'] ?></td>
                <td><?= (int) $transaction['total_price_coins'] ?> Coin</td>
                <td>
                    <?= $transaction['recipient_mode'] === 'selected_user'
                        ? 'مستخدم محدد' . ($transaction['recipient_slot'] ? ' #' . (int) $transaction['recipient_slot'] : '')
                        : 'جميع المستخدمين' ?>
                </td>
                <td><?= htmlspecialchars((string) $transaction['created_at']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
