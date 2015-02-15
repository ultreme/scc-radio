require 'net/http'
require 'rexml/document'
require 'uri'
require 'pp'

current_song = ''
current_live = ''

total_listeners_current = 0
total_listeners_points = []
(1..100).each do |i|
  total_listeners_points << { x: i, y: 0 }
end
total_listeners_last_x = total_listeners_points.last[:x]

total_connections_points = []
(1..100).each do |i|
  total_connections_points << { x: i, y: 0 }
end
total_connections_last_x = total_connections_points.last[:x]
total_connections_current = 0


SCHEDULER.every '5s' do
  uri = URI.parse('http://' + ENV['ICECAST_PORT_8000_TCP_ADDR'] + ':' + ENV['ICECAST_PORT_8000_TCP_PORT'] + '/admin/stats.xml')
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth("admin", ENV['ICECAST_ENV_ICECAST_ADMIN_PASSWORD'])
  response = http.request(request)

  doc = REXML::Document.new(response.body)
  doc.elements.each('icestats/source') do |ele|
    #puts 'source', ele.text
  end

  #pp response
  #puts response.body

  ####

  total_listeners_last = total_listeners_current
  total_listeners_current = doc.root.elements['listeners'].text.to_i
  total_connections_last = total_connections_current
  total_connections_current = doc.root.elements['listener_connections'].text.to_i


  send_event('total-listeners', { current: total_listeners_current, last: total_listeners_last })
  send_event('total-connections', { current: total_connections_current, last: total_connections_last })

  total_listeners_points.shift
  total_listeners_last_x += 1
  total_listeners_points << { x: total_listeners_last_x, y: total_listeners_current }
  send_event('total-listeners-graph', points: total_listeners_points)
  total_connections_points.shift
  total_connections_last_x += 1
  total_connections_points << { x: total_connections_last_x, y: total_connections_current }
  send_event('total-connections-graph', points: total_connections_points)

  latest_song = current_song
  current_song = doc.root.elements['source'].elements['title'].text
  if latest_song != current_song
    send_event('current-song', { text: current_song })
  end

  latest_live = current_live
  current_live = current_song =~ /LIVE\ de\ /
  if latest_live != current_live
    if current_live
      send_event('is-live', { text: 'LIVE :)' })
    else
      send_event('is-live', { text: 'PAS LIVE :(' })
    end
  end
end
