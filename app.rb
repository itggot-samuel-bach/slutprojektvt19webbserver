require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require 'securerandom'

enable :sessions

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
        session["user"] = result[0]['id']
        session["username"] = params["username"]
        redirect('/accepted')
    else
        redirect('/denied')
    end
end 

post('/create') do
    #Ansluta till db
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    hashed_password = BCrypt::Password.create(params["passwordC"])
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [params["usernameC"], hashed_password])

    redirect('/')
end

get('/profile/:id') do

    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true

    result = db.execute('SELECT * FROM posts WHERE userId=?', params["id"])
    
    slim(:user, locals:{posts: result, session: session, user: params["id"]})

end

get('/profile/:id/edit') do

    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    
    result = db.execute('SELECT * FROM users WHERE username=?', session["username"])

    if session["username"] == params["id"]
        slim(:user_edit, locals:{user: result[0], session: session})
    else
        slim(:denied)
    end

end

post('/profile/:id/edit') do 
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    hashed_password = BCrypt::Password.create(params["password"])
    db.execute("REPLACE INTO users (id, username, password) VALUES (?, ?, ?)", [params["user_id"], params["username"], hashed_password])

    redirect('/')


end

post('/logout') do
    session.clear
    redirect('/')
end

post('/post') do
    text = params["content"]
    db = SQLite3::Database.new('db/database.db')

    username = db.execute("SELECT username FROM users WHERE id=?", [session["user"]])

    new_file_name = SecureRandom.uuid
    temp_file = params["image"]["tempfile"]
    path = File.path(temp_file)
    
    new_file = FileUtils.copy(path, "./public/img/#{new_file_name}")

    db.execute('INSERT INTO posts (content, picture, userId) VALUES (?, ?, ?)', [text, new_file_name, username])

    redirect('/')

end

post('/delete') do
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true

    db.execute("DELETE FROM posts WHERE id = ?", params["post_id"])

    redirect('/')
end

get('/edit/:id') do
    slim(:edit, locals:{id: params["id"]})
end

post('/edit_post') do
    text = params["content"]
    post_ident = params["post_id"]
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    
    new_file_name = SecureRandom.uuid
    temp_file = params["image"]["tempfile"]
    path = File.path(temp_file)
    
    new_file = FileUtils.copy(path, "./public/img/#{new_file_name}")

    db.execute('REPLACE INTO posts (id, content, picture, userId) VALUES (?, ?, ?, ?)', [post_ident, text, new_file_name, session["username"]])
   
    redirect('/')

end