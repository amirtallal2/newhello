<?php

declare(strict_types=1);

$config = require __DIR__ . '/../config/app.php';

require_once __DIR__ . '/../src/Database.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/Response.php';
require_once __DIR__ . '/../src/TokenManager.php';
require_once __DIR__ . '/../src/AuthService.php';
require_once __DIR__ . '/../src/GiftService.php';
require_once __DIR__ . '/../src/RoomService.php';
require_once __DIR__ . '/../src/RoomMusicService.php';

Response::cors();

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    Response::json(['success' => true], 200);
}

$pdo = Database::connection($config['db']);
$authService = new AuthService($pdo, $config);
$giftService = new GiftService($pdo);
$roomService = new RoomService($pdo);
$roomMusicService = new RoomMusicService($pdo);
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';
$path = preg_replace('#^' . preg_quote($config['api_base_path'], '#') . '#', '', $path) ?: '/';
$method = $_SERVER['REQUEST_METHOD'];

try {
    $payload = Response::readJson();

    if ($method === 'POST' && $path === '/auth/register') {
        $data = $authService->register(
            (string) ($payload['email'] ?? ''),
            (string) ($payload['password'] ?? '')
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

    if ($method === 'GET' && $path === '/music/catalog') {
        Response::json([
            'success' => true,
            'message' => 'Music catalog loaded successfully.',
            'data' => [
                'tracks' => $roomMusicService->catalog((string) ($_GET['source'] ?? '')),
            ],
        ]);
    }

    if ($method === 'GET' && $path === '/rooms') {
        Response::json([
            'success' => true,
            'message' => 'Rooms loaded successfully.',
            'data' => [
                'rooms' => $roomService->listRooms(),
            ],
        ]);
    }

    if ($method === 'GET' && preg_match('#^/rooms/(\d+)$#', $path, $matches) === 1) {
        Response::json([
            'success' => true,
            'message' => 'Room loaded successfully.',
            'data' => [
                'room' => $roomService->getRoom((int) $matches[1]),
            ],
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
