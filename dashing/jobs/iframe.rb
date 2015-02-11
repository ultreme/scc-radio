SCHEDULER.every '2m', :first_in => 0 do |job|
    send_event('adminiframe', url: ENV['ADMIN_IFRAME_URL'])
end
