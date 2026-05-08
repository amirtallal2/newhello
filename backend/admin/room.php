<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/RoomRtcService.php';
require_once __DIR__ . '/../src/RoomMusicService.php';
require_once __DIR__ . '/../src/RoomService.php';

admin_require_auth();
$pdo = admin_pdo();
$roomRtcService = new RoomRtcService($pdo, $config);
$roomMusicService = new RoomMusicService($pdo);
$roomService = new RoomService($pdo);
$roomId = (int) ($_GET['id'] ?? 0);
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? '');

        if ($action === 'save_room') {
            $roomService->updateRoomAdmin(
                $roomId,
                trim((string) ($_POST['card_title'] ?? '')),
                trim((string) ($_POST['room_title'] ?? '')),
                trim((string) ($_POST['subtitle'] ?? '')),
                trim((string) ($_POST['room_type'] ?? '')),
                trim((string) ($_POST['slogan_text'] ?? '')),
                trim((string) ($_POST['country_label'] ?? '')),
                trim((string) ($_POST['host_name'] ?? '')),
                trim((string) ($_POST['room_code'] ?? '')),
                trim((string) ($_POST['card_image_asset'] ?? '')),
                trim((string) ($_POST['meta_icon_asset'] ?? '')),
                trim((string) ($_POST['background_asset'] ?? '')),
                (int) ($_POST['listener_count'] ?? 0),
                (int) ($_POST['mic_count'] ?? 9),
                (string) ($_POST['status'] ?? 'active')
            );
            if ((string) ($_POST['status'] ?? 'active') === 'hidden') {
                $roomRtcService->adminCloseRoomAudio($roomId);
            }
            $flash = 'تم حفظ بيانات الغرفة.';
        }

        if ($action === 'save_audio_settings') {
            $hostUserId = trim((string) ($_POST['host_user_id'] ?? ''));
            $roomRtcService->adminUpdateRoomAudioSettings(
                $roomId,
                isset($_POST['audio_enabled']),
                $hostUserId === '' ? null : (int) $hostUserId,
                trim((string) ($_POST['agora_channel_name'] ?? ''))
            );
            $flash = 'تم حفظ إعدادات الغرفة الصوتية.';
        }

        if (in_array($action, ['approve_request', 'reject_request'], true)) {
            $requestId = (int) ($_POST['request_id'] ?? 0);
            if ($action === 'approve_request') {
                $roomService->approveSeatRequest($roomId, $requestId);
                $flash = 'تمت الموافقة على طلب المايك.';
            } else {
                $roomService->rejectSeatRequest($roomId, $requestId);
                $flash = 'تم رفض طلب المايك.';
            }
        }

        if ($action === 'remove_music_entry') {
            $roomMusicService->adminRemoveRoomPlaylistEntry(
                $roomId,
                (int) ($_POST['entry_id'] ?? 0)
            );
            $flash = 'تمت إزالة المقطع من قائمة التشغيل.';
        }

        if ($action === 'save_audio_participant') {
            $roomRtcService->adminUpdateParticipant(
                $roomId,
                (int) ($_POST['participant_id'] ?? 0),
                (string) ($_POST['participant_role'] ?? 'listener'),
                ($_POST['seat_number'] ?? '') === '' ? null : (int) $_POST['seat_number'],
                isset($_POST['mic_muted'])
            );
            $flash = 'تم تحديث المشارك الصوتي.';
        }

        if ($action === 'kick_audio_participant') {
            $roomRtcService->adminKickParticipant(
                $roomId,
                (int) ($_POST['participant_id'] ?? 0)
            );
            $flash = 'تم طرد المشارك من الغرفة الصوتية.';
        }
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$roomRtcService->refreshAudioPresence($roomId);
$room = $roomService->getRoom($roomId);
$requests = $roomService->listSeatRequests($roomId);
$playlistEntries = $roomMusicService->adminRoomPlaylist($roomId);
$audioParticipants = $roomRtcService->listParticipants($roomId);
$audioConfiguration = $roomRtcService->configurationStatus();

