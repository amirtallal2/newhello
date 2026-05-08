<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';

admin_require_auth();
$pdo = admin_pdo();
$levelService = new LevelService($pdo);
$referralService = new ReferralService($pdo);
$userId = (int) ($_GET['id'] ?? $_POST['user_id'] ?? 0);

if ($userId <= 0) {
    admin_redirect('/admin/users.php');
}

$avatarOptions = [
    'assets/images/profile_avatar.png',
    'assets/images/post_author_avatar.png',
    'assets/images/live150_comment_avatar.png',
    'assets/images/profile_store_friend_yara.png',
    'assets/images/profile_store_friend_yara_alt.png',
    'assets/images/profile_store_friend_nona_avatar.png',
];
$agencyRoles = ['owner', 'member', 'manager'];
$statusOptions = ['active', 'suspended'];
$languageOptions = ['ar' => 'العربية', 'en' => 'English'];
$flash = null;
$error = null;

$fetchUser = static function (PDO $pdo, int $userId): array {
    $statement = $pdo->prepare('SELECT * FROM users WHERE id = :id LIMIT 1');
    $statement->execute(['id' => $userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    if ($user === false) {
        throw new RuntimeException('المستخدم غير موجود.');
    }

    return $user;
};

$ensureSettings = static function (PDO $pdo, int $userId): array {
    $statement = $pdo->prepare('SELECT * FROM user_settings WHERE user_id = :user_id LIMIT 1');
    $statement->execute(['user_id' => $userId]);
    $settings = $statement->fetch(PDO::FETCH_ASSOC);

    if ($settings !== false) {
        return $settings;
    }

    $defaults = [
        'user_id' => $userId,
        'private_profile' => 0,
        'allow_direct_messages' => 1,
        'show_online_status' => 1,
        'receive_chat_notifications' => 1,
        'receive_live_notifications' => 1,
        'receive_room_invites' => 1,
        'receive_party_invites' => 1,
        'preferred_language' => 'ar',
        'updated_at' => gmdate('Y-m-d H:i:s'),
    ];

    $insert = $pdo->prepare(
        'INSERT INTO user_settings
            (user_id, private_profile, allow_direct_messages, show_online_status, receive_chat_notifications, receive_live_notifications, receive_room_invites, receive_party_invites, preferred_language, updated_at)
         VALUES
            (:user_id, :private_profile, :allow_direct_messages, :show_online_status, :receive_chat_notifications, :receive_live_notifications, :receive_room_invites, :receive_party_invites, :preferred_language, :updated_at)'
    );
    $insert->execute($defaults);

    return $defaults;
};

$ensureWallet = static function (PDO $pdo, int $userId): array {
    $statement = $pdo->prepare('SELECT * FROM user_wallets WHERE user_id = :user_id LIMIT 1');
    $statement->execute(['user_id' => $userId]);
    $wallet = $statement->fetch(PDO::FETCH_ASSOC);

    if ($wallet !== false) {
        return $wallet;
    }

    $defaults = [
        'user_id' => $userId,
        'coins_balance' => 1235,
        'diamonds_balance' => 5,
        'created_at' => gmdate('Y-m-d H:i:s'),
        'updated_at' => gmdate('Y-m-d H:i:s'),
    ];

    $insert = $pdo->prepare(
        'INSERT INTO user_wallets
            (user_id, coins_balance, diamonds_balance, created_at, updated_at)
         VALUES
            (:user_id, :coins_balance, :diamonds_balance, :created_at, :updated_at)'
    );
    $insert->execute($defaults);

    return $defaults;
};

$checkbox = static fn (string $key): int => isset($_POST[$key]) ? 1 : 0;
$nullIfEmpty = static fn (?string $value): ?string => ($value === null || trim($value) === '') ? null : trim($value);
$trimmed = static fn (?string $value): string => trim((string) $value);
$toInt = static fn (?string $value, int $default = 0): int => is_numeric($value) ? (int) $value : $default;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $user = $fetchUser($pdo, $userId);
        $now = gmdate('Y-m-d H:i:s');
        $action = (string) ($_POST['action'] ?? '');

        switch ($action) {
            case 'save_account':
                $status = (string) ($_POST['status'] ?? 'active');
                if (!in_array($status, $statusOptions, true)) {
                    $status = 'active';
                }

                $avatarAsset = trim((string) ($_POST['avatar_asset'] ?? 'assets/images/profile_avatar.png'));
                if ($avatarAsset === '') {
                    $avatarAsset = 'assets/images/profile_avatar.png';
                }

                $agencyRole = $nullIfEmpty($_POST['agency_role'] ?? null);
                if ($agencyRole !== null && !in_array($agencyRole, $agencyRoles, true)) {
                    $agencyRole = null;
                }

                $statement = $pdo->prepare(
                    'UPDATE users
                     SET nickname = :nickname,
                         email = :email,
                         phone = :phone,
                         status = :status,
                         gender = :gender,
                         country = :country,
                         birthdate = :birthdate,
                         profile_handle = :profile_handle,
                         signature_text = :signature_text,
                         avatar_asset = :avatar_asset,
                         agency_role = :agency_role,
                         email_verified_at = :email_verified_at,
                         phone_verified_at = :phone_verified_at,
                         updated_at = :updated_at
                     WHERE id = :id'
                );
                $statement->execute([
                    'nickname' => $trimmed($_POST['nickname'] ?? null) !== '' ? $trimmed($_POST['nickname'] ?? null) : 'بدون اسم',
                    'email' => $nullIfEmpty($_POST['email'] ?? null),
                    'phone' => $nullIfEmpty($_POST['phone'] ?? null),
                    'status' => $status,
                    'gender' => $nullIfEmpty($_POST['gender'] ?? null),
                    'country' => $trimmed($_POST['country'] ?? null) !== '' ? $trimmed($_POST['country'] ?? null) : 'Egypt',
                    'birthdate' => $nullIfEmpty($_POST['birthdate'] ?? null),
                    'profile_handle' => $trimmed($_POST['profile_handle'] ?? null) !== '' ? $trimmed($_POST['profile_handle'] ?? null) : 'Shark.island',
                    'signature_text' => $trimmed($_POST['signature_text'] ?? null) !== '' ? $trimmed($_POST['signature_text'] ?? null) : 'ليس لديك المقدمة الشخصية',
                    'avatar_asset' => $avatarAsset,
                    'agency_role' => $user['agency_id'] === null ? null : $agencyRole,
                    'email_verified_at' => isset($_POST['email_verified'])
                        ? ((string) ($user['email_verified_at'] ?? '') !== '' ? $user['email_verified_at'] : $now)
                        : null,
                    'phone_verified_at' => isset($_POST['phone_verified'])
                        ? ((string) ($user['phone_verified_at'] ?? '') !== '' ? $user['phone_verified_at'] : $now)
                        : null,
                    'updated_at' => $now,
                    'id' => $userId,
                ]);
                $flash = 'تم تحديث بيانات الحساب والملف الشخصي.';
                break;

            case 'save_stats':
                $statement = $pdo->prepare(
                    'UPDATE users
                     SET following_count = :following_count,
                         followers_count = :followers_count,
                         friends_count = :friends_count,
                         level_current = :level_current,
                         level_next = :level_next,
                         level_progress_percent = :level_progress_percent,
                         vip_tier = :vip_tier,
                         svip_tier = :svip_tier,
                         badges_count = :badges_count,
                         tasks_completed = :tasks_completed,
                         tasks_total = :tasks_total,
                         updated_at = :updated_at
                     WHERE id = :id'
                );
                $statement->execute([
                    'following_count' => max(0, $toInt($_POST['following_count'] ?? null)),
                    'followers_count' => max(0, $toInt($_POST['followers_count'] ?? null)),
                    'friends_count' => max(0, $toInt($_POST['friends_count'] ?? null)),
                    'level_current' => max(0, $toInt($_POST['level_current'] ?? null)),
                    'level_next' => max(1, $toInt($_POST['level_next'] ?? null, 1)),
                    'level_progress_percent' => max(0, min(100, $toInt($_POST['level_progress_percent'] ?? null, 0))),
                    'vip_tier' => $trimmed($_POST['vip_tier'] ?? null) !== '' ? $trimmed($_POST['vip_tier'] ?? null) : 'VIP 0',
                    'svip_tier' => $trimmed($_POST['svip_tier'] ?? null) !== '' ? $trimmed($_POST['svip_tier'] ?? null) : 'SVIP 0',
                    'badges_count' => max(0, $toInt($_POST['badges_count'] ?? null)),
                    'tasks_completed' => max(0, $toInt($_POST['tasks_completed'] ?? null)),
                    'tasks_total' => max(1, $toInt($_POST['tasks_total'] ?? null, 1)),
                    'updated_at' => $now,
                    'id' => $userId,
                ]);
                $flash = 'تم تحديث مؤشرات الحساب.';
                break;

            case 'save_settings':
                $settings = $ensureSettings($pdo, $userId);
                $statement = $pdo->prepare(
                    'UPDATE user_settings
                     SET private_profile = :private_profile,
                         allow_direct_messages = :allow_direct_messages,
                         show_online_status = :show_online_status,
                         receive_chat_notifications = :receive_chat_notifications,
                         receive_live_notifications = :receive_live_notifications,
                         receive_room_invites = :receive_room_invites,
                         receive_party_invites = :receive_party_invites,
                         preferred_language = :preferred_language,
                         updated_at = :updated_at
                     WHERE user_id = :user_id'
                );
                $statement->execute([
                    'private_profile' => $checkbox('private_profile'),
                    'allow_direct_messages' => $checkbox('allow_direct_messages'),
                    'show_online_status' => $checkbox('show_online_status'),
                    'receive_chat_notifications' => $checkbox('receive_chat_notifications'),
                    'receive_live_notifications' => $checkbox('receive_live_notifications'),
                    'receive_room_invites' => $checkbox('receive_room_invites'),
                    'receive_party_invites' => $checkbox('receive_party_invites'),
                    'preferred_language' => array_key_exists((string) ($_POST['preferred_language'] ?? ''), $languageOptions)
                        ? (string) $_POST['preferred_language']
                        : (string) $settings['preferred_language'],
                    'updated_at' => $now,
                    'user_id' => $userId,
                ]);
                $flash = 'تم تحديث إعدادات الحساب.';
                break;

            case 'save_wallet':
                $ensureWallet($pdo, $userId);
                $statement = $pdo->prepare(
                    'UPDATE user_wallets
                     SET coins_balance = :coins_balance,
                         diamonds_balance = :diamonds_balance,
                         updated_at = :updated_at
                     WHERE user_id = :user_id'
                );
                $statement->execute([
                    'coins_balance' => max(0, $toInt($_POST['coins_balance'] ?? null)),
                    'diamonds_balance' => max(0, $toInt($_POST['diamonds_balance'] ?? null)),
                    'updated_at' => $now,
                    'user_id' => $userId,
                ]);
                $flash = 'تم تحديث رصيد المستخدم.';
                break;

            case 'set_password':
                $newPassword = $trimmed($_POST['new_password'] ?? null);
                if (mb_strlen($newPassword) < 6) {
                    throw new RuntimeException('كلمة المرور الجديدة يجب ألا تقل عن 6 أحرف.');
                }

                $statement = $pdo->prepare(
                    'UPDATE users
                     SET password_hash = :password_hash,
                         updated_at = :updated_at
                     WHERE id = :id'
                );
                $statement->execute([
                    'password_hash' => password_hash($newPassword, PASSWORD_DEFAULT),
                    'updated_at' => $now,
                    'id' => $userId,
                ]);
                $flash = 'تم تعيين كلمة مرور جديدة للمستخدم.';
                break;

            case 'clear_agency':
                $statement = $pdo->prepare(
                    'UPDATE users
                     SET agency_id = NULL,
                         agency_role = NULL,
                         agency_joined_at = NULL,
                         updated_at = :updated_at
                     WHERE id = :id'
                );
                $statement->execute([
                    'updated_at' => $now,
                    'id' => $userId,
                ]);
                $flash = 'تم فصل المستخدم عن الوكالة الحالية.';
                break;
        }
    } catch (Throwable $throwable) {
        $error = $throwable->getMessage();
    }
}

