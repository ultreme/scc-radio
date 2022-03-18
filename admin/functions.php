<?php

error_reporting(E_ALL & ~E_NOTICE);

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
  if ($_GET["skip-cache"] == "true") {
    return false;
  }
  $cache_file = "$name.cache";
  if (file_exists($cache_file) && (filemtime($cache_file) > (time() - 5 ))) {
    $content = file_get_contents($cache_file);
    if (strlen($content) < 1) {
      return false;
    }
    return json_decode($content);
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
  //include_once('getid3/getid3/getid3.php');
  //$getID3 = new getID3;
  $infos['history'] = $metadata;
  return $infos;
}


function get_metadata() {
  $entries = cache_get('metadata');
  //var_dump($entries);
  if ($entries) {
    foreach ($entries as $key => $value) {
      $entries[$key] = (array)$value;
    }
  } else {
    $lines = explode("\n", trim(telnet_send("rscc.main.metadata")));
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
	$entry[$value[0]] = trim(trim($value[1]), '"');
      }
    }
    $entries_assoc[$entry_number] = $entry;
    $entries = array();
    for ($i = 1; $i < sizeof($entries_assoc); $i++) {
      $entry = $entries_assoc[$i];
      if ($entry["source_tag"] == "jingles") {
	continue;
      }
      // print_r($entry);
      $pos = strrpos($entry['title'], '(');
      $entry['left_title'] = trim(substr($entry['title'], 0, $pos));
      $entry['right_title'] = substr(trim(substr($entry['title'], $pos)), 1, -1);
      if (preg_match('/(LIVE de copains- radio Salut c\'est cool)/', $entry['title'])) {
	$entry['live'] = 1;
	$entry['mode'] = 'live';
	$entry['artist'] = 'Copains de salut c\'est cool';
      } else if (preg_match('/(LIVE de SCC - radio Salut c\'est cool)/', $entry['title'])) {
	$entry['live'] = 1;
	$entry['mode'] = 'live';
	$entry['live_artist'] = 'scc';
	//$entry['artist'] = 'salut c\'est cool';
      } else if ($entry['title'] == 'LIVE') {
	$entry['live'] = 1;
	$entry['mode'] = 'live';
	$entry['live_artist'] = 'secret';
	if ($entry['full_title'] == '') {
	$entry['full_title'] = '📡';
	}
	//$entry['artist'] = 'salut c\'est cool';
      } else {
	$mode = explode(' - ', $entry['right_title']);
	$entry['live'] = 0;
	if ($mode[0]) {
	  $entry['mode'] = $mode[0];
	}
      }
      if (empty($entry['full_title'])) {
	if ($entry['artist'] && $entry['left_title']) {
	  $entry['full_title'] = sprintf('%s - %s', $entry['artist'], $entry['left_title']);
	} else {
	  $entry['full_title'] = $entry['left_title'];
	}
      }
      if (empty($entry['full_title'])) {
	//$entry['full_title'] = 'Morceau sans nom';
        $entry['full_title'] = basename($entry['filename']);
      }
      if (empty($entry['full_title'])) {
	$entry['full_title'] = "mystère et boule de gomme";
      }
      /*if ($entry['live_artist'] == 'scc') {
	if (empty($entry['full_title'])) {
	$entry['full_title'] = 'salut c\'est cool en live';
	} else {
	$entry['full_title'] = sprintf('salut c\'est cool en live (%s)', $entry['full_title']);
	}
	}*/
      $allowed = array("comment", "genre", "tbpm", "on_air", "source_tag", "source", "title", "artist", "on_air_timestamp", "left_title", "right_title", "mode", "full_title", "composer", "album", "live", "year", "publisher", "tracknumber", "status", "album_artist");
      if ($_GET["no_skip_metadata"] != "true") {
	$entry = array_intersect_key($entry, array_flip($allowed));
      }
      $entries[] = $entry;
    }

    //print_r($entries);
    cache_set('metadata', $entries);
  }
  return $entries;
}


function cool_print($data, $format) {
  switch ($format) {
  case 'json':
    header('Content-Type: application/json; charset=utf-8');
    echo(json_encode($data, JSON_PRETTY_PRINT));
    break;
  case 'jsonp':
    header('Content-Type: application/javascript; charset=utf-8');
    printf("%s(%s);", $_GET['callback'], json_encode($data));
    break;
  case 'debug':
    header('Content-Type: text/plain');
    print_r($data);
    break;
  }
}
