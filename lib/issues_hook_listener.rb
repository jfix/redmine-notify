
class IssuesHookListener < Redmine::Hook::Listener
  def controller_issues_edit_after_save(context = {})
    issue = context[:issue]
	journal = context[:journal]
	
	statusChange = journal.detail_for_attribute('status_id')
	
	if statusChange.nil?
		return
	end
	
	event = {:issue => issue.id,:old_status => statusChange.old_value,:new_status => statusChange.value}
	
	Thread.new do
		uri = URI.parse('http://httpbin.org/post')
		request = Net::HTTP::Post.new(uri, {'Content-Type' => 'application/json'})
		request.body = event.to_json
		
		http = Net::HTTP.new(uri.host, uri.port)
		http.request(request)
	end
  end

end