try {
    $user = $fetchUser($pdo, $userId);
} catch (RuntimeException $_) {
    admin_redirect('/admin/users.php');
}

$settings = $ensureSettings($pdo, $userId);
$wallet = $ensureWallet($pdo, $userId);
$vipSubscriptions = $levelService->adminSubscriptionsForUser($userId);
$referralSummary = $referralService->adminUserReferralSummary($userId);

$agency = null;
if ($user['agency_id'] !== null) {
    $statement = $pdo->prepare('SELECT * FROM agencies WHERE id = :id LIMIT 1');
    $statement->execute(['id' => (int) $user['agency_id']]);
    $agency = $statement->fetch(PDO::FETCH_ASSOC) ?: null;
}

$openRequestsStatement = $pdo->prepare(
    'SELECT request_code, agency_name, status, created_at
     FROM agency_open_requests
     WHERE user_id = :user_id
     ORDER BY id DESC
     LIMIT 3'
);
$openRequestsStatement->execute(['user_id' => $userId]);
$openRequests = $openRequestsStatement->fetchAll(PDO::FETCH_ASSOC);

$joinRequestsStatement = $pdo->prepare(
    'SELECT request_code, agency_name_snapshot, invitation_code, status, created_at
     FROM agency_join_requests
     WHERE user_id = :user_id
     ORDER BY id DESC
     LIMIT 3'
);
$joinRequestsStatement->execute(['user_id' => $userId]);
$joinRequests = $joinRequestsStatement->fetchAll(PDO::FETCH_ASSOC);

