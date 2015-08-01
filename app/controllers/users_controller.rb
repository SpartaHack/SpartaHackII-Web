class UsersController < ApplicationController
	require 'parse_config'
  require 'monkey_patch'
  def new
    cookies.delete :spartaUser
  	@user = User.new
  	@error = flash[:error]
  end

  #create a user and redirect them to application process
  def create
    if user_signup_params['password'] == user_signup_params['password_confirmation']
    	begin
				signup = Parse::User.new({
				  :username => user_signup_params['username'],
				  :email => user_signup_params['email'],
				  :password => user_signup_params['password'],
				})
				response = signup.save
				cookies.signed[:spartaUser] = { value: response["objectId"], expires: (Time.now.getgm + 86400) }
				redirect_to '/app'	
			rescue Parse::ParseProtocolError => e
				if e.to_s.split(":").first == '202'
			  	flash[:error] = "Username is taken"
			  elsif e.to_s.split(":").first == "203"
			  	flash[:error] = "Email is taken"
			  end
			  redirect_to '/signup'
			end
			
    else
    	flash[:error] = "Passwords do not match"
      redirect_to '/signup'
    end
  end

  def login
    if cookies.signed[:spartaUser]
      redirect_to '/app'
    end
  	@user = User.new
  end

  # authenticate user and redirect them to their application
  def auth
  	begin
			login = Parse::User.authenticate(user_login_params['username'],user_login_params['password'])
      cookies.signed[:spartaUser] = { value: login["objectId"], expires: (Time.now.getgm + 86400) }
			redirect_to '/app'	
		rescue Parse::ParseProtocolError => e
			if e.to_s.split(":").first == '101'
		  	flash[:error] = "Username or password is incorrect"
		  	redirect_to '/login'
		  end
		end

  end  

  def app
    if !cookies.signed[:spartaUser]
      flash[:error] = "Please sign up to create an application."
      redirect_to '/signup'
    else
      begin
        @application = Parse::Query.new("Application").tap do |q|
          q.eq("userId", Parse::Pointer.new({
            "className" => "_User",
            "objectId"  => cookies.signed[:spartaUser]
          }))
        end.get
      rescue Parse::ParseProtocolError => e
        flash[:error] = e.message
        redirect_to '/login'
      end
    end
  end


  def save
    begin
      fields = [ "firstName", "lastName", "gender", "dob", "university", 
                                "gradeLevel", "github", "linkedIn", "website", "favProj"]

      application = Parse::Query.new("Application").tap do |q|
                      q.eq("userId", Parse::Pointer.new({
                        "className" => "_User",
                        "objectId"  => cookies.signed[:spartaUser]
                      }))
                    end.get.first
      if !application
        application = Parse::Object.new("Application")
      end
      fields.each do |field|
        application[field] = user_app_params[field]
      end
      application["firstHackathon"] = user_app_params["firstHackathon"].to_bool
      response = application.save

      application = Parse::Query.new("Application").eq("objectId", response["objectId"]).get.first
      user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser]).get.first
      application.array_add_relation("userId", user.pointer)
      application.save
      redirect_to '/app'  
    rescue Parse::ParseProtocolError => e
      flash[:error] =  e.message
      redirect_to '/signup'
    end

  end    

  private

    def user_signup_params
      params.require(:user).permit(:username, :email, :password,
                                   :password_confirmation)
    end

    def user_app_params
      params.permit(:firstName, :lastName,
                                   :gender, :dob, :firstHackathon, 
                                   :university, :gradeLevel, :github, 
                                   :linkedIn, :website, :favProj)
    end

    def user_login_params
      params.require(:user).permit(:username, :password)
    end
end