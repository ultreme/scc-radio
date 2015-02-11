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
       function telnet_send($command) {
             $fp = stream_socket_client($_ENV['MAIN_PORT_5000_TCP'], $errno, $errstr, 5);
             if (!$fp) {
               return("<b><u>TELNET FAILURE:</u> $errstr ($errno)</b><br>");
             }
             fwrite($fp, "$command\nquit\n");
             $eat = '';
             while (!feof($fp)) {
               $eat .= fgets($fp, 1024);
             }
             fclose($fp);
             return $eat;
       }

       if ($_REQUEST['action']) {
         echo '<pre>';
         switch ($_REQUEST['action']) {
           case 'NEXT':
             echo telnet_send("rscc(dot)main.skip");
           break;
           case 'INFO':
             echo telnet_send("rscc(dot)main.metadata");
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