admin_render_header('إدارة المستخدم', 'users');
?>
<?php if ($flash !== null): ?>
    <div class="alert alert-success"><?= htmlspecialchars($flash) ?></div>
<?php endif; ?>
<?php if ($error !== null): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<section class="panel">
    <div class="panel-title">ملخص المستخدم</div>
    <div class="media-inline" style="margin-bottom:16px;">
        <?= admin_render_media_preview((string) ($user['avatar_asset'] ?? ''), (string) ($user['nickname'] ?? 'avatar'), 'media-thumb') ?>
    </div>
    <div class="metric-grid">
        <div class="metric-card">
            <div class="metric-title">المستخدم</div>
            <div class="metric-copy">#<?= (int) $user['id'] ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">الحالة</div>
            <div class="metric-copy"><?= htmlspecialchars((string) $user['status']) ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">الكوينز</div>
            <div class="metric-copy"><?= (int) $wallet['coins_balance'] ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">الماس</div>
            <div class="metric-copy"><?= (int) $wallet['diamonds_balance'] ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">VIP</div>
            <div class="metric-copy"><?= htmlspecialchars((string) ($user['vip_tier'] ?? 'VIP 0')) ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">دعوات</div>
            <div class="metric-copy"><?= (int) $referralSummary['invited_count'] ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">أرباح الدعوات</div>
            <div class="metric-copy">$<?= number_format((float) $referralSummary['rewards_usd'], 2) ?></div>
        </div>
    </div>
    <div class="detail-grid" style="margin-top:16px;">
        <div><strong>المعرف:</strong> <?= htmlspecialchars((string) ($user['profile_handle'] ?? 'Shark.island')) ?></div>
        <div><strong>كود الدعوة:</strong> <?= htmlspecialchars((string) $referralSummary['invite_code']) ?></div>
        <div><strong>المزود:</strong> <?= htmlspecialchars((string) ($user['auth_provider'] ?? 'password')) ?></div>
        <div><strong>البريد موثق:</strong> <?= $user['email_verified_at'] ? 'نعم' : 'لا' ?></div>
        <div><strong>الهاتف موثق:</strong> <?= $user['phone_verified_at'] ? 'نعم' : 'لا' ?></div>
        <div><strong>الوكالة:</strong> <?= htmlspecialchars((string) ($agency['name'] ?? 'لا يوجد')) ?></div>
        <div><strong>دور الوكالة:</strong> <?= htmlspecialchars((string) ($user['agency_role'] ?? 'لا يوجد')) ?></div>
        <div><strong>تاريخ الإنشاء:</strong> <?= htmlspecialchars((string) $user['created_at']) ?></div>
        <div><strong>آخر تحديث:</strong> <?= htmlspecialchars((string) $user['updated_at']) ?></div>
    </div>
