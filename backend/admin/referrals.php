<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';

admin_require_auth();
$pdo = admin_pdo();
$referralService = new ReferralService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$status = trim((string) ($_GET['status'] ?? ''));
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? '');

        if ($action === 'save_settings') {
            $referralService->adminSaveSettings($_POST);
            $flash = 'تم تحديث إعدادات نظام الدعوات.';
        }

        if ($action === 'update_referral_status') {
            $referralService->adminUpdateReferralStatus(
                (int) ($_POST['referral_id'] ?? 0),
                (string) ($_POST['next_status'] ?? 'registered')
            );
            $flash = 'تم تحديث حالة الدعوة.';
        }
    }
} catch (Throwable $throwable) {
    $error = $throwable->getMessage();
}

$stats = $referralService->adminStats();
$settings = $referralService->adminSettings();
$referrals = $referralService->adminListReferrals($search, $status);
$rewards = $referralService->adminListRewardTransactions($search);

admin_render_header('الدعوات والأرباح', 'referrals');
?>
<?php if ($flash !== null): ?>
    <section class="panel"><div class="pill pill-success"><?= htmlspecialchars($flash) ?></div></section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel"><div class="pill pill-danger"><?= htmlspecialchars($error) ?></div></section>
<?php endif; ?>

<section class="panel">
    <div class="panel-title">ملخص نظام الدعوات</div>
    <div class="metric-grid">
        <div class="metric-card">
            <div class="metric-title">إجمالي الدعوات</div>
            <div class="metric-copy"><?= (int) $stats['total_referrals'] ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">دعوات اليوم</div>
            <div class="metric-copy"><?= (int) $stats['today_referrals'] ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">أكواد نشطة</div>
            <div class="metric-copy"><?= (int) $stats['active_codes'] ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">إجمالي الأرباح</div>
            <div class="metric-copy">$<?= number_format((float) $stats['total_rewards_usd'], 2) ?></div>
        </div>
    </div>
</section>

<section class="panel">
    <div class="panel-title">إعدادات الخوارزمية</div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="save_settings">
        <label>
            هدف الربح اليومي المعروض
            <input type="number" step="0.01" min="0" name="daily_target_usd" value="<?= htmlspecialchars((string) $settings['daily_target_usd']) ?>">
        </label>
        <label>
            مبلغ السحب الأول
            <input type="number" step="0.01" min="0" name="first_withdraw_usd" value="<?= htmlspecialchars((string) $settings['first_withdraw_usd']) ?>">
        </label>
        <label>
            أيام الوصول للسحب الأول
            <input type="number" min="0" name="first_withdraw_days" value="<?= (int) $settings['first_withdraw_days'] ?>">
        </label>
        <label>
            مكافأة التسجيل بالدولار
            <input type="number" step="0.01" min="0" name="signup_reward_usd" value="<?= htmlspecialchars((string) $settings['signup_reward_usd']) ?>">
        </label>
        <label>
            نسبة شحن الصديق المباشر %
            <input type="number" step="0.01" min="0" max="95" name="direct_recharge_percent" value="<?= htmlspecialchars((string) $settings['direct_recharge_percent']) ?>">
        </label>
        <label>
            نسبة شحن صديق الصديق %
            <input type="number" step="0.01" min="0" max="95" name="indirect_recharge_percent" value="<?= htmlspecialchars((string) $settings['indirect_recharge_percent']) ?>">
        </label>
        <label class="span-2">
            رابط الدعوة الأساسي
            <input type="text" name="invite_link_base" value="<?= htmlspecialchars((string) $settings['invite_link_base']) ?>">
        </label>
        <label class="span-2">
            صورة الهيدر
            <input type="text" name="header_asset" value="<?= htmlspecialchars((string) ($settings['header_asset'] ?? '')) ?>">
        </label>
        <label class="span-2">
            صورة كارت المكافأة
            <input type="text" name="reward_card_asset" value="<?= htmlspecialchars((string) ($settings['reward_card_asset'] ?? '')) ?>">
        </label>
        <label class="span-2">
            صورة الحالة الفارغة
            <input type="text" name="empty_asset" value="<?= htmlspecialchars((string) ($settings['empty_asset'] ?? '')) ?>">
        </label>
        <div class="action-row span-2">
            <button class="btn btn-primary" type="submit">حفظ الإعدادات</button>
        </div>
    </form>
