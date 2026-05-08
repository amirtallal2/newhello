<?php

declare(strict_types=1);

$config = require __DIR__ . '/../config/app.php';

require_once __DIR__ . '/../src/Database.php';
require_once __DIR__ . '/../src/AgencyService.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/Response.php';
require_once __DIR__ . '/../src/TokenManager.php';
require_once __DIR__ . '/../src/AuthService.php';
require_once __DIR__ . '/../src/SocialService.php';
require_once __DIR__ . '/../src/ChatService.php';
require_once __DIR__ . '/../src/ClubService.php';
require_once __DIR__ . '/../src/EconomyService.php';
require_once __DIR__ . '/../src/GiftService.php';
require_once __DIR__ . '/../src/GoogleIdTokenVerifier.php';
require_once __DIR__ . '/../src/LevelService.php';
require_once __DIR__ . '/../src/ReferralService.php';
require_once __DIR__ . '/../src/LiveService.php';
require_once __DIR__ . '/../src/AgoraTokenBuilder.php';
require_once __DIR__ . '/../src/PostService.php';
require_once __DIR__ . '/../src/ProfileService.php';
require_once __DIR__ . '/../src/RoomGameService.php';
require_once __DIR__ . '/../src/RoomRtcService.php';
require_once __DIR__ . '/../src/RoomService.php';
require_once __DIR__ . '/../src/RoomMusicService.php';
require_once __DIR__ . '/../src/SupportService.php';

Response::cors();

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    Response::json(['success' => true], 200);
}

$pdo = Database::connection($config['db']);
$agencyService = new AgencyService($pdo);
$authService = new AuthService($pdo, $config);
$socialService = new SocialService($pdo);
$chatService = new ChatService($pdo);
$clubService = new ClubService($pdo);
$economyService = new EconomyService($pdo);
$giftService = new GiftService($pdo);
$liveService = new LiveService($pdo, $config);
$postService = new PostService($pdo);
$profileService = new ProfileService($pdo);
$roomGameService = new RoomGameService($pdo);
$roomRtcService = new RoomRtcService($pdo, $config);
$roomService = new RoomService($pdo);
$roomMusicService = new RoomMusicService($pdo);
$supportService = new SupportService($pdo);
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';
$path = preg_replace('#^' . preg_quote($config['api_base_path'], '#') . '#', '', $path) ?: '/';
$method = $_SERVER['REQUEST_METHOD'];