admin_render_header('تفاصيل الغرفة', 'rooms');
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
    <div class="panel-title">المعاينة السريعة</div>
    <div class="metric-grid">
        <div class="metric-card">
            <div class="metric-title">صورة الغرفة</div>
            <div class="metric-copy"><?= admin_render_media_preview((string) ($room['card_image_asset'] ?? ''), (string) ($room['room_title'] ?? 'room'), 'media-thumb') ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">أيقونة البلد</div>
            <div class="metric-copy"><?= admin_render_media_preview((string) ($room['meta_icon_asset'] ?? ''), (string) ($room['country_label'] ?? 'country'), 'media-thumb') ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">خلفية الغرفة</div>
            <div class="metric-copy"><?= admin_render_media_preview((string) ($room['background_asset'] ?? ''), (string) ($room['room_title'] ?? 'background'), 'media-thumb') ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">منشئ الغرفة</div>
            <div class="metric-copy"><?= $room['creator_user_id'] === null ? 'غير محدد' : '#' . (int) $room['creator_user_id'] ?></div>
        </div>
    </div>
</section>

<section class="panel">
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="save_room">
        <label>
            <span>عنوان الكارت</span>
            <input type="text" name="card_title" value="<?= htmlspecialchars((string) $room['card_title']) ?>" required>
        </label>
        <label>
            <span>عنوان الغرفة</span>
            <input type="text" name="room_title" value="<?= htmlspecialchars((string) $room['room_title']) ?>" required>
        </label>
        <label>
            <span>الوصف</span>
            <input type="text" name="subtitle" value="<?= htmlspecialchars((string) $room['subtitle']) ?>">
        </label>
        <label>
            <span>نوع الغرفة</span>
            <select name="room_type">
                <?php foreach (['دردشة', 'غناء', 'حب', 'عائلة', 'مزيكا'] as $roomType): ?>
                    <option value="<?= htmlspecialchars($roomType) ?>" <?= (string) ($room['room_type'] ?? 'غناء') === $roomType ? 'selected' : '' ?>><?= htmlspecialchars($roomType) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>شعار الغرفة</span>
            <input type="text" name="slogan_text" value="<?= htmlspecialchars((string) ($room['slogan_text'] ?? '')) ?>">
        </label>
        <label>
            <span>البلد</span>
            <input type="text" name="country_label" value="<?= htmlspecialchars((string) ($room['country_label'] ?? 'مصر')) ?>" required>
        </label>
        <label>
            <span>المضيف</span>
            <input type="text" name="host_name" value="<?= htmlspecialchars((string) $room['host_name']) ?>" required>
        </label>
        <label>
            <span>كود الغرفة</span>
            <input type="text" name="room_code" value="<?= htmlspecialchars((string) $room['room_code']) ?>" required>
        </label>
        <label>
            <span>مسار صورة الغرفة</span>
            <input type="text" name="card_image_asset" value="<?= htmlspecialchars((string) ($room['card_image_asset'] ?? '')) ?>" required>
        </label>
        <label>
            <span>مسار أيقونة البلد</span>
            <input type="text" name="meta_icon_asset" value="<?= htmlspecialchars((string) ($room['meta_icon_asset'] ?? '')) ?>" required>
        </label>
        <label>
            <span>مسار الخلفية</span>
            <input type="text" name="background_asset" value="<?= htmlspecialchars((string) ($room['background_asset'] ?? '')) ?>" required>
        </label>
        <label>
            <span>المستمعون</span>
            <input type="number" name="listener_count" value="<?= (int) $room['listener_count'] ?>" min="0">
        </label>
        <label>
            <span>عدد المايكات</span>
            <select name="mic_count">
                <?php foreach ([5, 9, 12, 15] as $micCount): ?>
                    <option value="<?= $micCount ?>" <?= (int) $room['mic_count'] === $micCount ? 'selected' : '' ?>><?= $micCount ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>الحالة</span>
            <select name="status">
                <option value="active" <?= $room['status'] === 'active' ? 'selected' : '' ?>>نشطة</option>
                <option value="hidden" <?= $room['status'] === 'hidden' ? 'selected' : '' ?>>مخفية</option>
            </select>
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">حفظ الغرفة</button>
            <a class="btn btn-secondary" href="/admin/rooms.php">رجوع</a>
        </div>
    </form>
