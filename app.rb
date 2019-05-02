require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require 'securerandom'

require_relative 'functions/functions'

enable :sessions

before() do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    
    @categories = db.execute('SELECT * FROM tags')
end

get('/') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    
    result = db.execute('SELECT * FROM posts')

    slim(:index, locals:{posts: result, session: session})
end

get('/denied') do
    slim(:denied)
end


get('/accepted') do
    slim(:accepted, locals:{session: session})
end

post('/login') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    
    result = db.execute("SELECT id, password FROM users WHERE username=?", [params["username"]])
    if result.length == 0
        redirect('/denied')
    end  
    if BCrypt::Password.new(result[0]["password"]) == params["password"]
        session["user_id"] = result[0]['id']
        redirect('/accepted')
    else
        redirect('/denied')
    end
end 

post('/create') do
    #Ansluta till db
    session["user_id"] = create(params)
    redirect('/')
end

get('/profile/:id') do

    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true

    result = db.execute('SELECT * FROM posts WHERE userId=?', params["id"])
    user = db.execute('SELECT * FROM users WHERE id=?', params["id"])[0]
    
    slim(:user, locals:{posts: result, session: session, user: user})

end

get('/tags/:id/:name') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true

    result = db.execute('SELECT * FROM posts WHERE tag=?', params["id"])

    slim(:topics, locals:{posts: result})
end

get('/profile/:id/edit') do

    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    
    result = db.execute('SELECT * FROM users WHERE id=?', session["user_id"])

    if session["user_id"] == params["id"].to_i
        slim(:user_edit, locals:{user: result[0]})
    else
        slim(:denied)
    end

end

post('/profile/:id/edit') do 
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true

    hashed_password = BCrypt::Password.create(params["password"])
    db.execute("REPLACE INTO users (id, username, password) VALUES (?, ?, ?)", [params["id"], params["username"], hashed_password])

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
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true

    db.execute("DELETE FROM posts WHERE id = ?", params["post_id"])

    redirect('/')
end

# get('/edit/:id') do
#     slim(:edit, locals:{id: params["id"]})
# end

post('/edit_post/:id') do
    id = params["post_id"]
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
   
    if params.key?("image") and params["image"]
        temp_file = params["image"]["tempfile"]
        new_file_name = SecureRandom.uuid
        path = File.path(temp_file)
        new_file = FileUtils.copy(path, "./public/img/#{new_file_name}")
        db.execute("UPDATE posts SET picture=? WHERE id=?", new_file_name, id)
    end
    
    if params.key?("content") and params["content"].length > 1
        db.execute("UPDATE posts SET content=? WHERE id=?", [params["content"], id])
    end
   
    redirect('/')

end

get('/comments/:id') do 
    slim(:topics_comments)
end