try {
    $payload = Response::readJson();

    if ($method === 'GET' && ($path === '/' || $path === '')) {
        Response::json([
            'success' => true,
            'message' => 'HalloParty API is running.',
            'data' => [
                'app' => $config['app_name'],
                'status' => 'ok',
                'timestamp' => gmdate('c'),
            ],
        ]);
    }

    if ($method === 'GET' && $path === '/health') {
        Response::json([
            'success' => true,
            'message' => 'Health check passed.',
            'data' => [
                'status' => 'ok',
                'database_driver' => $config['db']['driver'],
                'timestamp' => gmdate('c'),
            ],
        ]);
    }

    if ($method === 'POST' && $path === '/auth/register') {
        $data = $authService->register(
            (string) ($payload['email'] ?? ''),
            (string) ($payload['password'] ?? ''),
            (string) ($payload['referral_code'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Registration created successfully.',
            'data' => $data,
        ], 201);
    }

    if ($method === 'POST' && $path === '/auth/email/resend') {
        $data = $authService->resendEmailVerification(
            (string) ($payload['registration_token'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Verification email resent.',
            'data' => $data,
        ]);
    }

    if ($method === 'POST' && $path === '/auth/email/verify') {
        $data = $authService->verifyEmail(
            (string) ($payload['registration_token'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Email verified successfully.',
            'data' => $data,
        ]);
    }

    if ($method === 'POST' && $path === '/auth/identity') {
        $data = $authService->completeIdentity(
            (string) ($payload['registration_token'] ?? ''),
            (string) ($payload['nickname'] ?? ''),
            (string) ($payload['phone'] ?? ''),
            (string) ($payload['birthdate'] ?? ''),
            (string) ($payload['gender'] ?? ''),
            (string) ($payload['country'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Identity saved successfully.',
            'data' => $data,
        ]);
    }

    if ($method === 'POST' && $path === '/auth/phone/verify') {
        $data = $authService->verifyPhoneOtp(
            (string) ($payload['registration_token'] ?? ''),
            (string) ($payload['otp'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Phone verified successfully.',
            'data' => $data,
        ]);
    }

    if ($method === 'POST' && $path === '/auth/login/email') {
        $data = $authService->loginByEmail(
            (string) ($payload['email'] ?? ''),
            (string) ($payload['password'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Logged in successfully.',
            'data' => $data,
        ]);
    }

    if ($method === 'POST' && $path === '/auth/login/phone') {
        $data = $authService->loginByPhone(
            (string) ($payload['phone'] ?? ''),
            (string) ($payload['password'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Logged in successfully.',
            'data' => $data,
        ]);
    }

    if ($method === 'POST' && $path === '/auth/login/google') {
        $data = $authService->loginByGoogle(
            (string) ($payload['id_token'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Logged in with Google successfully.',
            'data' => $data,
        ]);
    }

    if ($method === 'POST' && $path === '/auth/password/forgot') {
        $data = $authService->forgotPassword(
            (string) ($payload['email'] ?? '')
        );
        Response::json([
            'success' => true,
            'message' => 'Password reset request created.',
            'data' => $data,
        ]);
    }

    if ($method === 'POST' && $path === '/auth/password/reset') {
        $password = (string) ($payload['password'] ?? '');
        $confirmation = (string) ($payload['password_confirmation'] ?? '');

        if ($password !== $confirmation) {
            throw new ApiException('Password confirmation does not match.');
        }

        $authService->resetPassword(
            (string) ($payload['reset_token'] ?? ''),
            $password
        );

        Response::json([
            'success' => true,
            'message' => 'Password reset successfully.',
            'data' => null,
        ]);
    }

    if ($method === 'GET' && $path === '/auth/me') {
        $data = $authService->me($_SERVER['HTTP_AUTHORIZATION'] ?? null);
        Response::json([
            'success' => true,
            'message' => 'User loaded successfully.',
            'data' => $data,
        ]);
    }

    if ($method === 'GET' && $path === '/profile/summary') {
        Response::json([
            'success' => true,
            'message' => 'Profile summary loaded successfully.',
            'data' => $profileService->summary($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'GET' && preg_match('#^/profile/users/(\d+)/summary$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Public profile summary loaded successfully.',
            'data' => $profileService->publicSummary(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/profile') {
        Response::json([
            'success' => true,
            'message' => 'Profile updated successfully.',
            'data' => $profileService->updateProfile(
                $_SERVER['HTTP_AUTHORIZATION'] ?? null,
                (string) ($payload['nickname'] ?? ''),
                isset($payload['email']) ? (string) $payload['email'] : null,
                isset($payload['phone']) ? (string) $payload['phone'] : null,
                isset($payload['birthdate']) ? (string) $payload['birthdate'] : null,
                isset($payload['gender']) ? (string) $payload['gender'] : null,
                (string) ($payload['country'] ?? ''),
                (string) ($payload['signature_text'] ?? ''),
                (string) ($payload['profile_handle'] ?? ''),
                isset($payload['avatar_asset']) ? (string) $payload['avatar_asset'] : null,
                is_array($payload['avatar_upload'] ?? null) ? $payload['avatar_upload'] : null,
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/profile/settings') {
        Response::json([
            'success' => true,
            'message' => 'Profile settings updated successfully.',
            'data' => $profileService->updateSettings(
                $_SERVER['HTTP_AUTHORIZATION'] ?? null,
                is_array($payload) ? $payload : [],
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/profile/password') {
        $newPassword = (string) ($payload['new_password'] ?? '');
        $confirmation = (string) ($payload['confirm_password'] ?? '');

        if ($newPassword !== $confirmation) {
            throw new ApiException('Password confirmation does not match.', 422);
        }

        $profileService->changePassword(
            $_SERVER['HTTP_AUTHORIZATION'] ?? null,
            (string) ($payload['current_password'] ?? ''),
            $newPassword,
        );

        Response::json([
            'success' => true,
            'message' => 'Password updated successfully.',
            'data' => null,
        ]);
    }

    if ($method === 'GET' && $path === '/social/connections') {
        Response::json([
            'success' => true,
            'message' => 'Social connections loaded successfully.',
            'data' => $socialService->listConnections(
                (string) ($_GET['type'] ?? 'following'),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null,
                isset($_GET['user_id']) ? (int) $_GET['user_id'] : null
            ),
        ]);
    }

    if ($method === 'GET' && $path === '/social/search') {
        Response::json([
            'success' => true,
            'message' => 'Social users loaded successfully.',
            'data' => $socialService->searchUsers(
                trim((string) ($_GET['query'] ?? '')),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && preg_match('#^/social/users/(\d+)/relationship$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Social relationship loaded successfully.',
            'data' => $socialService->relationship(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/social/users/(\d+)/follow$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'User followed successfully.',
            'data' => $socialService->follow(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/social/users/(\d+)/unfollow$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'User unfollowed successfully.',
            'data' => $socialService->unfollow(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/social/users/(\d+)/follow-toggle$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Follow status updated successfully.',
            'data' => $socialService->toggleFollow(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && $path === '/clubs') {
        Response::json([
            'success' => true,
            'message' => 'Clubs loaded successfully.',
            'data' => $clubService->listClubs(
                (string) ($_GET['scope'] ?? 'trending'),
                trim((string) ($_GET['query'] ?? '')),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/clubs') {
        Response::json([
            'success' => true,
            'message' => 'Club created successfully.',
            'data' => $clubService->createClub(
                (string) ($payload['name'] ?? ''),
                (string) ($payload['code'] ?? ''),
                (string) ($payload['announcement_text'] ?? ''),
                isset($payload['avatar_asset']) ? (string) $payload['avatar_asset'] : null,
                is_array($payload['avatar_upload'] ?? null) ? $payload['avatar_upload'] : null,
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && preg_match('#^/clubs/(\d+)$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Club loaded successfully.',
            'data' => $clubService->detail(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/clubs/(\d+)/join$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Joined club successfully.',
            'data' => $clubService->joinClub(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/clubs/(\d+)/leave$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Left club successfully.',
            'data' => $clubService->leaveClub(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/clubs/(\d+)/posts$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Club post created successfully.',
            'data' => $clubService->createPost(
                (int) $matches[1],
                (string) ($payload['body_text'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && $path === '/agency/summary') {
        Response::json([
            'success' => true,
            'message' => 'Agency summary loaded successfully.',
            'data' => $agencyService->summary($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'POST' && $path === '/agency/open-requests') {
        Response::json([
            'success' => true,
            'message' => 'Agency open request submitted successfully.',
            'data' => [
                'request' => $agencyService->submitOpenRequest(
                    (string) ($payload['agency_name'] ?? ''),
                    (string) ($payload['country'] ?? ''),
                    (string) ($payload['phone'] ?? ''),
                    (string) ($payload['address'] ?? ''),
                    isset($payload['avatar']) && is_array($payload['avatar']) ? $payload['avatar'] : null,
                    isset($payload['front_id']) && is_array($payload['front_id']) ? $payload['front_id'] : null,
                    isset($payload['back_id']) && is_array($payload['back_id']) ? $payload['back_id'] : null,
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ], 201);
    }

    if ($method === 'POST' && $path === '/agency/join-requests') {
        Response::json([
            'success' => true,
            'message' => 'Agency join request submitted successfully.',
            'data' => [
                'request' => $agencyService->submitJoinRequest(
                    (string) ($payload['invitation_code'] ?? ''),
                    (string) ($payload['agency_type'] ?? ''),
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ], 201);
    }

    if ($method === 'GET' && $path === '/gifts/catalog') {
        Response::json([
            'success' => true,
            'message' => 'Gift catalog loaded successfully.',
            'data' => [
                'gifts' => $giftService->catalog(),
            ],
        ]);
    }

    if ($method === 'GET' && $path === '/wallet/summary') {
        Response::json([
            'success' => true,
            'message' => 'Wallet summary loaded successfully.',
            'data' => $giftService->walletSummary($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'GET' && $path === '/economy/wallet') {
        Response::json([
            'success' => true,
            'message' => 'Economy wallet loaded successfully.',
            'data' => $economyService->walletSummary($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'GET' && $path === '/levels/vip') {
        $levelService = new LevelService($pdo);
        Response::json([
            'success' => true,
            'message' => 'VIP levels loaded successfully.',
            'data' => $levelService->vipSummary($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'GET' && $path === '/referrals/summary') {
        $referralService = new ReferralService($pdo);
        Response::json([
            'success' => true,
            'message' => 'Referral summary loaded successfully.',
            'data' => $referralService->summary($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'POST' && $path === '/levels/vip/activate') {
        $levelService = new LevelService($pdo);
        Response::json([
            'success' => true,
            'message' => 'VIP level activated successfully.',
            'data' => $levelService->activateVip(
                (int) ($payload['level_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && $path === '/levels/vip/recipients') {
        $levelService = new LevelService($pdo);
        Response::json([
            'success' => true,
            'message' => 'VIP recipients loaded successfully.',
            'data' => $levelService->recipients(
                trim((string) ($_GET['query'] ?? '')),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/levels/vip/send') {
        $levelService = new LevelService($pdo);
        Response::json([
            'success' => true,
            'message' => 'VIP level sent successfully.',
            'data' => $levelService->sendVip(
                (int) ($payload['level_id'] ?? 0),
                isset($payload['recipient_user_id']) ? (int) $payload['recipient_user_id'] : null,
                (string) ($payload['recipient_name'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'POST' && $path === '/economy/wallet/top-up') {
        Response::json([
            'success' => true,
            'message' => 'Wallet package applied successfully.',
            'data' => $economyService->topUpWallet(
                (int) ($payload['package_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && $path === '/economy/wallet/records') {
        Response::json([
            'success' => true,
            'message' => 'Wallet records loaded successfully.',
            'data' => $economyService->walletRecords($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'GET' && $path === '/economy/history') {
        Response::json([
            'success' => true,
            'message' => 'Economy history loaded successfully.',
            'data' => $economyService->history(
                (string) ($_GET['wallet_type'] ?? 'coins'),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && $path === '/economy/store/catalog') {
        Response::json([
            'success' => true,
            'message' => 'Store catalog loaded successfully.',
            'data' => $economyService->storeCatalog(
                (string) ($_GET['category'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/economy/store/purchase') {
        Response::json([
            'success' => true,
            'message' => 'Store purchase completed successfully.',
            'data' => $economyService->purchaseStoreItem(
                (int) ($payload['item_id'] ?? 0),
                (int) ($payload['duration_days'] ?? 7),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && $path === '/economy/store/recipients') {
        Response::json([
            'success' => true,
            'message' => 'Store recipients loaded successfully.',
            'data' => $economyService->sendRecipients(
                (string) ($_GET['query'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/economy/store/send') {
        Response::json([
            'success' => true,
            'message' => 'Store item sent successfully.',
            'data' => $economyService->sendStoreItem(
                (int) ($payload['item_id'] ?? 0),
                (int) ($payload['duration_days'] ?? 7),
                isset($payload['recipient_user_id']) ? (int) $payload['recipient_user_id'] : null,
                (string) ($payload['recipient_name'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && $path === '/economy/bag') {
        Response::json([
            'success' => true,
            'message' => 'Bag loaded successfully.',
            'data' => $economyService->bagItems(
                (string) ($_GET['group'] ?? 'art'),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/economy/bag/equip') {
        Response::json([
            'success' => true,
            'message' => 'Bag item equipped successfully.',
            'data' => $economyService->equipInventoryItem(
                (int) ($payload['inventory_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/economy/bag/unequip') {
        Response::json([
            'success' => true,
            'message' => 'Bag item unequipped successfully.',
            'data' => $economyService->unequipInventoryItem(
                (int) ($payload['inventory_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/economy/bag/remove') {
        Response::json([
            'success' => true,
            'message' => 'Bag item removed successfully.',
            'data' => $economyService->removeInventoryItem(
                (int) ($payload['inventory_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && $path === '/posts') {
        Response::json([
            'success' => true,
            'message' => 'Posts loaded successfully.',
            'data' => $postService->feed(
                ((string) ($_GET['friends_only'] ?? '0')) === '1',
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/posts') {
        Response::json([
            'success' => true,
            'message' => 'Post created successfully.',
            'data' => [
                'post' => $postService->createPost(
                    (string) ($payload['body_text'] ?? ''),
                    is_array($payload['image'] ?? null) ? $payload['image'] : null,
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ], 201);
    }

    if ($method === 'GET' && $path === '/posts/report-reasons') {
        Response::json([
            'success' => true,
            'message' => 'Post report reasons loaded successfully.',
            'data' => [
                'reasons' => $postService->listReportReasons(),
            ],
        ]);
    }

    if ($method === 'GET' && $path === '/chat/inbox') {
        Response::json([
            'success' => true,
            'message' => 'Chat inbox loaded successfully.',
            'data' => $chatService->inbox(
                (string) ($_GET['scope'] ?? 'friends'),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && $path === '/chat/selection') {
        Response::json([
            'success' => true,
            'message' => 'Chat selection loaded successfully.',
            'data' => $chatService->selection($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'POST' && $path === '/chat/direct') {
        Response::json([
            'success' => true,
            'message' => 'Direct chat opened successfully.',
            'data' => $chatService->startDirectThread(
                (int) ($payload['user_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && preg_match('#^/chat/threads/(\d+)$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Chat conversation loaded successfully.',
            'data' => $chatService->conversation(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/chat/threads/(\d+)/messages$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Chat message sent successfully.',
            'data' => $chatService->sendMessage(
                (int) $matches[1],
                (string) ($payload['body_text'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null,
                (string) ($payload['message_type'] ?? 'text'),
                is_array($payload['attachment_upload'] ?? null) ? $payload['attachment_upload'] : null,
                isset($payload['attachment_path']) ? (string) $payload['attachment_path'] : null,
                isset($payload['attachment_name']) ? (string) $payload['attachment_name'] : null,
                isset($payload['gift_id']) ? (int) $payload['gift_id'] : 0,
                isset($payload['quantity']) ? (int) $payload['quantity'] : 1
            ),
        ], 201);
    }

    if ($method === 'GET' && $path === '/chat/search') {
        Response::json([
            'success' => true,
            'message' => 'Chat search loaded successfully.',
            'data' => $chatService->search(
                trim((string) ($_GET['query'] ?? 'Mo')),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/chat/search/delete') {
        Response::json([
            'success' => true,
            'message' => 'Search item deleted successfully.',
            'data' => $chatService->deleteSearch(
                (int) ($payload['search_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/chat/search/remember') {
        Response::json([
            'success' => true,
            'message' => 'Search item saved successfully.',
            'data' => $chatService->rememberSearch(
                (string) ($payload['label'] ?? ''),
                isset($payload['thread_id']) ? (int) $payload['thread_id'] : null,
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && $path === '/chat/threads/bulk') {
        Response::json([
            'success' => true,
            'message' => 'Chat bulk action completed successfully.',
            'data' => $chatService->bulkAction(
                is_array($payload['thread_ids'] ?? null) ? $payload['thread_ids'] : [],
                (string) ($payload['action'] ?? 'mark_read'),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && $path === '/posts/notifications') {
        Response::json([
            'success' => true,
            'message' => 'Notifications loaded successfully.',
            'data' => $postService->listNotifications($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'POST' && $path === '/posts/notifications/read-all') {
        Response::json([
            'success' => true,
            'message' => 'Notifications marked as read.',
            'data' => $postService->markNotificationsRead($_SERVER['HTTP_AUTHORIZATION'] ?? null),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/follow-toggle$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Follow status updated successfully.',
            'data' => $postService->toggleFollowByPost(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Post updated successfully.',
            'data' => [
                'post' => $postService->updatePost(
                    (int) $matches[1],
                    (string) ($payload['body_text'] ?? ''),
                    is_array($payload['image'] ?? null) ? $payload['image'] : null,
                    filter_var($payload['remove_image'] ?? false, FILTER_VALIDATE_BOOLEAN),
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/delete$#', $path, $matches) === 1) {
        $postService->deletePost(
            (int) $matches[1],
            $_SERVER['HTTP_AUTHORIZATION'] ?? null
        );
        Response::json([
            'success' => true,
            'message' => 'Post deleted successfully.',
            'data' => null,
        ]);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/like-toggle$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Like status updated successfully.',
            'data' => [
                'post' => $postService->toggleLike(
                    (int) $matches[1],
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ]);
    }

    if ($method === 'GET' && preg_match('#^/posts/(\d+)/comments$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Comments loaded successfully.',
            'data' => $postService->listComments(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/comments$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Comment added successfully.',
            'data' => $postService->addComment(
                (int) $matches[1],
                (string) ($payload['body_text'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/comments/(\d+)$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Comment updated successfully.',
            'data' => $postService->updateComment(
                (int) $matches[1],
                (int) $matches[2],
                (string) ($payload['body_text'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/comments/(\d+)/delete$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Comment deleted successfully.',
            'data' => $postService->deleteComment(
                (int) $matches[1],
                (int) $matches[2],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/comments/(\d+)/report$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Comment reported successfully.',
            'data' => $postService->reportComment(
                (int) $matches[1],
                (int) $matches[2],
                (string) ($payload['reason_key'] ?? ($payload['reason'] ?? '')),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/share$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Post shared successfully.',
            'data' => [
                'post' => $postService->sharePost(
                    (int) $matches[1],
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/posts/(\d+)/report$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Post reported successfully.',
            'data' => $postService->reportPost(
                (int) $matches[1],
                (string) ($payload['reason_key'] ?? ($payload['reason'] ?? '')),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && $path === '/shipping-agencies') {
        Response::json([
            'success' => true,
            'message' => 'Shipping agencies loaded successfully.',
            'data' => [
                'agencies' => $supportService->listShippingAgencies(
                    trim((string) ($_GET['query'] ?? ''))
                ),
            ],
        ]);
    }

    if ($method === 'POST' && $path === '/support/tickets') {
        Response::json([
            'success' => true,
            'message' => 'Support ticket submitted successfully.',
            'data' => [
                'ticket' => $supportService->submitTicket(
                    (string) ($payload['category'] ?? ''),
                    (string) ($payload['description'] ?? ''),
                    is_array($payload['attachments'] ?? null) ? $payload['attachments'] : [],
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ], 201);
    }

    if ($method === 'GET' && $path === '/music/catalog') {
        Response::json([
            'success' => true,
            'message' => 'Music catalog loaded successfully.',
            'data' => [
                'tracks' => $roomMusicService->catalog((string) ($_GET['source'] ?? '')),
            ],
        ]);
    }

    if ($method === 'GET' && $path === '/live/rooms') {
        Response::json([
            'success' => true,
            'message' => 'Live rooms loaded successfully.',
            'data' => [
                'rooms' => $liveService->listRooms(
                    (string) ($_GET['scope'] ?? 'live'),
                    trim((string) ($_GET['query'] ?? '')),
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ]);
    }

    if ($method === 'POST' && $path === '/live/rooms') {
        Response::json([
            'success' => true,
            'message' => 'Live room created successfully.',
            'data' => $liveService->createRoom(
                (string) ($payload['title'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && $path === '/live/notifications') {
        Response::json([
            'success' => true,
            'message' => 'Live notifications loaded successfully.',
            'data' => [
                'notifications' => $liveService->listNotifications(),
            ],
        ]);
    }

    if ($method === 'GET' && $path === '/live/action-buttons') {
        Response::json([
            'success' => true,
            'message' => 'Live action buttons loaded successfully.',
            'data' => [
                'sections' => $liveService->listActionButtons($_SERVER['HTTP_AUTHORIZATION'] ?? null),
            ],
        ]);
    }

    if ($method === 'GET' && preg_match('#^/live/rooms/(\d+)$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live room loaded successfully.',
            'data' => [
                'room' => $liveService->getRoom((int) $matches[1]),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/actions$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live action recorded successfully.',
            'data' => $liveService->recordAction(
                (int) $matches[1],
                (int) ($payload['action_id'] ?? 0),
                (string) ($payload['action_key'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/rtc/join$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live RTC session joined successfully.',
            'data' => $liveService->joinRtc(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && preg_match('#^/live/rooms/(\d+)/rtc/token$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live RTC token issued successfully.',
            'data' => $liveService->issueRtcToken(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/rtc/heartbeat$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live RTC heartbeat saved successfully.',
            'data' => $liveService->heartbeatRtc(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/rtc/leave$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live RTC session left successfully.',
            'data' => $liveService->leaveRtc(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/end$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live room ended successfully.',
            'data' => $liveService->endRoom(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && preg_match('#^/live/rooms/(\d+)/notifications$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live room notifications loaded successfully.',
            'data' => [
                'notifications' => $liveService->listNotifications((int) $matches[1]),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/comments$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live comment added successfully.',
            'data' => [
                'room' => $liveService->addComment(
                    (int) $matches[1],
                    (string) ($payload['message_text'] ?? ''),
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ], 201);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/report$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live room reported successfully.',
            'data' => $liveService->reportRoom(
                (int) $matches[1],
                (string) ($payload['reason'] ?? ''),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && preg_match('#^/live/rooms/(\d+)/gifts/supporters$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live supporters loaded successfully.',
            'data' => [
                'supporters' => $liveService->roomSupporters((int) $matches[1]),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/gifts/send$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live gift sent successfully.',
            'data' => $liveService->sendGift(
                (int) $matches[1],
                (int) ($payload['gift_id'] ?? 0),
                (int) ($payload['quantity'] ?? 1),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'GET' && $path === '/live/pk/recipients') {
        Response::json([
            'success' => true,
            'message' => 'PK recipients loaded successfully.',
            'data' => [
                'recipients' => $liveService->pkRecipients(
                    trim((string) ($_GET['query'] ?? '')),
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ]);
    }

    if ($method === 'GET' && $path === '/live/pk/invites') {
        Response::json([
            'success' => true,
            'message' => 'PK invites loaded successfully.',
            'data' => [
                'invites' => $liveService->listPkInvites(
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null,
                    (string) ($_GET['status'] ?? 'sent')
                ),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/pk/invites/(\d+)/accept$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'PK invite accepted successfully.',
            'data' => $liveService->acceptPkInvite(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/pk/invites/(\d+)/reject$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'PK invite rejected successfully.',
            'data' => $liveService->rejectPkInvite(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/pk-matching/start$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'PK matching started successfully.',
            'data' => $liveService->startPkMatching(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/pk/end$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'PK battle ended successfully.',
            'data' => $liveService->endPkBattle(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/pk/tap$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'PK tap recorded successfully.',
            'data' => $liveService->sendPkTap(
                (int) $matches[1],
                (string) ($payload['side'] ?? 'host'),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/pk-invites$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'PK invite sent successfully.',
            'data' => $liveService->sendPkInvite(
                (int) $matches[1],
                (int) ($payload['recipient_user_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'POST' && preg_match('#^/live/rooms/(\d+)/pk-settings$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Live PK settings updated successfully.',
            'data' => [
                'room' => $liveService->updatePkSettings(
                    (int) $matches[1],
                    (string) ($payload['talk_permission'] ?? ''),
                    (string) ($payload['party_invite_permission'] ?? ''),
                    (string) ($payload['voice_room_invite_permission'] ?? ''),
                    (string) ($payload['chat_permission'] ?? ''),
                    (string) ($payload['battle_duration'] ?? ''),
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ]);
    }

    if ($method === 'GET' && $path === '/rooms') {
        $roomRtcService->refreshAudioPresence();
        Response::json([
            'success' => true,
            'message' => 'Rooms loaded successfully.',
            'data' => [
                'rooms' => $roomService->listRooms(
                    (string) ($_GET['scope'] ?? 'newest'),
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null
                ),
            ],
        ]);
    }

    if ($method === 'POST' && $path === '/rooms') {
        Response::json([
            'success' => true,
            'message' => 'Room created successfully.',
            'data' => [
                'room' => $roomService->createRoom(
                    (string) ($payload['room_name'] ?? ''),
                    (string) ($payload['room_type'] ?? ''),
                    (string) ($payload['slogan_text'] ?? ''),
                    (string) ($payload['country_label'] ?? ''),
                    $_SERVER['HTTP_AUTHORIZATION'] ?? null,
                    isset($payload['card_image_asset']) ? (string) $payload['card_image_asset'] : null,
                    is_array($payload['card_image_upload'] ?? null) ? $payload['card_image_upload'] : null,
                ),
            ],
        ], 201);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)$#', $path, $matches) === 1) {
        $roomRtcService->refreshAudioPresence((int) $matches[1]);
        Response::json([
            'success' => true,
            'message' => 'Room loaded successfully.',
            'data' => [
                'room' => $roomService->getRoom((int) $matches[1]),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/audio/join$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room audio session joined successfully.',
            'data' => $roomRtcService->join(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/audio/heartbeat$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room audio session refreshed successfully.',
            'data' => $roomRtcService->heartbeat(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/audio/leave$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room audio session left successfully.',
            'data' => $roomRtcService->leave(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/audio/end$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room audio ended successfully.',
            'data' => $roomRtcService->endRoomAsHost(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)/audio/participants$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room audio participants loaded successfully.',
            'data' => [
                'participants' => $roomRtcService->listParticipants((int) $matches[1]),
                'configuration' => $roomRtcService->configurationStatus(),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/audio/microphone$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room microphone state updated successfully.',
            'data' => $roomRtcService->updateLocalMicrophone(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null,
                filter_var($payload['muted'] ?? false, FILTER_VALIDATE_BOOLEAN)
            ),
        ]);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)/audio/token$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room audio token issued successfully.',
            'data' => $roomRtcService->issueToken(
                (int) $matches[1],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/mic-count$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Mic count updated successfully.',
            'data' => [
                'room' => $roomService->updateMicCount(
                    (int) $matches[1],
                    (int) ($payload['mic_count'] ?? 0)
                ),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/seat-requests$#', $path, $matches) === 1) {
        $request = $roomService->createSeatRequest(
            (int) $matches[1],
            (int) ($payload['seat_number'] ?? 0),
            $_SERVER['HTTP_AUTHORIZATION'] ?? null
        );

        Response::json([
            'success' => true,
            'message' => 'Seat request created successfully.',
            'data' => [
                'request' => $request,
                'room' => $roomService->getRoom((int) $matches[1]),
            ],
        ], 201);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)/seat-requests$#', $path, $matches) === 1) {
        $seatNumber = isset($_GET['seat_number']) ? (int) $_GET['seat_number'] : null;
        Response::json([
            'success' => true,
            'message' => 'Seat requests loaded successfully.',
            'data' => [
                'requests' => $roomService->listSeatRequests((int) $matches[1], $seatNumber),
            ],
        ]);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)/gifts/received$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room received gifts loaded successfully.',
            'data' => [
                'supporters' => $giftService->roomReceivedGifts((int) $matches[1]),
            ],
        ]);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)/games/catalog$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room games catalog loaded successfully.',
            'data' => $roomGameService->catalog((int) $matches[1]),
        ]);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)/games/(\d+)$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room game lobby loaded successfully.',
            'data' => $roomGameService->lobby(
                (int) $matches[1],
                (int) $matches[2],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/games/(\d+)/join$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Joined room game successfully.',
            'data' => $roomGameService->joinGame(
                (int) $matches[1],
                (int) $matches[2],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/games/sessions/(\d+)/leave$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Left room game successfully.',
            'data' => $roomGameService->leaveSession(
                (int) $matches[1],
                (int) $matches[2],
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ]);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)/music/playlist$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room music playlist loaded successfully.',
            'data' => $roomMusicService->roomPlaylist((int) $matches[1]),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/gifts/send$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Gift sent successfully.',
            'data' => $giftService->sendRoomGift(
                (int) $matches[1],
                (int) ($payload['gift_id'] ?? 0),
                (int) ($payload['quantity'] ?? 1),
                (string) ($payload['recipient_mode'] ?? 'room_users'),
                isset($payload['recipient_slot']) ? (int) $payload['recipient_slot'] : null,
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/music/playlist$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Track added to room playlist successfully.',
            'data' => $roomMusicService->addTrackToRoom(
                (int) $matches[1],
                (int) ($payload['track_id'] ?? 0),
                $_SERVER['HTTP_AUTHORIZATION'] ?? null
            ),
        ], 201);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/music/playlist/(\d+)/remove$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Track removed from room playlist successfully.',
            'data' => $roomMusicService->removePlaylistEntry(
                (int) $matches[1],
                (int) $matches[2]
            ),
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/seat-requests/(\d+)/approve$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Seat request approved successfully.',
            'data' => [
                'request' => $roomService->approveSeatRequest((int) $matches[1], (int) $matches[2]),
                'room' => $roomService->getRoom((int) $matches[1]),
            ],
        ]);
    }

    if ($method === 'POST' && preg_match('#^/rooms/(\d+)/seat-requests/(\d+)/reject$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Seat request rejected successfully.',
            'data' => [
                'request' => $roomService->rejectSeatRequest((int) $matches[1], (int) $matches[2]),
                'room' => $roomService->getRoom((int) $matches[1]),
            ],
        ]);
    }

    Response::json([
        'success' => false,
        'message' => 'Endpoint not found.',
    ], 404);
} catch (ApiException $exception) {
    Response::json([
        'success' => false,
        'message' => $exception->getMessage(),
    ], $exception->statusCode());
} catch (Throwable $throwable) {
    Response::json([
        'success' => false,
        'message' => 'Server error.',
        'debug' => $throwable->getMessage(),
    ], 500);
}
