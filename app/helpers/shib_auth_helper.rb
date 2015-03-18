module ShibAuthHelper
  unloadable
  
  def httpauthselfregister_url
    httpauthselfregister_url = "/httpauth-selfregister"
  end

  def home_url
	home_url = "/"
  end

  def user_attributes
    ['login', 'mail', 'firstname', 'lastname']
  end

  def use_email?
    Setting.plugin_redmine_shib_auth['lookup_mode'] == 'mail'
  end

  def set_default_attributes(user)
    user_attributes.each do |attr|
      user.send(attr + "=", (get_attribute_value attr))
    end
  end

  def set_readonly_attributes(user)
    user_attributes.each do |attr|
      user.send(attr + "=", (get_attribute_value attr)) if readonly_attribute? attr
    end
  end

  def remote_user
    #Rails.logger.debug "attempting to build remote-user http remote: #{request.env['HTTP_X_REMOTE_USER_6E3RZQKX']}"
    #request.env['HTTP_REMOTE_USER'] || request.headers['X-Forwarded-User']
    request.env[Setting.plugin_redmine_shib_auth['server_env_var']]
  end
  # Given Name shibb
  def given_name
    request.env[Setting.plugin_redmine_shib_auth['givenName']]
  #  request.env['givenName']
  end
  # sn
  def sn
  request.env[Setting.plugin_redmine_shib_auth['sn']]
  #request.env['sn']
  end

  def readonly_attribute?(attribute_name)
    if remote_user_attribute? attribute_name
      true
    else
      conf = Setting.plugin_redmine_shib_auth['readonly_attribute']
      if conf.nil? || !conf.has_key?(attribute_name)
        false
      else
        conf[attribute_name] == "true"
      end
    end
  end

  private
  def remote_user_attribute?(attribute_name)
    (attribute_name == "login" && !use_email?) || (attribute_name == "mail" && use_email?)
  end

  def get_attribute_value(attribute_name)
    if remote_user_attribute? attribute_name
      remote_user
    else
      conf = Setting.plugin_redmine_shib_auth['attribute_mapping']
      if conf.nil? || !conf.has_key?(attribute_name)
        nil
      else
        request.env[conf[attribute_name]]
      end
    end
  end

end
