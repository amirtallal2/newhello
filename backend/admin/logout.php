<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';

session_destroy();
admin_redirect('/admin/login.php');
