<?php

const HTTP_OK = 204;
const HTTP_UNAUTHORIZED = 401;
const USERS_FILE = '/etc/satis-server/users.json';
const INBUDGET_URL = 'https://inbudget.jkweb.ch/api/users/current';

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

function isInbudgetUserValid(string $authorization): bool
{
    try {
        $curlHandler = curl_init(INBUDGET_URL);
        curl_setopt($curlHandler, CURLOPT_HTTPHEADER, ["Authorization: $authorization\r\n"]);
        curl_setopt($curlHandler, CURLOPT_RETURNTRANSFER, true);
        curl_exec($curlHandler);
        $httpCode = curl_getinfo($curlHandler, CURLINFO_HTTP_CODE);
        curl_close($curlHandler);

        echo "inbudget http code: $httpCode\n";

        return ($httpCode < 300 && $httpCode >= 200);
    } catch (\Throwable $e) {
        return false;
    }
}

$authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? null;
$user = $_SERVER['PHP_AUTH_USER'] ?? null;
$password = $_SERVER['PHP_AUTH_PW'] ?? null;

if ($authorization === null) {
    http_response_code(HTTP_UNAUTHORIZED);
    exit();
}

if ($user !== null && $password !== null && isLocalUserValid($user, $password)) {
    http_response_code(HTTP_OK);
    exit();
}

if (isInbudgetUserValid($authorization)) {
    http_response_code(HTTP_OK);
    exit();
}

http_response_code(HTTP_UNAUTHORIZED);
exit();
