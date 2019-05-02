require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require 'securerandom'

require_relative 'functions/functions'

enable :sessions

before() do
    start(@categories)
end

get('/') do
    result = home()
    slim(:index, locals:{posts: result, session: session})
end

get('/denied') do
    slim(:denied)
end

get('/accepted') do
    slim(:accepted, locals:{session: session})
end

post('/login') do
    state = login(params, session)
    if state == true
        redirect('/accepted')
    else
        redirect('/denied')
    end
end 

post('/create') do
    session["user_id"] = create(params)
    redirect('/')
end

get('/profile/:id') do
    array_values = profile(params)
    result = array_values[0]
    user = array_values[1]
    my_tags = array_values[2]
    slim(:user, locals:{posts: result, session: session, tags: my_tags, user: user})
end

get('/tags/:id/:name') do
    result = tags(params)
    slim(:topics, locals:{posts: result})
end

get('/profile/:id/edit') do

    result = get_profile_edit(session)

    if session["user_id"] == params["id"].to_i
        slim(:user_edit, locals:{user: result[0]})
    else
        slim(:denied)
    end
end

post('/profile/:id/edit') do 
    post_profile_edit(params)
    redirect('/')
end

post('/logout') do
    session.clear
    redirect('/')
end

post('/post') do
    post(params, session)
    redirect('/')
end

post('/delete') do
    delete(params)
    redirect('/')
end

 get('/edit/:id') do
     slim(:edit, locals:{id: params["id"]})
 end

post('/edit_post/:id') do
    edit_post(params)
    redirect('/')
end

get('/comments/:id') do 
    slim(:topics_comments)
end