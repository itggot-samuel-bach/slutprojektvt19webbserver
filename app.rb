require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require 'securerandom'
require 'byebug'
require_relative 'functions/functions'

enable :sessions

configure do
    set :unsecured_paths, ['/create, /profile/:id/edit, /edit/:id, /edit_post/:id']
end

#Loads all tags
#
before() do
    request.path
    - unsecured_paths.each do |unsecured|
        if unsecured = request.path 
            if session["id"] == 
        end
    end
    @categories = start()
end

# Display Landing Page
#
get('/') do
    result = home()
    slim(:index, locals:{posts: result, session: session})
end

#Loads the denied page
#
get('/denied') do
    slim(:denied)
end

#Loads the accepted page
#
get('/accepted') do
    slim(:accepted, locals:{session: session})
end

#Attempts login and updates the session
#
# @param [String] username, The Username
# @param [String] password, the Password
# @see Functions#Login
post('/login') do
    state = login(params, session)
    if state == true
        redirect('/accepted')
    else

        redirect('/')
    end
end 

#Attempts to create a user and logs in if successfull
#
# @param [String] username, The Username
# @param [String] password, The Password
#
# @see Functions#Create
post('/create') do
    session["user_id"] = create(params)
    redirect('/')
end

#Loads the profile page
#
get('/profile/:id') do
    result,user,my_tags = profile(params)
    slim(:user, locals:{posts: result, session: session, tags: my_tags, user: user})
end

#Loads the specific tags page and displays it with an id and name of the tag
#
# param [Integer] 
#
get('/tags/:id/:name') do
    result = tags(params)
    slim(:topics, locals:{posts: result})
end

#Edits the currently logged in user's credentials
#
# @param [integer] id, user's id
#
# @see Functions#GetProfileEdit
get('/profile/:id/edit') do

    result = get_profile_edit(session)

    if session["user_id"] == params["id"].to_i
        slim(:user_edit, locals:{user: result[0]})
    else
        slim(:denied)
    end
end

#Implements the changes done to the logged in user's credentials
#
# @param [integer] id, user's id
# @param [string] username, The Username
# @param [string] password, The Password
#
# @see Functions#PostProfileEdit
post('/profile/:id/edit') do 
    result = post_profile_edit(params)
    if result[:error]
        session[:error] = result[:message]
    else
        redirect('/')
    end
end

#Logs out the user
#
post('/logout') do
    session.clear
    redirect('/')
end

#Posts a post by a user
#
# @param []
post('/post') do
    post(params, session['user_id'])
    redirect('/')
end

post('/delete') do
    delete(params)
    redirect('/')
end

 get('/edit/:id') do
     slim(:edit, locals:{id: params["id"]})
 end


 # Description
 # 
 # @param [Integer] :id, Description.
 # 
 # @see Model#Function
post('/edit_post/:id') do
    edit_post(params)
    redirect('/')
end