</section>

<section class="panel">
    <form method="get" class="toolbar">
        <select name="status">
            <option value="">كل الحالات</option>
            <?php foreach (['registered', 'qualified', 'paid', 'rejected'] as $option): ?>
                <option value="<?= $option ?>" <?= $status === $option ? 'selected' : '' ?>><?= htmlspecialchars($option) ?></option>
            <?php endforeach; ?>
        </select>
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بالاسم أو البريد أو كود الدعوة">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <div class="panel-title">سجل الدعوات</div>
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>الداعي</th>
            <th>المدعو</th>
            <th>الكود</th>
            <th>المكافأة</th>
            <th>الحالة</th>
            <th>التاريخ</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($referrals as $referral): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="action" value="update_referral_status">
                    <input type="hidden" name="referral_id" value="<?= (int) $referral['id'] ?>">
                    <td>#<?= (int) $referral['id'] ?></td>
                    <td>
                        <?= htmlspecialchars((string) ($referral['inviter_name'] ?: 'بدون اسم')) ?>
                        <div class="muted-copy"><?= htmlspecialchars((string) $referral['inviter_code']) ?></div>
                    </td>
                    <td>
                        <?= htmlspecialchars((string) ($referral['invited_name'] ?: 'غير معروف')) ?>
                        <div class="muted-copy"><?= htmlspecialchars((string) ($referral['invited_email'] ?: $referral['invited_phone'] ?: '')) ?></div>
                    </td>
                    <td><span class="code-chip"><?= htmlspecialchars((string) $referral['invite_code_snapshot']) ?></span></td>
                    <td>$<?= number_format((float) $referral['total_reward_usd'], 2) ?></td>
                    <td>
                        <select name="next_status">
                            <?php foreach (['registered', 'qualified', 'paid', 'rejected'] as $option): ?>
                                <option value="<?= $option ?>" <?= $referral['status'] === $option ? 'selected' : '' ?>><?= htmlspecialchars($option) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </td>
                    <td><?= htmlspecialchars((string) $referral['created_at']) ?></td>
                    <td><button class="btn btn-secondary" type="submit">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        <?php if ($referrals === []): ?>
            <tr><td colspan="8">لا توجد دعوات مطابقة.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">سجل أرباح الدعوات</div>
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>المستخدم</th>
            <th>المصدر</th>
            <th>النوع</th>
            <th>القيمة</th>
            <th>النسبة</th>
            <th>الحالة</th>
            <th>التاريخ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($rewards as $reward): ?>
            <tr>
                <td>#<?= (int) $reward['id'] ?></td>
                <td><?= htmlspecialchars((string) ($reward['user_name'] ?: 'بدون اسم')) ?></td>
                <td><?= htmlspecialchars((string) ($reward['source_user_name'] ?: 'نظام')) ?></td>
                <td>
                    <?= htmlspecialchars((string) $reward['title']) ?>
                    <div class="muted-copy"><?= htmlspecialchars((string) $reward['reward_type']) ?></div>
                </td>
                <td>$<?= number_format((float) $reward['amount_usd'], 2) ?></td>
                <td><?= number_format((float) $reward['rate_percent'], 2) ?>%</td>
                <td><?= htmlspecialchars((string) $reward['status']) ?></td>
                <td><?= htmlspecialchars((string) $reward['created_at']) ?></td>
            </tr>
        <?php endforeach; ?>
        <?php if ($rewards === []): ?>
            <tr><td colspan="8">لا توجد أرباح مطابقة.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
