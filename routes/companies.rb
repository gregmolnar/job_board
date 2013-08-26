class Companies < Cuba
  define do
    on "dashboard" do
      render("company/dashboard", title: "Dashboard")
    end

    on "profile" do
      render("company/profile", title: "Profile")
    end

    on "edit" do
      on post, param("company") do |params|
        if !params["url"].start_with?("http")
          params["url"] = "http://" + params["url"]
        end

        company = current_company

        values = []

        company.attributes.each_value do |value|
          values << value
        end

        if params["password"].empty?
          params["password"] = company.crypted_password
          params["password_confirmation"] = company.crypted_password
        end

        params.each_value do |value|
          if !values.include?(value)
            edit = EditCompanyAccount.new(params)

            on edit.valid? do
              params.delete("password_confirmation")

              on company.email != edit.email &&
                Company.with(:email, edit.email) do

                session[:error] = "E-mail is already registered"
                render("company/edit", title: "Edit profile")
              end

              on default do
                company.update(params)

                session[:success] = "Your account was successfully updated!"
                res.redirect "/profile"
              end
            end

            on edit.errors[:name] == [:not_present] do
              session[:error] = "Company name is required"
              render("company/edit", title: "Edit profile")
            end

            on edit.errors[:email] == [:not_email] do
              session[:error] = "E-mail not valid"
              render("company/edit", title: "Edit profile")
            end

            on edit.errors[:url] == [:not_url] do
              session[:error] = "URL not valid"
              render("company/edit", title: "Edit profile")
            end

            on edit.errors[:password] == [:not_in_range] do
              session[:error] = "The password must be at least 8 characters"
              render("company/edit", title: "Edit profile")
            end

            on edit.errors[:password] == [:not_confirmed] do
              session[:error] = "Passwords don't match"
              render("company/edit", title: "Edit profile")
            end

            on default do
              session[:error] = "Name, E-mail and URL are required and must be valid"
              render("company/edit", title: "Edit profile")
            end
          end
        end

        res.redirect "/profile"
      end

      on default do
        render("company/edit", title: "Edit profile")
      end
    end

    on "post/new" do
      on post, param("post") do |params|
        post = PostJobOffer.new(params)

        on post.valid? do
          time = Time.new.to_i

          params[:company_id] = current_company.id
          params[:date] = time
          params[:expiration_date] = time + (30 * 24 * 60 * 60)

          Post.create(params)

          session[:success] = "You have successfully posted a job offer!"
          res.redirect "/dashboard"
        end

        on post.errors[:title] == [:not_in_range] do
          session[:error] = "Title should not exceed 80 characters"
          render("company/post/new", title: "Post job offer", post: params)
        end

        on post.errors[:description] == [:not_in_range] do
          session[:error] = "Description should not exceed 600 characters"
          render("company/post/new", title: "Post job offer", post: params)
        end

        on default do
          session[:error] = "All fields are required"
          render("company/post/new", title: "Post job offer", post: params)
        end
      end

      on default do
        render("company/post/new", title: "Post job offer", post: {})
      end
    end

    on "post/remove/:id" do |id|
      post = Post[id]
      developers = post.developers

      developers.each do |developer|
        Malone.deliver(to: developer.email,
          subject: "Auto-notice: '" + post.title + "' post has been removed",
          html: mote("views/company/message/remove_post.mote",
            post: post, developer: developer))
      end

      post.delete
      session[:success] = "Post successfully removed!"
      res.redirect "/dashboard"
    end

    on "post/edit/:id" do |id|
      on post, param("post") do |params|
        post = PostJobOffer.new(params)

        if post.valid?
          Post[id].update(params)

          session[:success] = "Post successfully edited!"
          res.redirect "/dashboard"
        else
          session[:error] = "All fields are required"
          render("company/post/edit", title: "Edit post", id: id)
        end
      end

      on default do
        render("company/post/edit", title: "Edit post", id: id)
      end
    end

    on "post/applications/:id" do |id|
      render("company/post/applications", title: "Applicants", id: id)
    end

    on "application/remove/:id" do |id|
      application = Application[id]
      developer = application.developer
      post = application.post
      company = post.company

      Malone.deliver(to: developer.email,
            cc: company.email,
            subject: "Auto-notice: Regarding '" + post.title + "' post",
            html: mote("views/company/message/remove_application.mote",
              post: post, developer: developer))

      Application[id].delete

      session[:success] = "Applicant successfully removed!"
      res.redirect "/dashboard"
    end

    on "application/contact/:id" do |id|
      on post, param("message") do |params|
        mail = Contact.new(params)

        if mail.valid?
          company = current_company

          Malone.deliver(to: Developer[id].email,
            cc: company.email,
            subject: params["subject"],
            html: mote("views/company/message/contact.mote",
              title: "Contact", params: params))

          session[:success] = "You just sent an e-mail to the applicant!"
          res.redirect "/dashboard"
        else
          session[:error] = "All fields are required"
          render("company/post/contact", title: "Contact developer",
            id: id, message: params)
        end
      end

      on default do
        render("company/post/contact", title: "Contact developer",
          id: id, message: {})
      end
    end

    on "application/favorite/:id" do |id|
      application = Application[id]
      post = application.post

      if post.favorites.member?(application)
        post.favorites.delete(application)
      else
        post.favorites.add(application)
      end

      on default do
        render("company/post/applications", title: "Applicants", id: post.id)
      end
    end

    on "posts" do
      render("posts", title: "Posts")
    end

    on "logout" do
      logout(Company)
      session[:success] = "You have successfully logged out!"
      res.redirect "/"
    end

    on "delete/:id" do |id|
      company = Company[id]
      posts = company.posts
      developers = []

      posts.each do |post|
        post.developers.each do |developer|
         if !developers.include?(developer)
          developers << developer
         end
        end
      end

      developers.each do |developer|
        Malone.deliver(to: developer.email,
          subject: "Auto-notice: '" + company.name + "' removed their profile",
          html: mote("views/company/message/delete_account.mote",
              developer: developer))
      end

      company.delete
      session[:success] = "You have deleted your account."
      res.redirect "/"
    end

    on default do
      render("company/dashboard", title: "Dashboard")
    end
  end
end
