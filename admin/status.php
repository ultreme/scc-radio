<?php

include('functions.php');

$data = get_status();

if ($_GET['format'] == '') {
   $_GET['format'] = 'json';
}
cool_print($data, $_GET['format']);
