<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';

if (admin_current_user() !== null) {
    admin_redirect('/admin/index.php');
}

$error = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = (string) ($_POST['email'] ?? '');
    $password = (string) ($_POST['password'] ?? '');

    if (admin_attempt_login($email, $password)) {
        admin_redirect('/admin/index.php');
    }

    $error = 'بيانات الدخول غير صحيحة.';
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تسجيل دخول الأدمن</title>
    <link rel="stylesheet" href="/admin/assets/style.css">
</head>
<body class="login-page">
    <div class="login-card">
        <div class="brand login-brand">
            <div class="brand-badge">
                <img class="brand-logo-image" src="<?= htmlspecialchars(admin_brand_logo_url(), ENT_QUOTES) ?>" alt="<?= htmlspecialchars(admin_brand_name(), ENT_QUOTES) ?>">
            </div>
            <div>
                <div class="brand-title"><?= htmlspecialchars(admin_brand_name()) ?></div>
                <div class="brand-subtitle">Admin Panel</div>
            </div>
        </div>
        <h1>تسجيل دخول الأدمن</h1>
        <p class="login-hint">الحساب الافتراضي: admin@voicelive.local / Admin@12345</p>
        <?php if ($error !== null): ?>
            <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>
        <form method="post" class="stack">
            <label class="field">
                <span>البريد الإلكتروني</span>
                <input type="email" name="email" required value="admin@voicelive.local">
            </label>
            <label class="field">
                <span>كلمة المرور</span>
                <input type="password" name="password" required value="Admin@12345">
            </label>
            <button class="btn btn-primary" type="submit">دخول</button>
        </form>
    </div>
</body>
</html>
