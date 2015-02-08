require 'net/http'
require 'rexml/document'
require 'uri'
require 'pp'

total_listeners_current = 0
total_listeners_points = []
(1..100).each do |i|
  total_listeners_points << { x: i, y: 0 }
end
total_listeners_last_x = total_listeners_points.last[:x]


SCHEDULER.every '5s' do
  total_listeners_last = total_listeners_current
  uri = URI.parse('http://' + ENV['ICECAST_PORT_8000_TCP_ADDR'] + ':' + ENV['ICECAST_PORT_8000_TCP_PORT'] + '/admin/stats.xml')
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth("admin", ENV['ICECAST_ENV_ICECAST_ADMIN_PASSWORD'])
  response = http.request(request)

  doc = REXML::Document.new(response.body)
  doc.elements.each('icestats/source') do |ele|
    #puts 'source', ele.text
  end

  total_listeners_current = doc.root.elements['listeners'].text.to_i

  #pp response
  #puts response.body

  send_event('total-listeners', { current: total_listeners_current, last: total_listeners_last })


  total_listeners_points.shift
  total_listeners_last_x += 1
  total_listeners_points << { x: total_listeners_last_x, y: total_listeners_current }
  send_event('total-listeners-graph', points: total_listeners_points)
end
