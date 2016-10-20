require_dependency 'issues_hook_listener'

Redmine::Plugin.register :notify do
  name 'Notify plugin'
  author 'mereth & jfix'
  description 'This is a plugin to send notifications to a message broker'
  version '0.0.7'
  url 'https://github.com/mereth/redmine-notify'
  author_url 'https://github.com/mereth'
end