</section>

<section class="panel">
    <div class="panel-title">إعدادات Agora والصوت المباشر</div>
    <?php if (!$audioConfiguration['configured']): ?>
        <p class="pill pill-warning">Agora غير مهيأة على السيرفر بعد. ضع `AGORA_APP_ID` و`AGORA_APP_CERTIFICATE` داخل `backend/config/runtime.php`.</p>
    <?php endif; ?>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="save_audio_settings">
        <label>
            <span>تفعيل الغرفة الصوتية</span>
            <input type="checkbox" name="audio_enabled" value="1" <?= !empty($room['audio_enabled']) ? 'checked' : '' ?>>
        </label>
        <label>
            <span>Agora Channel Name</span>
            <input type="text" name="agora_channel_name" value="<?= htmlspecialchars((string) ($room['agora_channel_name'] ?? '')) ?>" placeholder="voice-room-1512345412">
            <div class="field-hint">اتركه فارغًا ليتم توليد اسم افتراضي من كود الغرفة.</div>
        </label>
        <label>
            <span>Host User ID</span>
            <input type="number" name="host_user_id" value="<?= htmlspecialchars($room['host_user_id'] === null ? '' : (string) $room['host_user_id']) ?>" min="1" placeholder="مثال: 3">
            <div class="field-hint">إذا تم إدخال مستخدم صحيح، سيتم تحديث اسم وصورة المضيف تلقائيًا من بياناته.</div>
        </label>
        <div class="metric-grid span-2">
            <div class="metric-card">
                <div class="metric-title">حالة Agora</div>
                <div class="metric-copy"><?= $audioConfiguration['configured'] ? 'Configured' : 'Missing App ID' ?></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">التوكن</div>
                <div class="metric-copy"><?= $audioConfiguration['uses_tokens'] ? 'Enabled' : 'Testing mode' ?></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">مدة التوكن</div>
                <div class="metric-copy"><?= (int) $audioConfiguration['token_expires_in_seconds'] ?>s</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">المشاركون الآن</div>
                <div class="metric-copy"><?= count($audioParticipants) ?></div>
            </div>
        </div>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">حفظ إعدادات الصوت</button>
        </div>
    </form>
</section>

