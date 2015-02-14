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
      <input type="submit" name="action" value="REFRESH" />
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
           case 'REFRESH':
           break;
           default:
             print_r($_REQUEST);
             print_r($_ENV);
           break;
         }
         echo '</pre>';
       }
       ?>
    <table border="1">
      <thead>
	<th>Artiste</th>
	<th>Morceau</th>
	<th>Mode</th>
      </thead>
      <?php foreach (get_metadata() as $song) { ?>
      <tr>
	<td><?php print($song['artist']);?>&nbsp;</td>
	<td><?php print($song['left_title']);?>&nbsp;</td>
	<td><?php print($song['mode']);?></td>
      </tr>
      <?php } ?>
    </table>
  </body>
</html>