</section>

<section class="panel">
    <h2 class="section-heading">الدعوات والأرباح</h2>
    <div class="detail-grid">
        <div>
            <div class="field-hint">كود دعوة المستخدم</div>
            <div class="code-chip"><?= htmlspecialchars((string) $referralSummary['invite_code']) ?></div>
        </div>
        <div>
            <div class="field-hint">إجمالي أرباح الدعوات</div>
            <div class="code-chip">$<?= number_format((float) $referralSummary['rewards_usd'], 2) ?></div>
        </div>
    </div>
    <?php if ($referralSummary['recent_referrals'] === []): ?>
        <div class="muted-copy" style="margin-top:12px;">لا توجد دعوات لهذا المستخدم حتى الآن.</div>
    <?php else: ?>
        <div class="detail-grid" style="margin-top:12px;">
            <?php foreach ($referralSummary['recent_referrals'] as $referral): ?>
                <div class="attachment-card">
                    <div><strong><?= htmlspecialchars((string) ($referral['invited_name'] ?: 'صديق جديد')) ?></strong></div>
                    <div>الحالة: <?= htmlspecialchars((string) $referral['status']) ?></div>
                    <div>المكافأة: $<?= number_format((float) $referral['total_reward_usd'], 2) ?></div>
                    <div><?= htmlspecialchars((string) $referral['created_at']) ?></div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
    <div class="field-hint" style="margin-top:12px;">
        التحكم الكامل في النسب والسجلات من صفحة الدعوات والأرباح.
    </div>
