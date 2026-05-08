<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';

admin_require_auth();
$pdo = admin_pdo();
$economyService = new EconomyService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$transactions = $economyService->adminListEconomyTransactions($search);

admin_render_header('عمليات المتجر والمحفظة', 'economy-transactions');
?>
<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بالمستخدم أو الوصف">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>المستخدم</th>
            <th>نوع المحفظة</th>
            <th>الاتجاه</th>
            <th>القيمة</th>
            <th>العنوان</th>
            <th>الوصف</th>
            <th>السياق</th>
            <th>التاريخ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($transactions as $transaction): ?>
            <tr>
                <td>#<?= (int) $transaction['id'] ?></td>
                <td>
                    <?= htmlspecialchars((string) ($transaction['user_nickname'] ?: '-')) ?><br>
                    <small><?= htmlspecialchars((string) ($transaction['user_email'] ?: '-')) ?></small>
                </td>
                <td><?= htmlspecialchars((string) $transaction['wallet_type']) ?></td>
                <td><?= htmlspecialchars((string) $transaction['direction']) ?></td>
                <td><?= (int) $transaction['amount'] ?></td>
                <td><?= htmlspecialchars((string) $transaction['title']) ?></td>
                <td><?= htmlspecialchars((string) $transaction['subtitle']) ?></td>
                <td><?= htmlspecialchars((string) $transaction['context_type']) ?> / <?= htmlspecialchars((string) ($transaction['context_ref'] ?? '-')) ?></td>
                <td><?= htmlspecialchars((string) $transaction['created_at']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
