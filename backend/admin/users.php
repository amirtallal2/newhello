<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';

admin_require_auth();
$pdo = admin_pdo();
$search = trim((string) ($_GET['search'] ?? ''));

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $userId = (int) ($_POST['user_id'] ?? 0);
    $action = (string) ($_POST['action'] ?? '');

    if ($userId > 0) {
        if ($action === 'suspend' || $action === 'activate') {
            $status = $action === 'activate' ? 'active' : 'suspended';
            $statement = $pdo->prepare(
                'UPDATE users SET status = :status, updated_at = :updated_at WHERE id = :id'
            );
            $statement->execute([
                'status' => $status,
                'updated_at' => gmdate('Y-m-d H:i:s'),
                'id' => $userId,
            ]);
        }

        if ($action === 'verify_email' || $action === 'verify_phone') {
            $field = $action === 'verify_email' ? 'email_verified_at' : 'phone_verified_at';
            $statement = $pdo->prepare(
                "UPDATE users SET {$field} = :verified_at, updated_at = :updated_at WHERE id = :id"
            );
            $statement->execute([
                'verified_at' => gmdate('Y-m-d H:i:s'),
                'updated_at' => gmdate('Y-m-d H:i:s'),
                'id' => $userId,
            ]);
        }
    }

    admin_redirect('/admin/users.php' . ($search !== '' ? '?search=' . urlencode($search) : ''));
}

$sql = 'SELECT * FROM users';
$params = [];

if ($search !== '') {
    $sql .= ' WHERE email LIKE :search OR phone LIKE :search OR nickname LIKE :search';
    $params['search'] = '%' . $search . '%';
}

$sql .= ' ORDER BY id DESC';
$statement = $pdo->prepare($sql);
$statement->execute($params);
$users = $statement->fetchAll();

admin_render_header('إدارة المستخدمين', 'users');
?>
<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بالبريد أو الهاتف أو الاسم">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>الاسم</th>
                <th>البريد</th>
                <th>الهاتف</th>
                <th>الحالة</th>
                <th>بريد</th>
                <th>هاتف</th>
                <th>إجراءات</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($users as $user): ?>
            <tr>
                <td>#<?= (int) $user['id'] ?></td>
                <td><a href="/admin/user.php?id=<?= (int) $user['id'] ?>"><?= htmlspecialchars((string) ($user['nickname'] ?: 'بدون اسم')) ?></a></td>
                <td><?= htmlspecialchars((string) ($user['email'] ?: '-')) ?></td>
                <td><?= htmlspecialchars((string) ($user['phone'] ?: '-')) ?></td>
                <td>
                    <span class="pill <?= $user['status'] === 'active' ? 'pill-success' : 'pill-danger' ?>">
                        <?= $user['status'] === 'active' ? 'نشط' : 'موقوف' ?>
                    </span>
                </td>
                <td><?= $user['email_verified_at'] ? 'نعم' : 'لا' ?></td>
                <td><?= $user['phone_verified_at'] ? 'نعم' : 'لا' ?></td>
                <td>
                    <div class="inline-actions">
                        <form method="post">
                            <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
                            <input type="hidden" name="action" value="<?= $user['status'] === 'active' ? 'suspend' : 'activate' ?>">
                            <button class="btn btn-secondary" type="submit">
                                <?= $user['status'] === 'active' ? 'إيقاف' : 'تفعيل' ?>
                            </button>
                        </form>
                        <?php if (!$user['email_verified_at']): ?>
                            <form method="post">
                                <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
                                <input type="hidden" name="action" value="verify_email">
                                <button class="btn btn-ghost" type="submit">توثيق البريد</button>
                            </form>
                        <?php endif; ?>
                        <?php if (!$user['phone_verified_at']): ?>
                            <form method="post">
                                <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
                                <input type="hidden" name="action" value="verify_phone">
                                <button class="btn btn-ghost" type="submit">توثيق الهاتف</button>
                            </form>
                        <?php endif; ?>
                    </div>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
