# Voice Live Backend

المرحلة الحالية تغطي:

- API للمصادقة والمستخدمين
- API للغرف الصوتية وطلبات المايك
- API للهدايا داخل الغرف والمحفظة
- API للموسيقى داخل الغرفة وقائمة التشغيل
- قاعدة بيانات للمستخدمين والتسجيلات المعلقة والتوكنز
- قاعدة بيانات للغرف الصوتية وطلبات المايك
- قاعدة بيانات للهدايا والمحافظ وسجل الإرسال
- قاعدة بيانات لمكتبة الموسيقى وقوائم تشغيل الغرف
- لوحة تحكم أدمن لإدارة المستخدمين والغرف والهدايا

## التشغيل السريع

### 1) تشغيل المهاجرات

MySQL:

```bash
APP_DB_DRIVER=mysql \
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_DATABASE=voice_live \
DB_USERNAME=YOUR_DB_USER \
DB_PASSWORD=YOUR_DB_PASSWORD \
php backend/scripts/migrate.php
```

تشغيل محلي سريع بدون MySQL:

```bash
APP_DB_DRIVER=sqlite php backend/scripts/migrate.php
```

### 2) تشغيل السيرفر

```bash
APP_DB_DRIVER=sqlite php -S 127.0.0.1:8080 backend/router.php
```

أو مع MySQL بنفس متغيرات البيئة السابقة.

## روابط التشغيل

- API: `http://127.0.0.1:8080/api`
- Admin: `http://127.0.0.1:8080/admin/login.php`

## بيانات الأدمن الافتراضية

- Email: `admin@voicelive.local`
- Password: `Admin@12345`

## أهم المسارات

- `POST /api/auth/register`
- `POST /api/auth/email/resend`
- `POST /api/auth/email/verify`
- `POST /api/auth/identity`
- `POST /api/auth/phone/verify`
- `POST /api/auth/login/email`
- `POST /api/auth/login/phone`
- `POST /api/auth/password/forgot`
- `POST /api/auth/password/reset`
- `GET /api/auth/me`
- `GET /api/rooms`
- `GET /api/rooms/{id}`
- `POST /api/rooms/{id}/mic-count`
- `POST /api/rooms/{id}/seat-requests`
- `GET /api/rooms/{id}/seat-requests`
- `POST /api/rooms/{id}/seat-requests/{requestId}/approve`
- `POST /api/rooms/{id}/seat-requests/{requestId}/reject`
- `GET /api/gifts/catalog`
- `GET /api/music/catalog?source=friends|whatsapp`
- `GET /api/wallet/summary`
- `GET /api/rooms/{id}/gifts/received`
- `POST /api/rooms/{id}/gifts/send`
- `GET /api/rooms/{id}/music/playlist`
- `POST /api/rooms/{id}/music/playlist`
- `POST /api/rooms/{id}/music/playlist/{entryId}/remove`

## صفحات الأدمن الحالية

- `/admin/index.php`
- `/admin/users.php`
- `/admin/user.php?id=...`
- `/admin/rooms.php`
- `/admin/room.php?id=...`
- `/admin/gifts.php`
- `/admin/gift-transactions.php`
- `/admin/music-tracks.php`
- `/admin/room.php?id=...` ويتضمن إدارة قائمة الموسيقى للغرفة
