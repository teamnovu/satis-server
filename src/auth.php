<?php

const HTTP_OK = 204;
const HTTP_UNAUTHORIZED = 401;
const USERS_FILE = '/etc/satis-server/users.json';
define('BEARER_UPSTREAM_ENDPOINT', getenv('BEARER_UPSTREAM_ENDPOINT') ?? '');
define('DEBUG_MODE_ENABLED', getenv('DEBUG_MODE_ENABLED') ?? false);

function logMessage($message)
{
    if (!DEBUG_MODE_ENABLED) {
        return;
    }

    error_log("$message\n");
}

logMessage("auth.php called");

function getLocalUsers(): array
{
    if (file_exists(USERS_FILE)) {
        $contents = file_get_contents(USERS_FILE);
        $users = json_decode($contents, true);
        if (is_array($users)) {
            return $users;
        }
    }

    return [];
}

function isLocalUserValid(string $user, string $password): bool
{
    $allowedUsers = getLocalUsers();

    foreach ($allowedUsers as $allowedUser => $allowedPassword) {
        if ($user === $allowedUser && $password === $allowedPassword) {
            return true;
        }
    }

    return false;
}

function isValidBearerToken(string $authorization): bool
{
    if (!BEARER_UPSTREAM_ENDPOINT) {
        return false;
    }

    if (substr($authorization, 0, 7) !== 'Bearer ') {
        return false;
    }

    try {
        $curlHandler = curl_init(BEARER_UPSTREAM_ENDPOINT);
        curl_setopt($curlHandler, CURLOPT_HTTPHEADER, ["Authorization: $authorization\r\n"]);
        curl_setopt($curlHandler, CURLOPT_RETURNTRANSFER, true);
        curl_exec($curlHandler);
        $httpCode = curl_getinfo($curlHandler, CURLINFO_HTTP_CODE);
        curl_close($curlHandler);

        logMessage("bearer check http code: $httpCode\n");

        return ($httpCode < 300 && $httpCode >= 200);
    } catch (\Throwable $e) {
        logMessage("bearer check error: {$e->getMessage()}\n");

        return false;
    }
}

$authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? null;
$user = $_SERVER['PHP_AUTH_USER'] ?? null;
$password = $_SERVER['PHP_AUTH_PW'] ?? null;

logMessage("checking authorization header: " . substr($authorization, 0, 10) . "..." . substr($authorization, -10) . "...");

if ($authorization === null) {
    http_response_code(HTTP_UNAUTHORIZED);
    exit();
}

logMessage("checking local user config file");

if ($user !== null && $password !== null && isLocalUserValid($user, $password)) {
    http_response_code(HTTP_OK);
    exit();
}

logMessage("try to check bearer token");

if (isValidBearerToken($authorization)) {
    http_response_code(HTTP_OK);
    exit();
}

http_response_code(HTTP_UNAUTHORIZED);
exit();
