
class IssuesHookListener < Redmine::Hook::Listener

  # catch new tickets
  def controller_issues_new_after_save(context = {})
    issue = context[:issue]

    event = {
      :type => "creation",
      :issue_id => issue.id,
      :project_id => issue.project.id,
      :priority_id => issue.priority.id
    }

    send_event_async(event)
  end

  # catch ticket status changes
  def controller_issues_edit_after_save(context = {})
    issue = context[:issue]
    journal = context[:journal]

    statusChange = journal.detail_for_attribute('status_id')

    if statusChange.nil?
      return
    end

    event = {
      :type => "change",
      :issue_id => issue.id,
      :project_id => issue.project.id,
      :priority_id => issue.priority.id,
      :old_status_id => statusChange.old_value,
      :new_status_id => statusChange.value
    }

    send_event_async(event)
  end

  # method to send the event to the message broker
  def send_event_async(event)

    # these variables are retrieved from the settings (see _notify_settings.html.erb)
    @@broker_url = Setting.plugin_notify[:broker_url]
    @@broker_login = Setting.plugin_notify[:broker_login]
    @@broker_pwd = Setting.plugin_notify[:broker_pwd]

    Thread.new do
      uri = URI.parse(@@broker_url)

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
      request.basic_auth(@@broker_login, @@broker_pwd)
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
