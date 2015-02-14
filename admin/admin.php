<?php

if ($_ENV['ICECAST_ADMIN_PASSWORD'] != $_GET['auth']) {
   echo("T'es pas admin !");
   exit;
}

?>
<html>
  <head>
    <style>
      html { background: #505; color: white; }
    </style>
  </head>
  <body>
    <form method="GET">
      <input type="hidden" name="auth" value="<?php echo $_GET['auth'] ?>" />
      <input type="submit" name="action" value="NEXT" />
      <input type="submit" name="action" value="INFO" />
    </form>
    <?php
       include('functions.php');
       if ($_REQUEST['action']) {
         echo '<pre>';
         switch ($_REQUEST['action']) {
           case 'NEXT':
             echo telnet_send("rscc(dot)main.skip");
           break;
           case 'INFO':
             cool_print(get_infos(), 'debug');
           break;
           case 'DIRE':
             echo "TODO";
           break;
           case 'REQUEST':
             echo "TODO";
           break;
           default:
             print_r($_REQUEST);
             print_r($_ENV);
           break;
         }
         echo '</pre>';
       }
       ?>
  </body>
</html>
