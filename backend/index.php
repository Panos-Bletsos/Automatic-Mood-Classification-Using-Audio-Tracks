<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$out = shell_exec('sh ./convert.sh');
echo $out;

?>