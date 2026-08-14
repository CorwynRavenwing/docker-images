<?php
header('Content-Type: text/plain');
$server = isset($_SERVER['SERVER_SOFTWARE']) ? $_SERVER['SERVER_SOFTWARE'] : 'N/A';
echo "PHP Version: " . phpversion() . "\n";
echo "Server Software: " . $server . "\n";
echo "SAPI Name: " . php_sapi_name() . "\n";
