<?php
​
$authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? null;
$user = $_SERVER['PHP_AUTH_USER'] ?? null;
$password = $_SERVER['PHP_AUTH_PW'] ?? null;
​
if ($authorization === null) {
    http_response_code(401);
    exit();
}
​
if($user !== null && $password !== null) {
    $allowed = [
        'user' => 'password'
    ];
​
    foreach ($allowed as $key => $value) {
        if ($user === $key && $password === $value) {
            http_response_code(201);
            exit();
        }
    }
} else {
    try {
        $curl_h = curl_init('https://inbudget.jkweb.ch/api/users/current');
​
        curl_setopt($curl_h, CURLOPT_HTTPHEADER,
            array(
                "Authorization: ".$authorization."\r\n"
            )
        );
​
        # do not output, but store to variable
        curl_setopt($curl_h, CURLOPT_RETURNTRANSFER, true);
        $response = curl_exec($curl_h);
        $httpCode = curl_getinfo($curl_h, CURLINFO_HTTP_CODE);
        curl_close($curl_h);
​
        if($httpCode < 300 && $httpCode >= 200) {
            http_response_code(201);
            exit();
        }
    } catch (\Throwable $e) {
        http_response_code(401);
        exit();
    }
}
​
http_response_code(401);
exit();