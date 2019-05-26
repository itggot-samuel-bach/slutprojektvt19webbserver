require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require 'securerandom'
require_relative 'functions/functions'
##include Model

enable :sessions

configure do
    set :unsecured_profile_paths, ["/profile/:id/edit"]
    set :unsecured_post_paths, ["/edit/:id", "/edit_post/:id", "/delete"]
end


set(:auth) do |*params|
    condition do
        settings.unsecured_profile_paths.each do |unsecured|
            if unsecured == request.path
                if session["id"] != params['id'].to_i
                    session[:error] = "You are not this user, stay away!"
                    return false
                end
            end
        end
        settings.unsecured_post_paths.each do |unsecured|
            if unsecured == request.path
                owner = post_owner(session)
                if session["id"] != owner
                    session[:error] = "You are not the owner of this post!"
                    return false
                end
            end
        end
    return true
    end
end

#Loads all tags 
#
before() do
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
# @see Model#Login
post('/login') do
    state = login(params)
    if state.key?(:user_id)
        session[:error] = ""
        session["user_id"] = state[:user_id] 
        redirect('/accepted')
    else
        session[:error] = state[:error]
        redirect('/')
    end
end 

#Attempts to create a user and logs in if successfull
#
# @param [String] username, The Username
# @param [String] password, The Password
#
# @see Model#Create
post('/create') do
    state = create(params)
    if state.key?(:user_id)
        session[:error] = ""
        session["user_id"] = state
        redirect('/')
    else
        session[:error] = state[:error]
        redirect('/')
    end
end

#Loads the profile page
#
get('/profile/:id') do
    result = profile(params)    
    if result.key?(:user)
        session[:error] = ""
        slim(:user, locals:{posts: result[:posts], session: session, user: result[:user]})
    else
        session[:error] = result[:error]
        redirect('/')
    end
end

#Loads the specific tags page and displays it with an id and name of the tag
#
# param [Integer]
#
get('/tags/:id/:name') do
    result = tags(params)
    if result.key?(:posts)
        slim(:topics, locals:{posts: result[:posts]})
    else
        session[:error] = result[:error]
        redirect('/')
    end
end

#Edits the currently logged in user's credentials
#
# @param [integer] id, user's id
#
# @see Model#GetProfileEdit
get('/profile/:id/edit', auth: true) do

    result = get_profile_edit(session, params)

    if result.key?(:user)
        slim(:user_edit, locals:{user: result})
    else
        session[:error] = result[:error]
        redirect('/')
    end
end

#Implements the changes done to the logged in user's credentials
#
# @param [integer] id, user's id
# @param [string] username, The Username
# @param [string] password, The Password
#
# @see Model#PostProfileEdit
post('/profile/:id/edit', auth: true ) do 
    result = post_profile_edit(params)
    if result[:error]
        session[:error] = result[:error]
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
    if session["user_id"]
        state = post(params, session['user_id'])
        if state.key?(:error)
            session[:error] = state[:error]
        end
    end 
    redirect('/')
end

post('/delete', auth: true) do
    delete(params)
    redirect('/')
end

 get('/edit/:id', auth: true) do
     slim(:edit, locals:{id: params["id"]})
 end


 # Description
 # 
 # @param [Integer] :id, Description.
 # 
 # @see Model#Function
post('/edit_post/:id', auth: true) do
    edit_post(params)
    redirect('/')
end
