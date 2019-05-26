module Model
    # Gathers all the input information from the user and then inserts it into the database as a post. 
    #
    # @param [Hash] params form data
    # @option params [String] content The text of the posts
    # @option params [Image] image The post's image
    # @option params [String] tags The name of the tags selected
    #
    # @return [Hash] returns an empty hash
    #
    # @return [Hash] contains an error message
    #   * :error [String] The error message
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

    # Attempts to create a user if all the necessary data has been provided.
    #
    # @param [Hash] params form data
    # @option params [String] username The username from the user's input
    # @option params [String] password The password from the user's input
    #
    # @return [Hash] contains the users id
    #   * :user_id [Integer] The user's id
    # @return [Hash] contains an error message
    #   * :error [String] The error message
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
            return {user_id: user_id[0]['id']}
        else
            return {error: "Your username or password is too long."}
        end
    end

    # Loads all the tags and displays them on a specific page once requested.
    #
    # @return [Array] contains all tags
    def start()
        db = connect_to_db()
        db.results_as_hash = true
        db.execute('SELECT * FROM tags')
    end

    # Loads all the posts and displays them on the index page
    #
    # @return [Array] contains all the posts
    def home()
        db = connect_to_db()
        db.results_as_hash = true
        
        result = db.execute('SELECT * FROM posts ORDER BY id DESC')
        return result
    end

    # Logs in the user if the user input provided is correct.
    #
    # @param [Hash] params form data
    # @option params [String] username The username from the user's input
    # @option params [String] password The password from the user's input
    #
    # @return [Hash] contains the users id
    #   * :user_id [Integer] The user's id
    # @return [Hash] contains the first error message
    #   * :error [String] The first error message
    # @return [Hash] contains the second error message
    #   * :error [String] The second error message
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
            return {error: "Make sure your password is the same in both boxes."}
        end
    end

    # Attempts to load a specific user's profile page
    #
    # @param [Hash] params form data
    # @option params [Integer] id The id of the user requested to visit
    #
    # @return [Hash] contains the users username and password and the posts owned by the user
    #   * :posts [Array] The posts owned by the user
    #   * :user [Integer] The user's username and password
    # @return [Hash] contains an error message
    #   * :error [String] The error message
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

    # Loads the specific page of a specificed tag and all the posts associated with it.
    #
    # @param [Hash] params form data
    # @option params [Integer] id The id of the specified tag
    #
    # @return [Hash] contains posts associated with the specified tag
    #   * :posts [Array] The posts associated with the specified tag
    # @return [Hash] contains an error message
    #   * :error [String] The error message
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

    # Gets the form for editing a specific profile.
    #
    # @param [Hash] params form data
    # @option params [Integer] id The id of the specified user requested to edit
    #
    # @return [Hash] contains the user's username and password with of the one currently logged in.
    #   * :user [Array] The username and password of the currently logged in user
    # @return [Hash] contains an error message
    #   * :error [String] The error message
    def get_profile_edit(session, params)
        if validate_profile_edit_get(session, params)
            db = connect_to_db()
            db.results_as_hash = true
            result = db.execute('SELECT * FROM users WHERE id=?', session["user_id"])
            return {user: result}
        else
            return {error: "You are not this user!"}
        end
    end

    # Conducts the requested changes to the profile from the get_profile_edit function.
    #
    # @param [Hash] params form data
    # @option params [Integer] id The id of the specified user requested to edit
    # @option params [String] username The username of the specified user requested to edit
    # @option params [String] password The password of the specified user requested to edit
    #
    # @return [Hash] returns an empty hash
    #
    # @return [Hash] contains an error message
    #   * :error [String] The error message
    def post_profile_edit(params)
        if validate_profile_edit_post(params)
            db = connect_to_db()
            db.results_as_hash = true
            hashed_password = BCrypt::Password.create(params["password"])
            db.execute("REPLACE INTO users (id, username, password) VALUES (?, ?, ?)", [params["id"].to_i, params["username"], hashed_password])
            return {}
        else
            return {error: "You are not this user!"}
        end
    end

    # Deletes a specified post.
    #
    # @param [Hash] params form data
    # @option params [Integer] id The id of the specified post requested to deleted
    #
    # @return [true] Returns true if the post is allowed to be and is deleted.
    # 
    # @return [false] Returns false if the post is not allowed to be deleted
    #
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

    # Edits a post specified by the user's input.
    #
    # @param [Hash] params form data
    # @option params [Integer] id The id of the specified post requested to edit
    # @option params [Image] image The image for the post it is requested to change for
    # @option params [String] content The content the post is requested to change it to
    #
    # @return [Array] Returns the updated post's information
    #
    # @return [Hash] contains an error message
    #   * :error [String] The error message
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

    # Checks whoever owns a specified post
    #
    # @param [Hash] params form data
    # @option params [Integer] id The id of the specified post
    #
    # @return [Integer] Returns the user who owns the specified post
    #
    # @return [false] Returns false if not enough information is provided to determine the owner
    #
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

    # A function that defines which database is being used. 
    #
    # @return [SQLite3::Database] Returns the specified database
    #
    def connect_to_db()
        SQLite3::Database.new('db/database.db')
    end

    # Checks that all the necessary data and conditions are met to allow the creation of the post
    #
    # @param [Hash] params form data
    # @option params [String] content The text in the post
    # @option params [String] tags The tag's name in the post
    # @option params [Image] image The image in the post
    #
    # @return [true] Returns true if the data and conditions are met
    #
    # @return [false] Returns false if the data and conditions are not met
    #
    def validate_create_post(params)
        params["content"].length < 500 and params["tags"] and params["image"]
    end

    # Checks that all the necessary data and conditions are met to allow the creation of a user
    #
    # @param [Hash] params form data
    # @option params [String] username The provided username
    # @option params [String] password The provided password
    #
    # @return [true] Returns true if the data and conditions are met
    #
    # @return [false] Returns false if the data and conditions are not met
    #
    def validate_create_user(params)
        params["username"].length < 25 and params["password"].length < 25
    end
    
    # Checks that all the necessary data and conditions are met to allow the user to login
    #
    # @param [Hash] params form data
    # @option params [String] username The provided username
    # @option params [String] password The provided password
    # @option params [String] password2 A second box with the hopefully same provided password as the first box
    #
    # @return [true] Returns true if the data and conditions are met
    #
    # @return [false] Returns false if the data and conditions are not met
    #
    def validate_login_user(params)
        params["username"] and params["password"] and params["password"] == params["password_2"]
    end

    # Checks wether or not there is a user with the specified id
    #
    # @param [Hash] params form data
    # @option params [String] id The specified user id to check
    #
    # @return [true] Returns true if there is a user with the specified id
    #
    # @return [false] Returns false if there is not a user with the specified id
    #
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

    # Checks wether or not there is a tag with the specified id
    #
    # @param [Hash] params form data
    # @option params [String] id The specified tag id to check
    #
    # @return [true] Returns true if there is a tag with the specified id
    #
    # @return [false] Returns false if there is not a gag with the specified id
    #
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
    
    # Checks wether or not the logged in user is the user of the profile requested to edit
    #
    # @param [Hash] params form data
    # @option params [String] id The specified user id to check
    #
    # @return [true] Returns true if the logged in user is the user of the profile requsted to edit
    #
    # @return [false] Returns false if the logged in user is not the user of the profile requsted to edit
    #
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

    # Checks that all the necessary data available to allow the changes to the user to go through
    #
    # @param [Hash] params form data
    # @option params [String] username The new username
    # @option params [String] password The new password
    # @option params [Integer] id The user's id
    #
    # @return [true] Returns true if the data and conditions are met
    #
    # @return [false] Returns false if the data and conditions are not met
    #
    def validate_profile_edit_post(params)
        params["username"] and params["password"] and params["id"]
    end

    # Checks wether or not the logged in user is the owner of the post requested to delete
    #
    # @param [Hash] params form data
    # @option params [String] id The specified user id to check
    #
    # @return [true] Returns true if the logged in user is the owner of the post requsted to delete
    #
    # @return [false] Returns false if the logged in user is not the owner of the post requsted to delete
    #
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

    # Checks that all the necessary data available to allow the editing of a post
    #
    # @param [Hash] params form data
    # @option params [Integer] id The post's id
    # @option params [Image] image The new image for the post
    # @option params [String] content The new text in the post
    #
    # @return [true] Returns true if the data is available
    #
    # @return [false] Returns false if the data is not available
    #
    def validate_edit_post(params)
        params["id"] and params["image"] and params["content"] 
    end

    # Checks that all the necessary data available to determine who's the owner of a specified post
    #
    # @param [Hash] params form data
    # @option params [Integer] id The post's id
    #
    # @return [true] Returns true if the data is available
    #
    # @return [false] Returns false if the data is not available
    #
    def validate_post_owner(params)
        if params["id"]
            return true
        else
            return false
        end
    end
end

