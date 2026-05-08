<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/RoomGameService.php';

admin_require_auth();
$pdo = admin_pdo();
$roomGameService = new RoomGameService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $roomGameService->adminUpdateGame(
            (int) ($_POST['game_id'] ?? 0),
            (string) ($_POST['name'] ?? ''),
            (string) ($_POST['category_key'] ?? 'luck'),
            max(1, (int) ($_POST['min_players'] ?? 1)),
            max(1, (int) ($_POST['max_players'] ?? 4)),
            (string) ($_POST['status'] ?? 'active'),
            max(0, (int) ($_POST['display_order'] ?? 0)),
        );
        $flash = 'تم تحديث بيانات اللعبة.';
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$games = $roomGameService->adminListGames($search);

admin_render_header('ألعاب الغرف', 'room-games');
?>
<?php if ($flash !== null): ?>
    <section class="panel">
        <div class="pill pill-success"><?= htmlspecialchars($flash) ?></div>
    </section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel">
        <div class="pill pill-danger"><?= htmlspecialchars($error) ?></div>
    </section>
<?php endif; ?>

<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم اللعبة أو المفتاح">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>الأيقونة</th>
            <th>الاسم</th>
            <th>الفئة</th>
            <th>اللاعبون</th>
            <th>الحالة</th>
            <th>الترتيب</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($games as $game): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="game_id" value="<?= (int) $game['id'] ?>">
                    <td>#<?= (int) $game['id'] ?><div class="muted-copy"><?= htmlspecialchars((string) $game['game_key']) ?></div></td>
                    <td><?= htmlspecialchars((string) $game['icon_asset']) ?></td>
                    <td>
                        <input type="text" name="name" value="<?= htmlspecialchars((string) $game['name']) ?>">
                        <div class="muted-copy"><?= htmlspecialchars((string) $game['description_text']) ?></div>
                    </td>
                    <td>
                        <select name="category_key">
                            <option value="luck" <?= (string) $game['category_key'] === 'luck' ? 'selected' : '' ?>>العاب الحظ</option>
                            <option value="board" <?= (string) $game['category_key'] === 'board' ? 'selected' : '' ?>>العاب اللوح</option>
                        </select>
                    </td>
                    <td>
                        <div class="stack">
                            <input type="number" min="1" name="min_players" value="<?= (int) $game['min_players'] ?>">
                            <input type="number" min="1" name="max_players" value="<?= (int) $game['max_players'] ?>">
                        </div>
                    </td>
                    <td>
                        <select name="status">
                            <option value="active" <?= (string) $game['status'] === 'active' ? 'selected' : '' ?>>نشطة</option>
                            <option value="hidden" <?= (string) $game['status'] === 'hidden' ? 'selected' : '' ?>>مخفية</option>
                        </select>
                    </td>
                    <td><input type="number" min="0" name="display_order" value="<?= (int) $game['display_order'] ?>"></td>
                    <td><button class="btn btn-primary" type="submit">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
