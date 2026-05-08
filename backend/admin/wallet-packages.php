<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';

admin_require_auth();
$pdo = admin_pdo();
$economyService = new EconomyService($pdo);
$walletType = trim((string) ($_GET['wallet_type'] ?? ''));
$search = trim((string) ($_GET['search'] ?? ''));
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? 'update');

        if ($action === 'create') {
            $economyService->createWalletPackageAdmin(
                (string) ($_POST['wallet_type'] ?? 'coins'),
                (int) ($_POST['amount'] ?? 0),
                (int) ($_POST['bonus_amount'] ?? 0),
                trim((string) ($_POST['price_label'] ?? '')),
                (string) ($_POST['status'] ?? 'active')
            );
            $flash = 'تم إنشاء باقة الشحن.';
        } else {
            $economyService->updateWalletPackageAdmin(
                (int) ($_POST['package_id'] ?? 0),
                (string) ($_POST['wallet_type'] ?? 'coins'),
                (int) ($_POST['amount'] ?? 0),
                (int) ($_POST['bonus_amount'] ?? 0),
                trim((string) ($_POST['price_label'] ?? '')),
                (string) ($_POST['status'] ?? 'active')
            );
            $flash = 'تم تحديث باقة الشحن.';
        }
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$packages = $economyService->adminListWalletPackages($walletType, $search);

admin_render_header('باقات الشحن', 'wallet-packages');
?>
<?php if ($flash !== null): ?>
    <section class="panel"><div class="pill pill-success"><?= htmlspecialchars($flash) ?></div></section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel"><div class="pill pill-danger"><?= htmlspecialchars($error) ?></div></section>
<?php endif; ?>

<section class="panel">
    <div class="panel-title">إضافة باقة جديدة</div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="create">
        <label>
            نوع المحفظة
            <select name="wallet_type">
                <option value="coins">كوينز</option>
                <option value="diamonds">ألماس</option>
            </select>
        </label>
        <label>
            القيمة
            <input type="number" min="1" name="amount" value="1000" required>
        </label>
        <label>
            البونص
            <input type="number" min="0" name="bonus_amount" value="0" required>
        </label>
        <label>
            السعر المعروض
            <input type="text" name="price_label" value="100" required>
        </label>
        <label>
            الحالة
            <select name="status">
                <option value="active">نشطة</option>
                <option value="hidden">مخفية</option>
            </select>
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">إضافة</button>
        </div>
    </form>
</section>

<section class="panel">
    <form method="get" class="toolbar">
        <select name="wallet_type">
            <option value="">كل المحافظ</option>
            <option value="coins" <?= $walletType === 'coins' ? 'selected' : '' ?>>كوينز</option>
            <option value="diamonds" <?= $walletType === 'diamonds' ? 'selected' : '' ?>>ألماس</option>
        </select>
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بالسعر أو القيمة">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>النوع</th>
            <th>القيمة</th>
            <th>البونص</th>
            <th>السعر</th>
            <th>الحالة</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($packages as $package): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="package_id" value="<?= (int) $package['id'] ?>">
                    <td>#<?= (int) $package['id'] ?></td>
                    <td>
                        <select name="wallet_type">
                            <option value="coins" <?= $package['wallet_type'] === 'coins' ? 'selected' : '' ?>>كوينز</option>
                            <option value="diamonds" <?= $package['wallet_type'] === 'diamonds' ? 'selected' : '' ?>>ألماس</option>
                        </select>
                    </td>
                    <td><input type="number" min="1" name="amount" value="<?= (int) $package['amount'] ?>"></td>
                    <td><input type="number" min="0" name="bonus_amount" value="<?= (int) $package['bonus_amount'] ?>"></td>
                    <td><input type="text" name="price_label" value="<?= htmlspecialchars((string) $package['price_label']) ?>"></td>
                    <td>
                        <select name="status">
                            <option value="active" <?= $package['status'] === 'active' ? 'selected' : '' ?>>نشطة</option>
                            <option value="hidden" <?= $package['status'] === 'hidden' ? 'selected' : '' ?>>مخفية</option>
                        </select>
                    </td>
                    <td><button class="btn btn-primary" type="submit">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
