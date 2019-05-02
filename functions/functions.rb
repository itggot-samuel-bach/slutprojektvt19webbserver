def post(params, session)
    text = params["content"]
    db = SQLite3::Database.new('db/database.db')

    username = db.execute("SELECT username FROM users WHERE id=?", [session["user_id"]])

    new_file_name = SecureRandom.uuid
    temp_file = params["image"]["tempfile"]
    path = File.path(temp_file)
    tag = params["tag"]
    tag_id = db.execute("SELECT id FROM tags WHERE name=?", tag)[0]

    new_file = FileUtils.copy(path, "./public/img/#{new_file_name}")

    db.execute('INSERT INTO posts (content, picture, userId, tag, author) VALUES (?, ?, ?, ?, ?)', [text, new_file_name, session['user_id'], tag_id, username])
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

