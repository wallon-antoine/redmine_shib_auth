require 'redmine'

Rails.logger.info 'Starting Redmine Http Shibboleth plugin for RedMine'
 
Redmine::Plugin.register :redmine_shib_auth do
  name 'HTTP Authentication plugin'
  author 'Antoine WALLON'
  url 'http://github.com/wallon-antoine/redmine_shib_auth' if respond_to?(:url)
  description 'A plugin for doing Shibboleth HTTP authentication'
  version '0.3.0-dev-redmine-2.x'


  settings :partial => 'settings/redmine_shib_auth_settings',
    :default => {
      'enable' => 'true',
      'server_env_var' => 'REMOTE_USER',
      'lookup_mode' => 'login',
      'auto_registration' => 'false',
      'keep_sessions' => 'false'
    }
end

RedmineApp::Application.config.after_initialize do
  unless ApplicationController.include? (RedmineShibAuth::ShibAuthPatch)
    ApplicationController.send(:include, RedmineShibAuth::ShibAuthPatch)
  end
end

