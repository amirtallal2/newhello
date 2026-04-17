<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';

admin_require_auth();
$pdo = admin_pdo();
$userId = (int) ($_GET['id'] ?? 0);

$statement = $pdo->prepare('SELECT * FROM users WHERE id = :id LIMIT 1');
$statement->execute(['id' => $userId]);
$user = $statement->fetch();

if ($user === false) {
    admin_redirect('/admin/users.php');
}

admin_render_header('تفاصيل المستخدم', 'users');
?>
<section class="panel">
    <div class="detail-grid">
        <div><strong>ID:</strong> #<?= (int) $user['id'] ?></div>
        <div><strong>الاسم:</strong> <?= htmlspecialchars((string) ($user['nickname'] ?: '-')) ?></div>
        <div><strong>البريد:</strong> <?= htmlspecialchars((string) ($user['email'] ?: '-')) ?></div>
        <div><strong>الهاتف:</strong> <?= htmlspecialchars((string) ($user['phone'] ?: '-')) ?></div>
        <div><strong>الحالة:</strong> <?= htmlspecialchars((string) $user['status']) ?></div>
        <div><strong>الجنس:</strong> <?= htmlspecialchars((string) ($user['gender'] ?: '-')) ?></div>
        <div><strong>الدولة:</strong> <?= htmlspecialchars((string) ($user['country'] ?: '-')) ?></div>
        <div><strong>عيد الميلاد:</strong> <?= htmlspecialchars((string) ($user['birthdate'] ?: '-')) ?></div>
        <div><strong>البريد موثق:</strong> <?= $user['email_verified_at'] ? 'نعم' : 'لا' ?></div>
        <div><strong>الهاتف موثق:</strong> <?= $user['phone_verified_at'] ? 'نعم' : 'لا' ?></div>
        <div><strong>تاريخ الإنشاء:</strong> <?= htmlspecialchars((string) $user['created_at']) ?></div>
        <div><strong>آخر تحديث:</strong> <?= htmlspecialchars((string) $user['updated_at']) ?></div>
    </div>
</section>
<?php admin_render_footer(); ?>
