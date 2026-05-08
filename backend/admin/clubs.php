<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/ClubService.php';

admin_require_auth();
$pdo = admin_pdo();
$clubService = new ClubService($pdo);
$search = trim((string) ($_GET['search'] ?? $_POST['search'] ?? ''));
$error = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $clubId = (int) ($_POST['club_id'] ?? 0);

    try {
        if ($clubId > 0) {
            $clubService->adminUpdateClub(
                $clubId,
                (string) ($_POST['name'] ?? ''),
                (string) ($_POST['code'] ?? ''),
                (string) ($_POST['announcement_text'] ?? ''),
                (string) ($_POST['avatar_asset'] ?? ''),
                (int) ($_POST['ranking_points'] ?? 0),
                (string) ($_POST['status'] ?? 'active')
            );
        }

        admin_redirect('/admin/clubs.php' . ($search !== '' ? '?search=' . urlencode($search) : ''));
    } catch (Throwable $throwable) {
        $error = $throwable->getMessage();
    }
}

$clubs = $clubService->adminListClubs($search);
$stats = $clubService->adminStats();

admin_render_header('إدارة النوادي', 'clubs');
?>
<?php if ($error !== null): ?>
    <section class="panel">
        <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
    </section>
<?php endif; ?>

<section class="stats-grid">
    <article class="stat-card">
        <span>كل النوادي</span>
        <strong><?= (int) $stats['clubs'] ?></strong>
    </article>
    <article class="stat-card">
        <span>النوادي النشطة</span>
        <strong><?= (int) $stats['active_clubs'] ?></strong>
    </article>
    <article class="stat-card">
        <span>الأعضاء</span>
        <strong><?= (int) $stats['club_members'] ?></strong>
    </article>
    <article class="stat-card">
        <span>منشورات النوادي</span>
        <strong><?= (int) $stats['club_posts'] ?></strong>
    </article>
</section>

<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم النادي أو الرمز أو المالك">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>الصورة</th>
                <th>النادي</th>
                <th>الرمز</th>
                <th>المالك</th>
                <th>الأعضاء</th>
                <th>الغرف</th>
                <th>النقاط</th>
                <th>المنشورات</th>
                <th>الحالة</th>
                <th>تعديل سريع</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($clubs as $club): ?>
            <tr>
                <td>#<?= (int) $club['id'] ?></td>
                <td><?= admin_render_media_preview((string) ($club['avatar_asset'] ?? ''), (string) ($club['name'] ?? 'club')) ?></td>
                <td>
                    <strong><?= htmlspecialchars((string) $club['name']) ?></strong>
                    <small><?= htmlspecialchars((string) ($club['announcement_text'] ?? '')) ?></small>
                </td>
                <td><?= htmlspecialchars((string) $club['code']) ?></td>
                <td><?= htmlspecialchars((string) (($club['owner_nickname'] ?? '') ?: ($club['owner_email'] ?? 'Hallo Party'))) ?></td>
                <td><?= (int) $club['members_count'] ?></td>
                <td><?= (int) $club['rooms_count'] ?></td>
                <td><?= (int) $club['ranking_points'] ?></td>
                <td><?= (int) ($club['posts_count'] ?? 0) ?></td>
                <td>
                    <span class="pill <?= $club['status'] === 'active' ? 'pill-success' : 'pill-danger' ?>">
                        <?= $club['status'] === 'active' ? 'نشط' : 'مخفي' ?>
                    </span>
                </td>
                <td>
                    <form method="post" class="stacked-form">
                        <input type="hidden" name="club_id" value="<?= (int) $club['id'] ?>">
                        <input type="hidden" name="search" value="<?= htmlspecialchars($search) ?>">
                        <input type="text" name="name" value="<?= htmlspecialchars((string) $club['name']) ?>" placeholder="اسم النادي">
                        <input type="text" name="code" value="<?= htmlspecialchars((string) $club['code']) ?>" placeholder="رمز النادي">
                        <input type="text" name="avatar_asset" value="<?= htmlspecialchars((string) ($club['avatar_asset'] ?? '')) ?>" placeholder="رابط الصورة أو مسارها">
                        <textarea name="announcement_text" rows="2" placeholder="إعلان النادي"><?= htmlspecialchars((string) ($club['announcement_text'] ?? '')) ?></textarea>
                        <input type="number" name="ranking_points" value="<?= (int) $club['ranking_points'] ?>" min="0">
                        <select name="status">
                            <option value="active" <?= $club['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                            <option value="hidden" <?= $club['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
                        </select>
                        <button class="btn btn-primary" type="submit">حفظ</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