</section>

<section class="panel">
    <h2 class="section-heading">اشتراكات VIP</h2>
    <?php if ($vipSubscriptions === []): ?>
        <div class="muted-copy">لا توجد اشتراكات VIP لهذا المستخدم حتى الآن.</div>
    <?php else: ?>
        <div class="detail-grid">
            <?php foreach ($vipSubscriptions as $subscription): ?>
                <div class="attachment-card">
                    <div><strong><?= htmlspecialchars((string) $subscription['tier_name']) ?></strong></div>
                    <div>المستوى: VIP <?= (int) ($subscription['tier_number'] ?? 0) ?></div>
                    <div>المصدر: <?= htmlspecialchars((string) ($subscription['source'] ?? 'self')) ?></div>
                    <div>الحالة: <?= htmlspecialchars((string) $subscription['status']) ?></div>
                    <div>من <?= htmlspecialchars((string) $subscription['started_at']) ?> إلى <?= htmlspecialchars((string) $subscription['expires_at']) ?></div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
    <div class="field-hint" style="margin-top:12px;">
        التفعيل والإرسال الحقيقي يتم من التطبيق، أما الأسعار والمميزات فتدار من صفحة مستويات VIP.
    </div>
</section>

<section class="panel">
    <h2 class="section-heading">الحساب والملف الشخصي</h2>
    <form method="post" class="form-grid">
        <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
        <input type="hidden" name="action" value="save_account">

        <label>
            الاسم
            <input type="text" name="nickname" value="<?= htmlspecialchars((string) ($user['nickname'] ?? '')) ?>">
        </label>
        <label>
            البريد الإلكتروني
            <input type="email" name="email" value="<?= htmlspecialchars((string) ($user['email'] ?? '')) ?>">
        </label>
        <label>
            الهاتف
            <input type="text" name="phone" value="<?= htmlspecialchars((string) ($user['phone'] ?? '')) ?>">
        </label>
        <label>
            الحالة
            <select name="status">
                <?php foreach ($statusOptions as $status): ?>
                    <option value="<?= $status ?>" <?= $user['status'] === $status ? 'selected' : '' ?>><?= $status === 'active' ? 'نشط' : 'موقوف' ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            الجنس
            <input type="text" name="gender" value="<?= htmlspecialchars((string) ($user['gender'] ?? '')) ?>" placeholder="male / female">
        </label>
        <label>
            الدولة
            <input type="text" name="country" value="<?= htmlspecialchars((string) ($user['country'] ?? 'Egypt')) ?>">
        </label>
        <label>
            عيد الميلاد
            <input type="date" name="birthdate" value="<?= htmlspecialchars((string) ($user['birthdate'] ?? '')) ?>">
        </label>
        <label>
            المعرف
            <input type="text" name="profile_handle" value="<?= htmlspecialchars((string) ($user['profile_handle'] ?? 'Shark.island')) ?>">
        </label>
        <label>
            الصورة المختارة
            <div class="media-stack">
                <?= admin_render_media_preview((string) ($user['avatar_asset'] ?? ''), (string) ($user['nickname'] ?? 'avatar'), 'media-thumb') ?>
                <input type="text" name="avatar_asset" list="avatar-options" value="<?= htmlspecialchars((string) ($user['avatar_asset'] ?? '')) ?>" placeholder="assets/... أو /storage/profile/...">
                <datalist id="avatar-options">
                    <?php foreach ($avatarOptions as $avatarOption): ?>
                        <option value="<?= htmlspecialchars($avatarOption) ?>"></option>
                    <?php endforeach; ?>
                </datalist>
            </div>
        </label>
        <label>
            دور الوكالة
            <select name="agency_role" <?= $user['agency_id'] === null ? 'disabled' : '' ?>>
                <option value="">بدون دور</option>
                <?php foreach ($agencyRoles as $role): ?>
                    <option value="<?= $role ?>" <?= (string) ($user['agency_role'] ?? '') === $role ? 'selected' : '' ?>>
                        <?= htmlspecialchars($role) ?>
                    </option>
                <?php endforeach; ?>
            </select>
        </label>
        <label class="span-2">
            التوقيع الشخصي
            <textarea name="signature_text" rows="4"><?= htmlspecialchars((string) ($user['signature_text'] ?? '')) ?></textarea>
        </label>
        <div class="checkbox-grid span-2">
            <label class="checkbox-card">
                <input type="checkbox" name="email_verified" value="1" <?= $user['email_verified_at'] ? 'checked' : '' ?>>
                <span>البريد موثق</span>
            </label>
            <label class="checkbox-card">
                <input type="checkbox" name="phone_verified" value="1" <?= $user['phone_verified_at'] ? 'checked' : '' ?>>
                <span>الهاتف موثق</span>
            </label>
        </div>
        <div class="action-row">
            <button type="submit" class="btn btn-primary">حفظ بيانات الحساب</button>
        </div>
    </form>
    <?php if ($user['agency_id'] !== null): ?>
        <form method="post" class="action-row" style="margin-top:12px;">
            <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
            <input type="hidden" name="action" value="clear_agency">
            <button type="submit" class="btn btn-ghost">فصل المستخدم عن الوكالة</button>
        </form>
    <?php endif; ?>
