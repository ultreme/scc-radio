<?php

include('functions.php');

switch ($_GET['action']) {
 case 'metadata':
   $data = get_metadata();
   break;
 case 'infos':
   $data = get_infos();
   break;
}

cool_print($data, $_GET['format']);
