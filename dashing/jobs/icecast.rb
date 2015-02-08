require 'net/http'
require 'rexml/document'
require 'uri'
require 'pp'

current_total_listeners = 0

SCHEDULER.every '2s' do
  last_total_listeners = current_total_listeners
  uri = URI.parse('http://' + ENV['ICECAST_PORT_8000_TCP_ADDR'] + ':' + ENV['ICECAST_PORT_8000_TCP_PORT'] + '/admin/stats.xml')
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth("admin", ENV['ICECAST_ENV_ICECAST_ADMIN_PASSWORD'])
  response = http.request(request)

  doc = REXML::Document.new(response.body)
  doc.elements.each('icestats/source') do |ele|
    #puts 'source', ele.text
  end

  current_total_listeners = doc.root.elements['listeners'].text.to_i

  #pp response
  #puts response.body

  send_event('total-listeners', { current: current_total_listeners, last: last_total_listeners })
end
