def post(params, session)
    text = params["content"]
    db = SQLite3::Database.new('db/database.db')
    username = db.execute("SELECT username FROM users WHERE id=?", [session["user_id"]])
    new_file_name = SecureRandom.uuid
    
    temp_file = params["image"]["tempfile"]
    path = File.path(temp_file)
    tag = params["tags"]
    new_file = FileUtils.copy(path, "./public/img/#{new_file_name}")

    db.execute('INSERT INTO posts (content, picture, userId, author) VALUES (?, ?, ?, ?)', [text, new_file_name, session['user_id'], username])
    post_id = db.execute("SELECT last_insert_rowid()")[0][0]
    
    tag.split(" ").each do |tags|
        tagId = db.execute('SELECT id FROM tags where NAME=?', tags)[0][0]
        db.execute('INSERT INTO posts_tags (tagId, postId) VALUES (?, ?)', tagId, post_id)
    end
end

def create(params)
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    existing_user = db.execute("SELECT id FROM users WHERE username=?", [params["username"]])
    
    if existing_user.length > 0
        redirect('/')
    end
    
    hashed_password = BCrypt::Password.create(params["password"])
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [params["username"], hashed_password])
    user_id = db.execute("SELECT id FROM users WHERE username=?", [params["username"]])
    
    return user_id[0]["id"]
end

def start()
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    db.execute('SELECT * FROM tags')
end

def home()
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    
    result = db.execute('SELECT * FROM posts')
    return result
end

def login(params, session)
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute("SELECT id, password FROM users WHERE username=?", [params["username"]])
    if result.length == 0
        return false
    end  
    if BCrypt::Password.new(result[0]["password"]) == params["password"]
        session["user_id"] = result[0]['id']
        return true
    else
        return false
    end
end

def profile(params)
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    
    result = db.execute('SELECT * FROM posts WHERE userId=?', params["id"])
    user = db.execute('SELECT * FROM users WHERE id=?', params["id"])[0]
    
    return result, user
end

def tags(params)
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute('SELECT posts.* FROM tags INNER JOIN posts_tags ON posts_tags.tagId = tags.id INNER JOIN posts ON posts.id = posts_tags.postId WHERE tags.id=?', params["id"])
    return result
end

def get_profile_edit(session)
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM users WHERE id=?', session["user_id"])
    return result
end

def post_profile_edit(params)
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    hashed_password = BCrypt::Password.create(params["password"])
    db.execute("REPLACE INTO users (id, username, password) VALUES (?, ?, ?)", [params["id"], params["username"], hashed_password])

end

def delete(params)
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    db.execute("DELETE FROM posts WHERE id = ?", params["post_id"])
end

def edit_post(params)
    id = params["id"]
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
   
end