</section>

<section class="panel">
    <h2 class="section-heading">مؤشرات الملف الشخصي</h2>
    <form method="post" class="form-grid">
        <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
        <input type="hidden" name="action" value="save_stats">

        <label>
            عدد أتابع
            <input type="number" min="0" name="following_count" value="<?= (int) ($user['following_count'] ?? 0) ?>">
        </label>
        <label>
            عدد المتابعين
            <input type="number" min="0" name="followers_count" value="<?= (int) ($user['followers_count'] ?? 0) ?>">
        </label>
        <label>
            عدد الأصدقاء
            <input type="number" min="0" name="friends_count" value="<?= (int) ($user['friends_count'] ?? 0) ?>">
        </label>
        <label>
            المستوى الحالي
            <input type="number" min="0" name="level_current" value="<?= (int) ($user['level_current'] ?? 0) ?>">
        </label>
        <label>
            المستوى التالي
            <input type="number" min="1" name="level_next" value="<?= (int) ($user['level_next'] ?? 1) ?>">
        </label>
        <label>
            نسبة التقدم %
            <input type="number" min="0" max="100" name="level_progress_percent" value="<?= (int) ($user['level_progress_percent'] ?? 0) ?>">
        </label>
        <label>
            VIP
            <input type="text" name="vip_tier" value="<?= htmlspecialchars((string) ($user['vip_tier'] ?? 'VIP 0')) ?>">
        </label>
        <label>
            SVIP
            <input type="text" name="svip_tier" value="<?= htmlspecialchars((string) ($user['svip_tier'] ?? 'SVIP 0')) ?>">
        </label>
        <label>
            عدد الشارات
            <input type="number" min="0" name="badges_count" value="<?= (int) ($user['badges_count'] ?? 0) ?>">
        </label>
        <label>
            المهام المكتملة
            <input type="number" min="0" name="tasks_completed" value="<?= (int) ($user['tasks_completed'] ?? 0) ?>">
        </label>
        <label>
            إجمالي المهام
            <input type="number" min="1" name="tasks_total" value="<?= (int) ($user['tasks_total'] ?? 1) ?>">
        </label>
        <div class="action-row span-2">
            <button type="submit" class="btn btn-primary">حفظ المؤشرات</button>
        </div>
    </form>
