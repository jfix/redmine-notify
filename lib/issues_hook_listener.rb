
class IssuesHookListener < Redmine::Hook::Listener
  @@broker_url = 'http://localhost:8161/api/message/redmine?type=topic'

  # catch new tickets
  def controller_issues_new_after_save(context = {})
    issue = context[:issue]

    event = {
      :type => "creation",
      :issue => issue.id,
      :project_id => issue.project.id,
      :priority => issue.priority.id
    }

    send_event(event)
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
      :issue => issue.id,
      :project_id => issue.project.id,
      :priority => issue.priority.id,
      :old_status => statusChange.old_value,
      :new_status => statusChange.value
    }
    send_event(event)
  end

  # method to send the event to the message broker
  def send_event(event)
    Thread.new do
      uri = URI.parse(@@broker_url)
      request = Net::HTTP::Post.new(uri, {'Content-Type' => 'application/json'})
      request.body = event.to_json
      request.basic_auth("admin", "admin")

      http = Net::HTTP.new(uri.host, uri.port)
      http.request(request)
    end
  end
end
