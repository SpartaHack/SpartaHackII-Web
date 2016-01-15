class AdminController < ApplicationController
  require 'mailchimp'
  require 'parse_config'
  require 'monkey_patch'
  require 'pp'

  def admin
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship" || cookies.signed[:spartaUser][1] == "statistics"
        @user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    @users_total = Parse::Query.new("_User").tap do |q|
      q.limit = 1000
    end.get.length

    @users_total += Parse::Query.new("_User").tap do |q|
                      q.limit = 1000
                      q.skip = 1000
                    end.get.length
    
    @apps_total = Parse::Query.new("Application").tap do |q|
      q.limit = 1000
    end.get.length

     @apps_total += Parse::Query.new("Application").tap do |q|
                      q.limit = 1000
                      q.skip = 1000
                    end.get.length

    render layout: false
  end

  def sponsorship
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    @sponsors = []

    companies = Parse::Query.new("Company").get

    companies.each do |c|
        @sponsors.push([c["objectId"], c["name"]])
    end

    render layout: false
  end

  def addsponsor
    logo = add_sponsor_params['picture']

    photo = Parse::File.new({
      :body => logo.read,
      :local_filename => logo.original_filename,
      :content_type => logo.content_type,
      :content_length => logo.tempfile().size().to_s
    })
    photo.save

    company = Parse::Object.new("Company")
    company['name'] = add_sponsor_params['name']
    company['url'] = add_sponsor_params['url']
    company['img'] = photo
    company['level'] = add_sponsor_params['level']

    company.save

    redirect_to '/admin'

  end

  def viewsponsor
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    object = view_sponsor_params['object']
    @sponsor = Parse::Query.new("Company").eq("objectId", object).get[0]

    render layout: false

  end

  def editsponsor 
    company = Parse::Query.new("Company").eq("objectId", edit_sponsor_params['object']).get.first
    
    if edit_sponsor_params["commit"] == "Delete"
      company.parse_delete
    else

      if edit_sponsor_params["picture"]
        logo = edit_sponsor_params['picture']
        photo = Parse::File.new({
          :body => logo.read,
          :local_filename => logo.original_filename,
          :content_type => logo.content_type,
          :content_length => logo.tempfile().size().to_s
        })
        photo.save
        company['img'] = photo
      end

      company['name'] = edit_sponsor_params['name']
      company['url'] = edit_sponsor_params['url']
      company['level'] = edit_sponsor_params['level']

      company.save
    end

    redirect_to '/admin'

  end

  def applications
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end
    
    @apps = Parse::Query.new("Application").tap do |q|
      q.limit = 1000
    end.get

    @apps += Parse::Query.new("Application").tap do |q|
      q.skip = 1000
      q.limit = 1000
    end.get

    pp @apps

    render layout: false
  end

  def app_status 
      app = Parse::Query.new("Application").eq("objectId", status_params["object"]).get.first
      if !status_params["status-select"].blank?
        app['status'] = status_params["status-select"]
      else
        app['status'] = nil
      end
      app.save
  end

  def stats
    # Only allow admins to view
    if cookies.signed[:spartaUser]
      if cookies.signed[:spartaUser][1] == "admin" || cookies.signed[:spartaUser][1] == "sponsorship" || cookies.signed[:spartaUser][1] == "statistics"
        user = Parse::Query.new("_User").eq("objectId", cookies.signed[:spartaUser][0]).get.first
      else
        flash[:error] = "You're not an admin."
        redirect_to '/login' and return
      end
    else
      redirect_to '/login' and return
    end

    # Gets all applications
    @apps = Parse::Query.new("Application").tap do |q|
      q.limit = 1000
    end.get

    @apps += Parse::Query.new("Application").tap do |q|
      q.skip = 1000
      q.limit = 1000
    end.get

    def age(dob,diq)
      diq = diq.to_date
      diq.year - dob.year - ((diq.month > dob.month || (diq.month == dob.month && diq.day >= dob.day)) ? 0 : 1)
    end


    # gender count [male, female, nonbinary]
    @gender_count = {"male"=>0, "female"=>0, "non-binary"=>0, "prefer-not"=>0}

    # Hash of university => attendee count
    @uni_applicants = {"High School"=>0};
    @international_count=0;

    # Age
    @age_count = { };
    @minor_count = 0;
    @adult_count = 0;

    # Get date of hackathon: feb 26
    @start_date = Date.new(2016, 2, 26)

    @total_apps = @apps.length

    # First Year, Second Year, Third Year, Fourth Year, Fifth Year, Graduate Student, Not a Student
    @uni_grade_count = {"First Year"=>0,"Second Year"=>0,"Third Year"=>0,"Fourth Year"=>0,"Fifth Year +"=>0,"Graduate Student"=>0,"High School Student"=>0, "Not a Student"=>0};

    # Majors
    @major_count = {};

    # Number Hackathons attended
    # { number => frequency }
    @hackathons_count = {0=>0,1=>0,2=>0,3=>0,4=>0,5=>0,6=>0,7=>0,8=>0,9=>0,10=>0,11=>0,12=>0,13=>0,14=>0,15=>0}

    @hackathons_attended = {}

    @submission_dates = {}

    # Start huge loop
    @apps.each do |app|
      # Gender
      if !app['gender'].blank? && !@gender_count[app['gender']].blank?
        @gender_count[app['gender']]+=1;
      else
        @gender_count["nonbinary"]+=1;
      end

      # Universities
      if !app['university'].blank?
        if !(app["university"][0..2] =="USA")
          @international_count += 1
        end
        if @uni_applicants[ app['university'] ]
          @uni_applicants[ app['university'] ] += 1
        else
          @uni_applicants[ app['university'] ] = 1
        end
      else
        if !app['otherUniversity'].blank?
          if @uni_applicants[ app['otherUniversity'] ]
            @uni_applicants[ app['otherUniversity'] ] += 1
          else
            @uni_applicants[ app['otherUniversity'] ] = 1
          end
        else
          @uni_applicants['High School'] += 1
        end
      end

      # Ages
      if !app['birthyear'].blank?
        curr_bday = Time.zone.local(app['birthyear'].to_i, Date::MONTHNAMES.index(app['birthmonth'].to_i), app['birthday'].to_i, 0, 0)
        if age(curr_bday, @start_date) < 18
          @minor_count+=1
        else
          @adult_count+=1
        end
        if !@age_count[age(curr_bday, @start_date)].blank?
          @age_count[ age(curr_bday, @start_date) ] += 1
        else
          @age_count[ age(curr_bday, @start_date) ] = 1
        end
      end

      # Grade level
      if app['universityStudent'] == 'true'
        if !app['gradeLevel'].blank?
          if !@uni_grade_count[app['gradeLevel']].blank?
            @uni_grade_count[ app['gradeLevel'] ] += 1
          else
            @uni_grade_count[ app['gradeLevel'] ] = 1
          end
        end
      else
        @uni_grade_count['High School Student'] += 1
      end

      # Majors
      if !app['major'].blank?
        app['major'].each do |major|
          if !@major_count[major].blank?
            @major_count[major] += 1
          else
            @major_count[major] = 1
          end
        end
      end

      # Hackathons
      if !app['hackathons'].blank?
        if !@hackathons_count[app['hackathons'].length].blank?
          @hackathons_count[ app['hackathons'].length ] += 1
        else
          @hackathons_count[ app['hackathons'].length ] = 1
        end
      else
        @hackathons_count[ 0 ] += 1
      end

      if !app['hackathons'].blank?
        app['hackathons'].each do |hackathon|
          if !@hackathons_attended[hackathon].blank?
            @hackathons_attended[hackathon] += 1
          else
            @hackathons_attended[hackathon] = 1
          end
        end
      end

      # Applications per day
      current_day = ( Time.parse(app['createdAt']) - 9*3600).strftime("%d-%b-%y")
      if !@submission_dates[ current_day ].blank?
        @submission_dates[ current_day ] += 1
      else
        @submission_dates[ current_day ] = 1
      end

    # End huge loop

    end

    # Random reason for wanting to attend SpartaHack
    # [reason, first name, last name]
    @random_reason = ["","",""]
    @random_num = rand(0..( @apps.length-1 ))
    while ( @apps[@random_num]["whyAttend"].blank?)
      @random_num = rand(0..( @apps.length-1 ))
    end
    @random_reason[0] = @apps[@random_num]["whyAttend"]
    @random_reason[1] = @apps[@random_num]["firstName"]
    @random_reason[2] = @apps[@random_num]["lastName"]   

    @submission_array = []

    @submission_dates.each do |submission|
      @submission_array.push({"date" => submission[0], "close" => submission[1]})
    end

    # Sorting
    @age_count = @age_count.sort_by {|value, _key| value}
    @uni_applicants = @uni_applicants.sort_by {|_key, value| value}.reverse
    @major_count = @major_count.sort_by {|_key, value| value}.reverse
    @hackathons_count = @hackathons_count.sort_by {|value,_key| value}
    @hackathons_attended = @hackathons_attended.sort_by {|_key, value| value}.reverse

    # Find most common words for word map
    def most_common(str)
      str.gsub(/./) do |c|
        case c
        when /\w/ then c.downcase
        when /\s/ then c
        else ''
        end
      end.split
         .group_by {|w| w}
         .map {|k,v| [k,v.size]}
         .sort_by(&:last)
         .reverse
         .to_h
    end

    @master_string = ""

    @apps.each do |app|
      if !app['whyAttend'].blank?
        @master_string += " " + app['whyAttend']
      end
    end
    @common_words = most_common(@master_string)

    most_common_words = ["the", "be", "to", "of", "and", "a", "in", "that", "have", "i", "it", "for", "not", "on", "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from", "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would", "there", "their", "what", "so", "up", "out", "if", "about", "who", "get", "which", "go", "me", "when", "make", "can", "like", "time", "no", "just", "him", "know", "take", "person", "into", "year", "your", "good", "some", "could", "them", "see", "other", "than", "then", "now", "look", "only", "come", "its", "over", "think", "also", "back", "after", "use", "two", "how", "our", "work", "first", "well", "way", "even", "new", "want", "because", "any", "these", "give", "day", "most", "us", "im", "ive", "id", "am"]

    most_common_words.each do |word|
      @common_words.delete(word)
    end

    @common_words = @common_words.sort_by {|_key, value| value}.reverse


    # RSVP setup
    @rsvp_status = true;
    # Gets all rsvps
    @rsvps = Parse::Query.new("RSVP").tap do |q|
      q.limit = 1000
    end.get

    @rsvps_count = @rsvps.length

  end

  def send_emails
    if email_params['type'] == 'decision'
      @applications = Parse::Query.new("Application").tap do |q|
        q.eq("emailStatus", nil)
        q.include = "user"
      end.get

      @applications.each do |app|

        if app['status'] == "Accepted"
          UserMailer.notify_of_status(app["firstName"], app["user"]['email']).deliver_now
          app['emailStatus'] = true
          app.save
        end

      end
    elsif email_params['type'] == "empty_app"
      users_with_apps = []
      
      @applications = Parse::Query.new("Application").tap do |q|
        q.include = "user"
      end.get

      @applications.each do |app|
        users_with_apps.push(app["user"]['email'])
      end

      @users = Parse::Query.new("_User").tap do |q|
        q.value_not_in("email", users_with_apps)
      end.get

      @users.each do |user|
          UserMailer.notify_of_empty_app(user['email']).deliver_now
      end
    end

  end

      # @applications = Parse::Query.new("Application").tap do |q|
      #   q.eq("emailStatus", nil)
      # end.get

      # @applications.each do |app|
      #   user = Parse::Query.new("_User").tap do |q|
      #             q.related_to("userId", Parse::Pointer.new({
      #               "className" => "Application",
      #               "objectId" => app["objectId"]
      #             }))
      #           end.get.first

      #   app['user'] = user.pointer
      #   app.save
      # end

  private

  def add_sponsor_params
    params.permit(:picture, :name, :url, :level)
  end   

  def edit_sponsor_params
    params.permit(:picture, :name, :url, :level, :commit, :object)
  end   

  def view_sponsor_params
    params.permit(:object)
  end   

  def status_params
    params.permit(:object, :"status-select")
  end 

  def email_params
    params.permit(:object, :"type")
  end 

end