</section>

<section class="panel">
    <h2 class="section-heading">إعدادات الحساب</h2>
    <form method="post" class="stack">
        <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
        <input type="hidden" name="action" value="save_settings">
        <div class="checkbox-grid">
            <label class="checkbox-card">
                <input type="checkbox" name="private_profile" value="1" <?= (int) $settings['private_profile'] === 1 ? 'checked' : '' ?>>
                <span>الملف الشخصي خاص</span>
            </label>
            <label class="checkbox-card">
                <input type="checkbox" name="allow_direct_messages" value="1" <?= (int) $settings['allow_direct_messages'] === 1 ? 'checked' : '' ?>>
                <span>السماح بالرسائل المباشرة</span>
            </label>
            <label class="checkbox-card">
                <input type="checkbox" name="show_online_status" value="1" <?= (int) $settings['show_online_status'] === 1 ? 'checked' : '' ?>>
                <span>إظهار حالة التواجد</span>
            </label>
            <label class="checkbox-card">
                <input type="checkbox" name="receive_chat_notifications" value="1" <?= (int) $settings['receive_chat_notifications'] === 1 ? 'checked' : '' ?>>
                <span>إشعارات المحادثات</span>
            </label>
            <label class="checkbox-card">
                <input type="checkbox" name="receive_live_notifications" value="1" <?= (int) $settings['receive_live_notifications'] === 1 ? 'checked' : '' ?>>
                <span>إشعارات اللايف</span>
            </label>
            <label class="checkbox-card">
                <input type="checkbox" name="receive_room_invites" value="1" <?= (int) $settings['receive_room_invites'] === 1 ? 'checked' : '' ?>>
                <span>دعوات الغرف الصوتية</span>
            </label>
            <label class="checkbox-card">
                <input type="checkbox" name="receive_party_invites" value="1" <?= (int) $settings['receive_party_invites'] === 1 ? 'checked' : '' ?>>
                <span>دعوات Party</span>
            </label>
            <label>
                اللغة المفضلة
                <select name="preferred_language">
                    <?php foreach ($languageOptions as $value => $label): ?>
                        <option value="<?= $value ?>" <?= (string) $settings['preferred_language'] === $value ? 'selected' : '' ?>><?= htmlspecialchars($label) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
        </div>
        <div class="action-row">
            <button type="submit" class="btn btn-primary">حفظ الإعدادات</button>
        </div>
    </form>
