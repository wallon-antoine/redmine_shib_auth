# redmine_shib_auth
UPDATE (2014-03-18)

This is an updated version of the original Adam Lantos redmine_http_auth
plugin.

This update is known to work with Redmine 2.4.x versions.

To the best of my knowledge the original functionality is complete.
(with the exception of the menu item - commented in init.rb)

Shibboleth Authentication plugin for Redmine
====

This plugin enables an optional Shibboleth authentication method in the Redmine
project management tool.

If the REMOTE_USER server environment variable is set, an attempt is
made to look up the matching local user account and log in. An attempt is made
to synchronize redmine session with the container managed authentication session,
but this can be switched off.

This module disable the form-based login

Installation
====

1) Install Service provider in your redmine server<br />
2) Enter into /your/redmine/plugins/<br />
3) git checkout https://github.com/wallon-antoine/redmine_shib_auth.git<br />
4) Edit /your/redmine/app/controllers/application_controller.rb and add after<br />
<pre><code>
      elsif params[:format] == 'atom' && params[:key] && request.get? && accept_rss_auth?
        # RSS key authentication does not start a session
        user = User.find_by_rss_key(params[:key])
</code></pre>
add this line
<pre><code>        
        #Shib_AUTH_Module
      elsif (forwarded_user = request.env["HTTP_X_REMOTE_USER_6E3RZQKX"])
</code></pre>
5) launch this command
   $ rake redmine:plugins:migrate NAME=redmine_vote RAILS_ENV=production
6) disable redmine authentication in /your/redmine/config/routes.rb

Comment this line

    #match 'login', :to => 'account#login', :as => 'signin', :via => [:get, :post]
Add this line
<pre><code>match 'httpauth-login', :to => 'account#login', :as => 'signin', :via => [:get, :post]</code></pre>

7) add this line in apache virtualhost

        <Location /httpauth-*>
        RewriteEngine     On
        RewriteCond       %{IS_SUBREQ} ^false$
        RewriteCond       %{LA-U:REMOTE_USER} (.+)
        RewriteRule ^.*$ - [E=RU:%1]
        #RewriteRule       . - [E=RU:%1]
        *RequestHeader     add X_REMOTE_USER_6E3RZQKX %{RU}e
        ShibRequestSetting requireSession On
        ShibRequestSetting applicationId default
        AuthType shibboleth
        Require valid-user
        </Location>
8) restart apache
