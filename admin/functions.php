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


function cache_get($name) {
  $cache_file = "$name.cache";
  if (file_exists($cache_file) && (filemtime($cache_file) > (time() - 5 ))) {
    return json_decode(file_get_contents($cache_file));
  }
  return false;
}


function cache_set($name, $value) {
  $cache_file = "$name.cache";
  file_put_contents($cache_file, json_encode($value), LOCK_EX);
}


function get_infos() {
  $infos = array();
  $metadata = get_metadata();
  $infos['current'] = array_shift($metadata);
  $infos['history'] = $metadata;
  return $infos;
}


function get_metadata() {
  $entries = cache_get('metadata');
  if (!$entries) {
    $lines = explode("\n", trim(telnet_send("rscc(dot)main.metadata")));
    $entries_assoc = [];
    $entry_number = 0;

    foreach ($lines as $line) {
      if (in_array(trim($line), array('END', 'Bye!'))) {
	continue;
      }
      $match = preg_match('/^---\ ([0-9]*)\ ---/', $line, $search);
      if ($match) {
	if ($entry_number) {
	  $entries_assoc[$entry_number] = $entry;
	}
	$entry_number = intval($search[1]);
	$entry = array();
      } else {
	$value = explode('=', $line, 2);
	$entry[$value[0]] = $value[1];
      }
    }
    $entries_assoc[$entry_number] = $entry;
    $entries = array();
    for ($i = 1; $i < sizeof($entries_assoc); $i++) {
      $entry = $entries_assoc[$i];
      $entry['live'] = false;
      if (preg_match('/(LIVE - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['live'] = true;
	$entry['mode'] = 'live';
      } else if (preg_match('/Jingle (radio Salut c\'est cool)/', $entry['title'])) {
	$entry['mode'] = 'jingle';
      } else if (preg_match('/(reggae - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['mode'] = 'reggae';
      } else if (preg_match('/(soiree - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['mode'] = 'soiree';
      } else if (preg_match('/(jour - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['mode'] = 'jour';
      } else if (preg_match('/(nuit - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['mode'] = 'nuit';
      } else if (preg_match('/(matin - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['mode'] = 'matin';
      } else if (preg_match('/(pluie - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['mode'] = 'pluie';
      } else if (preg_match('/(trance - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['mode'] = 'trance';
      } else { 
	$entry['mode'] = 'random';
      }
      $entries[] = $entry;
    }

    cache_set('metadata', $entries);
  }
  return $entries;
}


function cool_print($data, $format) {
  switch ($format) {
  case 'json':
    echo(json_encode($data));
    break;
  case 'jsonp':
    printf("%s(%s);", $_GET['callback'], json_encode($data));
    break;
  case 'debug':
    echo '<pre>';
    print_r($data);
    echo '</pre>';
    break;
  }
}