</section>

<section class="panel">
    <h2 class="section-heading">المحفظة والأمان</h2>
    <div class="detail-grid">
        <form method="post" class="stack">
            <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
            <input type="hidden" name="action" value="save_wallet">
            <label>
                رصيد الكوينز
                <input type="number" min="0" name="coins_balance" value="<?= (int) $wallet['coins_balance'] ?>">
            </label>
            <label>
                رصيد الماس
                <input type="number" min="0" name="diamonds_balance" value="<?= (int) $wallet['diamonds_balance'] ?>">
            </label>
            <div class="action-row">
                <button type="submit" class="btn btn-primary">حفظ الرصيد</button>
            </div>
        </form>
        <form method="post" class="stack">
            <input type="hidden" name="user_id" value="<?= (int) $user['id'] ?>">
            <input type="hidden" name="action" value="set_password">
            <label>
                كلمة مرور جديدة
                <input type="password" name="new_password" placeholder="6 أحرف على الأقل">
            </label>
            <div class="field-hint">سيتم استبدال كلمة المرور الحالية مباشرة.</div>
            <div class="action-row">
                <button type="submit" class="btn btn-secondary">تعيين كلمة مرور جديدة</button>
            </div>
        </form>
    </div>
</section>

<section class="panel">
    <h2 class="section-heading">الوكالة والطلبات</h2>
    <div class="detail-grid">
        <div>
            <div class="field-hint">الوكالة الحالية</div>
            <div class="code-chip"><?= htmlspecialchars((string) ($agency['name'] ?? 'لا يوجد وكالة مرتبطة')) ?></div>
            <?php if ($agency !== null): ?>
                <div class="muted-copy">كود الدعوة: <?= htmlspecialchars((string) $agency['invitation_code']) ?></div>
            <?php endif; ?>
        </div>
        <div>
            <div class="field-hint">طلبات فتح وكالة حديثة</div>
            <?php if ($openRequests === []): ?>
                <div class="muted-copy">لا توجد طلبات فتح وكالة لهذا المستخدم.</div>
            <?php else: ?>
                <?php foreach ($openRequests as $request): ?>
                    <div class="attachment-card" style="margin-bottom:10px;">
                        <div><strong><?= htmlspecialchars((string) $request['agency_name']) ?></strong></div>
                        <div><?= htmlspecialchars((string) $request['request_code']) ?></div>
                        <div><?= htmlspecialchars((string) $request['status']) ?> - <?= htmlspecialchars((string) $request['created_at']) ?></div>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>
        <div class="span-2">
            <div class="field-hint">طلبات الانضمام حديثة</div>
            <?php if ($joinRequests === []): ?>
                <div class="muted-copy">لا توجد طلبات انضمام لهذا المستخدم.</div>
            <?php else: ?>
                <div class="detail-grid">
                    <?php foreach ($joinRequests as $request): ?>
                        <div class="attachment-card">
                            <div><strong><?= htmlspecialchars((string) ($request['agency_name_snapshot'] ?: 'بدون اسم وكالة')) ?></strong></div>
                            <div>الرمز: <?= htmlspecialchars((string) $request['invitation_code']) ?></div>
                            <div><?= htmlspecialchars((string) $request['request_code']) ?></div>
                            <div><?= htmlspecialchars((string) $request['status']) ?> - <?= htmlspecialchars((string) $request['created_at']) ?></div>
                        </div>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>
        </div>
    </div>
</section>
<?php admin_render_footer(); ?>
