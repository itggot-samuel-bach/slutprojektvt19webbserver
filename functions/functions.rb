module Model
    def post(params, user_id)
        if validate_create_post(params)
            text = params["content"]
            db = connect_to_db()
            username = db.execute("SELECT username FROM users WHERE id=?", user_id)
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
            return {}
        else
            return {error: "Your message is either too long or you are missing a message or an image"}
        end
    end

    def create(params)
        if validate_create_user(params)
            db = connect_to_db()
            db.results_as_hash = true
            existing_user = db.execute("SELECT id FROM users WHERE username=?", [params["username"]])
            
            if existing_user.length > 0
                return {error: "There is already a user with this name!"}
            end
            
            hashed_password = BCrypt::Password.create(params["password"])
            db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [params["username"], hashed_password])
            user_id = db.execute("SELECT id FROM users WHERE username=?", [params["username"]])
            return {user_id: result[0]['id']}
        else
            return {error: "Your username or password is too long."}
        end
    end

    def start()
        db = connect_to_db()
        db.results_as_hash = true
        db.execute('SELECT * FROM tags')
    end

    def home()
        db = connect_to_db()
        db.results_as_hash = true
        
        result = db.execute('SELECT * FROM posts ORDER BY id DESC')
        return result
    end

    def login(params)
        if validate_login_user(params)
            db = connect_to_db()
            db.results_as_hash = true
            result = db.execute("SELECT id, password FROM users WHERE username=?", [params["username"]])
            if result.length == 0
                return {error: "Check your input again"}
            end  
            if BCrypt::Password.new(result[0]["password"]) == params["password"]
                return {user_id: result[0]['id']}
            else
                return {error: "You have not provided the correct credentials!"}
            end
        else
            return {error: "Not valid input"}
        end
    end


    def profile(params)
        if validate_profile(params)
            db = connect_to_db()
            db.results_as_hash = true
            
            result = db.execute('SELECT * FROM posts WHERE userId=?', params["id"])
            user = db.execute('SELECT * FROM users WHERE id=?', params["id"])[0]
            
            return {posts: result, user: user}
        else
            return {error: "There is no such user!"}
        end
    end

    def tags(params)
        if validate_tags(params)
            db = connect_to_db()
            db.results_as_hash = true
            result = db.execute('SELECT posts.* FROM tags INNER JOIN posts_tags ON posts_tags.tagId = tags.id INNER JOIN posts ON posts.id = posts_tags.postId WHERE tags.id=?', params["id"])
            return {posts: result}
        else
            return {error: "There is no such tag!"}
        end
    end

    def get_profile_edit(session, params)
        if validate_profile_edit_get(session, params)
            db = connect_to_db()
            db.results_as_hash = true
            result = db.execute('SELECT * FROM users WHERE id=?', session["user_id"])
            return {user: result}
        else
            return {error: "You are not logged in"}
        end
    end

    def post_profile_edit(params)
        if validate_profile_edit_post(params)
            db = connect_to_db()
            db.results_as_hash = true
            hashed_password = BCrypt::Password.create(params["password"])
            db.execute("REPLACE INTO users (id, username, password) VALUES (?, ?, ?)", [params["id"].to_i, params["username"], hashed_password])
            return {}
        else
            return {error: "You are not logged in"}
        end
    end

    def delete(params, session)
        if validate_delete(params, session)
            db = connect_to_db()
            db.results_as_hash = true
            db.execute("DELETE FROM posts WHERE id=?", params["id"])
            return true
        else
            return false
        end
    end

    def edit_post(params)
        if validate_edit_post(params) 
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
            return {error: "You are not the owner of this post!"}
        end
    end

    def post_owner(params)
        if validate_post_owner(params)
            db = connect_to_db()
            db.results_as_hash = true
            
            result = db.execute('SELECT userId FROM posts where id=?', params["id"].to_i)
            return result[0][0]
        else
            return false
        end
    end

    def connect_to_db()
        SQLite3::Database.new('db/database.db')
    end

    def validate_create_post(params)
        params["content"].length < 500 and params["tags"] and params["image"]
    end

    def validate_create_user(params)
        params["username"].length < 25 and params["password"].length < 25
    end
    
    def validate_login_user(params)
        params["username"] and params["password"] and params["password"] == params["password_2"]
    end

    def validate_profile(params)
        db = connect_to_db()
        db.results_as_hash = true

        result = db.execute('SELECT id FROM users where id=?', params["id"].to_i)

        if !result.empty?()
            return true
        else
            return false
        end
    end

    def validate_tags(params)
        db = connect_to_db()
        db.results_as_hash = true

        result = db.execute('SELECT id FROM tags where id=?', params["id"].to_i)

        if !result.empty?()
            return true
        else
            return false
        end
    end

    def validate_profile_edit_get(session, params)
        db = connect_to_db()
        db.results_as_hash = true

        result = db.execute('SELECT id FROM users where id=?', params["id"].to_i)

        if result[0][0] == session["user_id"]
            return true
        else
            return false
        end
    end

    def validate_profile_edit_post(params)
        params["password"] and params["id"] and params["username"]
    end

    def validate_delete(params, session)
        db = connect_to_db()
        db.results_as_hash = true

        result = db.execute('SELECT userId FROM posts where id=?', params["id"].to_i)

        if result[0][0] == session["user_id"]
            return true
        else
            return false
        end
    end

    def validate_edit_post(params)
        params["id"] and params["image"] and params["content"] 
    end

    def validate_post_owner(params)
        if params["id"]
            return true
        else
            return false
        end
    end
end

