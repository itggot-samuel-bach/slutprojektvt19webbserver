module Model
    def post(params, user_id)
        if validate_create_post(params)
            text = params["content"]
            db = SQLite3::Database.new('db/database.db')
            username = db.execute("SELECT username FROM users WHERE id=?", [session["user_id"]])
            new_file_name = SecureRandom.uuid
            
            temp_file = params["image"]["tempfile"]
            path = File.path(temp_file)
            tag = params["tags"]
            new_file = FileUtils.copy(path, "./public/img/#{new_file_name}")
            
            db.execute('INSERT INTO posts (content, picture, userId, author) VALUES (?, ?, ?, ?)', [text, new_file_name, user_id, username])
            post_id = db.execute("SELECT last_insert_rowid()")[0][0]
            
            tag.split(" ").each do |tags|
                tagId = db.execute('SELECT id FROM tags where NAME=?', tags)
                if not tagId.empty?
                    db.execute('INSERT INTO posts_tags (tagId, postId) VALUES (?, ?)', tagId[0][0], post_id)
                end
            end
        else
            return false
        end
    end

    def create(params)
        if validate_create_user(params)
            db = SQLite3::Database.new('db/database.db')
            db.results_as_hash = true
            existing_user = db.execute("SELECT id FROM users WHERE username=?", [params["username"]])
            
            if existing_user.length > 0
                return false
            end
            
            hashed_password = BCrypt::Password.create(params["password"])
            db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [params["username"], hashed_password])
            user_id = db.execute("SELECT id FROM users WHERE username=?", [params["username"]])
            return user_id[0]["id"]
        else
            return false
        end
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

    def login(params)
        if validate_login_user(params)
            db = SQLite3::Database.new('db/database.db')
            db.results_as_hash = true
            result = db.execute("SELECT id, password FROM users WHERE username=?", [params["username"]])
            if result.length == 0
                return false
            end  
            if BCrypt::Password.new(result[0]["password"]) == params["password"]
                return result[0]['id']
            else
                return false
            end
        else
            return false
        end
    end

    def profile(params)
        if validate_profile_and_tags(params)
            db = SQLite3::Database.new('db/database.db')
            db.results_as_hash = true
            
            result = db.execute('SELECT * FROM posts WHERE userId=?', params["id"])
            user = db.execute('SELECT * FROM users WHERE id=?', params["id"])[0]
            
            return result, user
        else
            return false
        end
    end

    def tags(params)
        if validate_profile_and_tags(params)
            db = connect_to_db()
            db.results_as_hash = true
            result = db.execute('SELECT posts.* FROM tags INNER JOIN posts_tags ON posts_tags.tagId = tags.id INNER JOIN posts ON posts.id = posts_tags.postId WHERE tags.id=?', params["id"])
            return result
        else
            return false
        end
    end

    def get_profile_edit(user_id)
        if validate_profile_edit(user_id)
            db = connect_to_db()
            db.results_as_hash = true
            result = db.execute('SELECT * FROM users WHERE id=?', session["user_id"])
            return result
        else
            return false
        end
    end

    def post_profile_edit(params)
        if params["password"] and params["id"] and params["username"] and params["password"] == params["password_2"]
            db = connect_to_db()
            db.results_as_hash = true
            hashed_password = BCrypt::Password.create(params["password"])
            db.execute("REPLACE INTO users (id, username, password) VALUES (?, ?, ?)", [params["id"], params["username"], hashed_password])
        else
            return false
        end
    end

    def delete(params)
        if params["id"]
            db = connect_to_db()
            db.results_as_hash = true
            db.execute("DELETE FROM posts WHERE id = ?", params["id"])
        else
            return false
        end
    end

    def edit_post(params)
        if params["id"] and params["image"] and params["content"] 
            id = params["id"]
            db = connect_to_db()
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
        else
            return false
        end
    end

    def post_owner(params)
        if params["id"]
            db = connect_to_db()
            db.results_as_hash = true
            
            result = db.execute('SELECT userId FROM posts where id=?', params["id"].to_i)
            return result
        else
            return false
        end
    end

    def connect_to_db()
        db = SQLite3::Database.new('db/database.db')
    end

    validate_create_post(params)
        params["content"].length < 500 and params["tags"] and params["image"]
    end

    validate_create_user(params)
        params["username"].length < 25
    end
    
    validate_login_user(params)
        params["username"] and params["password"] and params["password"] == params["password_2"]
    end

    validate_profile_and_tags(params)
        params["id"]
    end

    validate_profile_edit(user_id)
        session["user_id"]
    end
end

