require_dependency 'issues_hook_listener'

Redmine::Plugin.register :notify do
  name 'Notify plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end
