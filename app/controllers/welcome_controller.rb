# Land us at the root of the App
class WelcomeController < ApplicationController

  unloadable
  include ShibAuthHelper
  helper :shib_auth
  before_filter :remote_user_set

  def index
    @news = News.latest User.current
    @projects = Project.latest User.current
  end

end
