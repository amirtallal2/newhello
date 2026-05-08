<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/PostService.php';

admin_require_auth();
$pdo = admin_pdo();
$postService = new PostService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$status = (string) ($_GET['status'] ?? 'all');
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $postService->adminUpdatePost(
            (int) ($_POST['post_id'] ?? 0),
            trim((string) ($_POST['body_text'] ?? '')),
            trim((string) ($_POST['image_path'] ?? '')),
            (string) ($_POST['status'] ?? 'active')
        );
        $flash = 'تم تحديث بيانات البوست.';
    }
} catch (Throwable $exception) {
    $error = $exception->getMessage();
}

$posts = $postService->adminListPosts($search, $status);

admin_render_header('إدارة البوستات', 'posts');
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
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم الكاتب أو نص البوست">
        <select name="status">
            <option value="all" <?= $status === 'all' ? 'selected' : '' ?>>كل الحالات</option>
            <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>نشط</option>
            <option value="hidden" <?= $status === 'hidden' ? 'selected' : '' ?>>مخفي</option>
        </select>
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>الكاتب</th>
            <th>المحتوى</th>
            <th>الإحصائيات</th>
            <th>الحالة</th>
            <th>التاريخ</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($posts as $post): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="post_id" value="<?= (int) $post['id'] ?>">
                    <td>#<?= (int) $post['id'] ?></td>
                    <td><?= htmlspecialchars((string) $post['author_name']) ?></td>
                    <td>
                        <textarea name="body_text" rows="4"><?= htmlspecialchars((string) $post['body_text']) ?></textarea>
                        <div class="media-stack">
                            <?= admin_render_media_preview((string) ($post['image_path'] ?? ''), 'post-image') ?>
                            <input type="text" name="image_path" value="<?= htmlspecialchars((string) ($post['image_path'] ?? '')) ?>" placeholder="مسار صورة البوست">
                        </div>
                    </td>
                    <td>
                        <div>Likes: <?= (int) $post['like_count'] ?></div>
                        <div>Comments: <?= (int) $post['comment_count'] ?></div>
                        <div>Reports: <?= (int) $post['report_count'] ?></div>
                    </td>
                    <td>
                        <select name="status">
                            <option value="active" <?= $post['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                            <option value="hidden" <?= $post['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
                        </select>
                    </td>
                    <td><?= htmlspecialchars((string) $post['created_at']) ?></td>
                    <td><button class="btn btn-primary" type="submit">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
