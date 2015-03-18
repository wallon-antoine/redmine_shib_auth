module RedmineShibAuth
  module ShibAuthPatch
    unloadable
    
    def self.included(base)
      base.send(:include, ClassMethods)
      base.class_eval do
        #avoid infinite recursion in development mode on subsequent requests
        alias_method :find_current_user,
          :find_current_user_without_httpauth if method_defined? 'find_current_user_without_httpauth'
        #chain our version of find_current_user implementation into redmine core
        alias_method_chain(:find_current_user, :httpauth)
      end
    end
  
    module ClassMethods
      include ShibAuthHelper
  
      def find_current_user_with_httpauth
        #first proceed with redmine's version of finding current user
        user = find_current_user_without_httpauth
        #if the http_auth is disabled in config, return the user
        return user unless Setting.plugin_redmine_shib_auth['enable'] == "true"
  
        remote_username = request.env['REMOTE_USER']
	### Debug
	#if logger && logger.info
	#    logger.info request.headers
  	#end
	##

        if remote_username.nil?
          #do not touch user, if he didn't use http authentication to log in
          #or if the keep_sessions configuration directive is set
          if !used_http_authentication? || Setting.plugin_redmine_shib_auth['keep_sessions'] == "true"
            return user
          end
          #log out previously authenticated user
          reset_session
          return nil
        end
  
        #return if the user has not been changed behind the session
        return user unless session_changed? user, remote_username
  
        #log out current logged in user
        reset_session
        try_login remote_username
      end
  
      def try_login(remote_username)
        #find user by login name or email address
        if use_email?
          user = User.active.find_by_mail remote_username

        else
          user = User.active.find_by_login remote_username

        end
        if user.nil?
          #user was not found in the database, try selfregistration if enabled
          if Setting.plugin_redmine_shib_auth['auto_registration'] == 'true'
	    #@user = User.new({:firstname given_name, :lastname sn, :mail remote_username, :language "fr" } )
		user = User.new({:mail => remote_username, :firstname => given_name, :lastname => sn, :language => "fr"})
		user.login = remote_username
	    	user.valid?
		user.save
		if user.save
		      reset_session
		      do_login remote_username
		      redirect_to "/httpauth-login"
		end
         	#redirect_to httpauthselfregister_url

            
            return nil
          else
            flash[:error] = l :error_unknown_user
            return nil
          end
        else
          #login and return user if user was found
          do_login user
        end
      end
  
      def used_http_authentication?
        session[:http_authentication] == true
      end
  
      def use_email?
        Setting.plugin_redmine_shib_auth['lookup_mode'] == 'mail'
      end
  
      def session_changed?(user, remote_username)
        if user.nil?
          true
        else
          use_email? ? user.mail.casecmp(remote_username) != 0 : user.login.casecmp(remote_username) != 0
        end
      end
  
      def do_login(user)
        if (user && user.is_a?(User))
          session[:user_id] = user.id
          session[:http_authentication] = true
	  # AW
	  session[:ctime] = Time.now.utc.to_i
	  session[:atime] = Time.now.utc.to_i
	  # FIN
          user.update_attribute(:last_login_on, Time.now)
          User.current = user
  	  #redirect_to home_url
  	  logger.info "Successful authentication for '#{user.login}'"
  	  redirect_back_or_default home_url
        else
          return nil
        end
      end
    end
  end
end
