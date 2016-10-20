
class IssuesHookListener < Redmine::Hook::Listener
  def controller_issues_edit_after_save(context = {})
    issue = context[:issue]
    journal = context[:journal]
    
    statusChange = journal.detail_for_attribute('status_id')
    
    if statusChange.nil?
      return
    end
    
    event = {
      :issue_id => issue.id,
      :project_id => issue.project.id,
      :old_status_id => statusChange.old_value,
      :new_status_id => statusChange.value
    }
    
    send_event_async(event)
  end

  # method to send the event to the message broker
  def send_event_async(event)
    Thread.new do
      uri = URI.parse('http://localhost:8161/api/message/redmine?type=topic')
      
      # load cookies store
      cookiesStore = PStore.new("notify.cookies.pstore", thread_safe = true)
      
      # prepare cookie header
      cookiesString = ""
      cookiesStore.transaction(true) do
        cookies = cookiesStore[:cookies]
        if(cookies)
          cookiesString = cookies.map{|k,v| "#{k}=#{v}"}.join(';')
        end
      end
      
      # setup request
      request = Net::HTTP::Post.new(uri, {
        'Content-Type' => 'application/json',
        'Cookie' => cookiesString
      })
      request.basic_auth("admin", "admin")
      request.body = event.to_json
      
      # execute request
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request(request)
      
      # save any new cookies
      newCookies = response.get_fields('Set-Cookie')
      if(newCookies)
        cookiesStore.transaction do
          cookies = cookiesStore[:cookies]
          if(!cookies)
            cookies = Hash.new
          end
          
          newCookies.each do |cookie|
            cookie = ( cookie.split(';')[0] ).split('=', 2)
            cookies[ cookie[0] ] = cookie[1]
          end
          
          cookiesStore[:cookies] = cookies
        end
      end
    end
  end
end