<section class="panel table-panel">
    <div class="panel-title">المشاركون الصوتيون الحاليون</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>الصورة</th>
                <th>الاسم</th>
                <th>الحساب</th>
                <th>الدور الحالي</th>
                <th>المقعد الحالي</th>
                <th>حالة المايك</th>
                <th>آخر نبضة</th>
                <th>إجراءات</th>
            </tr>
        </thead>
        <tbody>
        <?php if ($audioParticipants === []): ?>
            <tr>
                <td colspan="9">لا يوجد مشاركون متصلون الآن.</td>
            </tr>
        <?php else: ?>
            <?php foreach ($audioParticipants as $participant): ?>
                <tr>
                    <td>#<?= (int) $participant['id'] ?></td>
                    <td><?= admin_render_media_preview((string) $participant['avatar_asset'], (string) $participant['display_name']) ?></td>
                    <td><?= htmlspecialchars((string) $participant['display_name']) ?></td>
                    <td><span class="code-chip"><?= htmlspecialchars((string) $participant['user_account']) ?></span></td>
                    <td><?= htmlspecialchars((string) $participant['role']) ?></td>
                    <td><?= $participant['seat_number'] === null ? '-' : (int) $participant['seat_number'] ?></td>
                    <td>
                        <span class="pill <?= !empty($participant['mic_muted']) ? 'pill-danger' : 'pill-success' ?>">
                            <?= !empty($participant['mic_muted']) ? 'Muted' : 'Open' ?>
                        </span>
                    </td>
                    <td><?= htmlspecialchars((string) $participant['last_seen_at']) ?></td>
                    <td>
                        <div class="inline-actions">
                            <form method="post" class="inline-actions">
                                <input type="hidden" name="action" value="save_audio_participant">
                                <input type="hidden" name="participant_id" value="<?= (int) $participant['id'] ?>">
                                <select name="participant_role">
                                    <option value="host" <?= $participant['role'] === 'host' ? 'selected' : '' ?>>Host</option>
                                    <option value="speaker" <?= $participant['role'] === 'speaker' ? 'selected' : '' ?>>Speaker</option>
                                    <option value="listener" <?= $participant['role'] === 'listener' ? 'selected' : '' ?>>Listener</option>
                                </select>
                                <input type="number" name="seat_number" value="<?= $participant['seat_number'] === null ? '' : (int) $participant['seat_number'] ?>" min="1" max="15" placeholder="Seat">
                                <label class="checkbox-card">
                                    <input type="checkbox" name="mic_muted" value="1" <?= !empty($participant['mic_muted']) ? 'checked' : '' ?>>
                                    <span>كتم</span>
                                </label>
                                <button class="btn btn-primary" type="submit">حفظ</button>
                            </form>
                            <form method="post">
                                <input type="hidden" name="action" value="kick_audio_participant">
                                <input type="hidden" name="participant_id" value="<?= (int) $participant['id'] ?>">
                                <button class="btn btn-danger" type="submit">طرد</button>
                            </form>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">قائمة الموسيقى الحالية</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>العنوان</th>
                <th>الفنان</th>
                <th>المصدر</th>
                <th>المدة</th>
                <th>أضافه</th>
                <th>إزالة</th>
            </tr>
        </thead>
        <tbody>
        <?php if ($playlistEntries === []): ?>
            <tr>
                <td colspan="7">لا توجد موسيقى مضافة لهذه الغرفة.</td>
            </tr>
        <?php else: ?>
            <?php foreach ($playlistEntries as $entry): ?>
                <tr>
                    <td>#<?= (int) $entry['id'] ?></td>
                    <td><?= htmlspecialchars((string) $entry['title']) ?></td>
                    <td><?= htmlspecialchars((string) $entry['artist_name']) ?></td>
                    <td><?= $entry['source_type'] === 'friends' ? 'الاصدقاء' : 'واتساب' ?></td>
                    <td><?= (int) $entry['duration_seconds'] ?> ثانية</td>
                    <td><?= htmlspecialchars((string) $entry['added_by_name']) ?></td>
                    <td>
                        <form method="post">
                            <input type="hidden" name="action" value="remove_music_entry">
                            <input type="hidden" name="entry_id" value="<?= (int) $entry['id'] ?>">
                            <button class="btn btn-secondary" type="submit">إزالة</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">طلبات المايك المعلقة</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>الصورة</th>
                <th>الاسم</th>
                <th>المقعد</th>
                <th>الوقت</th>
                <th>إجراءات</th>
            </tr>
        </thead>
        <tbody>
        <?php if ($requests === []): ?>
            <tr>
                <td colspan="5">لا توجد طلبات مايك معلقة.</td>
            </tr>
        <?php else: ?>
            <?php foreach ($requests as $request): ?>
                <tr>
                    <td>#<?= (int) $request['id'] ?></td>
                    <td><?= admin_render_media_preview((string) ($request['requester_avatar_asset'] ?? ''), (string) $request['requester_name']) ?></td>
                    <td><?= htmlspecialchars((string) $request['requester_name']) ?></td>
                    <td><?= (int) $request['seat_number'] ?></td>
                    <td><?= htmlspecialchars((string) $request['created_at']) ?></td>
                    <td>
                        <div class="inline-actions">
                            <form method="post">
                                <input type="hidden" name="action" value="approve_request">
                                <input type="hidden" name="request_id" value="<?= (int) $request['id'] ?>">
                                <button class="btn btn-primary" type="submit">موافقة</button>
                            </form>
                            <form method="post">
                                <input type="hidden" name="action" value="reject_request">
                                <input type="hidden" name="request_id" value="<?= (int) $request['id'] ?>">
                                <button class="btn btn-secondary" type="submit">رفض</button>
                            </form>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
