require_dependency 'pstore'
require_dependency 'issues_hook_listener'

Redmine::Plugin.register :notify do
  name 'Notify plugin'
  author 'mereth & jfix'
  description 'This is a plugin to send notifications to a message broker'
  version '0.1.0'
  url 'https://github.com/mereth/redmine-notify'
  author_url 'https://github.com/mereth'
  settings :default => {'empty' => true},
           :partial => 'settings/notify_settings'
end
