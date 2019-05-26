require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require 'securerandom'
require_relative 'functions/functions'
include Model

enable :sessions

configure do 
    set :unsecured_profile_paths, [/\/profile\/\d+\/edit/]
    set :unsecured_post_paths, [/\/edit\/\d+/, /\/edit_post\/\d+/, /\/delete/]
end

set(:auth) do |*args|
    condition do
        if session["user_id"].nil?
            session[:error] = "You are not logged in!"
            redirect('/')
        end
        settings.unsecured_profile_paths.each do |unsecured|
            if !(unsecured =~ request.path).nil?
                if session["user_id"] != params['id'].to_i
                    session[:error] = "You are not this user, stay away!"
                    redirect('/')
                end
            end
        end
        settings.unsecured_post_paths.each do |unsecured|
            if !(unsecured =~ request.path).nil?
                owner = post_owner(params)
                if session["user_id"] != owner
                    session[:error] = "You are not the owner of this post!"
                    redirect('/')
                end
            end
        end
        return true
    end
end
# Loads all the tags on a specific page
#
# @see Model#start
get('/tags') do
    tags = start()
    slim(:tags, locals: {tags: tags})
end

# Display Landing Page
#
# @see Model#home
get('/') do
    result = home()
    slim(:index, locals:{posts: result, session: session})
end

# Loads the denied page
#
get('/denied') do
    slim(:denied)
end

#Loads the accepted page
#
get('/accepted') do
    slim(:accepted, locals:{session: session})
end

# Attempts login and updates the session["user_id"] if a login is sucessfull. If it is unsucessfull it will display an error.
#
# @param [String] username, The Username
# @param [String] password, the Password
# @param [String] password2, the Password repeated
# @see Model#login
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

# Creates a user if there is not an already existing user with the same name. If another user exists an error message will be display.
#
# @param [String] username, The Username
# @param [String] password, the Password
# @param [String] password2, the Password repeated
# @see Model#create
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

# Loads the profile page if a user with such an id requested exists. If a user does not exist an error will be displayed.
#
# @param [Integer] id, The id of the user
# @see Model#profile
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

# Loads the specific tags page and displays it with an id and name of the tag. If the tag id does not exist an error will be displayed.
#
# @param [Integer] id, The id of the tag
# @see Model#tags
get('/tags/:id/:name') do
    result = tags(params)
    if result.key?(:posts)
        slim(:topics, locals:{posts: result[:posts]})
    else
        session[:error] = result[:error]
        redirect('/')
    end
end

# Edits the currently logged in user's credentials if the logged in user is the owner of the attempted user being edited. If not, an error will be displayed.
#
# @param [Integer] id, The user's id of which is being attempted to edit. 
# @see Model#get_profile_edit
get('/profile/:id/edit', auth: true) do

    result = get_profile_edit(session, params)

    if result.key?(:user)
        slim(:user_edit, locals:{user: result[:user][0]})
    else
        session[:error] = result[:error]    
        redirect('/')
    end
end

# Implements the changes done to the logged in user's credentials if the previous request was sucessfull. 
#
# @param [integer] id, user's id
# @param [string] username, The Username
# @param [string] password, The Password
#
# @see Model#post_profile_edit
post('/profile/:id/edit', auth: true ) do 
    result = post_profile_edit(params)
    if result.key?(:error)
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

# Posts a post by a user if the user is logged in. If a user is not logged in, an error will be displayed.
#
# @param [String] tags, the name of the tag.
# @param [String] image, the image in raw data. 
# @param [String] content, the raw text of the post. 
# @see Model#post
post('/post') do
    if session["user_id"]
        state = post(params, session['user_id'])
        if state.key?(:error)
            session[:error] = state[:error]
        end
    end 
    redirect('/')
end
# Deletes a post if the user is the owner of the post and logged in. If the statements are not fulfilled, an error will show up. 
#
# @param [Integer] id, the id of the post.
# @see Model#delete
post('/delete', auth: true) do
    delete(params, session)
    redirect('/')
end 

# Calls for the page that allows one to edit a post. If the user is not logged in or does not own the right to edit the post, an error will be displayed.
#
# @param [Integer] id, the id of the post.
# @param [String] image, the image in raw data. 
# @param [String] content, the raw text of the post. 
# 
get('/edit/:id', auth: true) do
    slim(:edit, locals:{id: params["id"]})
end


# Completes the action request before and once again checks if the user is logged in on the owner of the post's account. If not, an error will be displayed.
# 
# @param [Integer] id, the id of the post.
# @param [String] image, the image in raw data. 
# @param [String] content, the raw text of the post. 
# @see Model#edit_post
post('/edit_post/:id', auth: true) do
    edit_post(params)
    redirect('/')
end
