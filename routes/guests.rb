class Guests < Cuba
  define do
    on root do
      res.redirect "/"
    end

    on "package" do
      on post, param("company") do |params|
        res.redirect "/signup?package=#{params["credits"]}"
      end

      on(default) { not_found! }
    end

    on "signup" do
      on root do
        signup = CompanySignup.new({})

        render("company/signup", title: "Sign up",
          company: {}, signup: signup, package: "1")
      end

      on param("package") do |package|
        signup = CompanySignup.new({})

        render("company/signup", title: "Sign up",
          company: {}, signup: signup, package: package)
      end

      on post, param("stripe_token"), param("company") do |token, params|
        customer = Stripe.create_customer(token, params["email"], params["name"])

        params["customer"] = customer

        signup = CompanySignup.new(params)

        on signup.valid? do
          params.delete("password_confirmation")
          params.delete("customer")

          params[:customer_id] = customer.id

          company = Company.create(params)

          authenticate(company)

          session[:success] = "You have successfully signed up!"

          res.redirect "/dashboard"
        end

        on default do
          render("company/signup", title: "Sign up",
              company: params, signup: signup, package: params["credits"])
        end
      end

      on(default) { not_found! }
    end

    on "login" do
      on root do
        render("company/login", title: "Login", user: "")
      end

      on post, param("company") do |params|
        user = params["email"]
        pass = params["password"]
        remember = params["remember"]

        if login(Company, user, pass)
          if remember
            remember(3600)
          end

          session[:success] = "You have successfully logged in!"
          res.redirect "/dashboard"
        else
          session[:error] = "Invalid email/password combination"
          render("company/login", title: "Login", user: user)
        end
      end

      on post, param("email") do |user|
        session[:error] = "No password provided"
        render("company/login", title: "Login", user: user)
      end

      on param("recovery") do
        session[:success] = "Check your e-mail and follow the instructions."
        res.redirect "/login"
      end

      on(default) { not_found! }
    end

    on "forgot-password" do
      on get do
        render("forgot-password", title: "Password recovery")
      end

      on post do
        company = Company.fetch(req[:email])

        on company do
          nobi = Nobi::TimestampSigner.new('my secret here')
          signature = nobi.sign(String(company.id))

          Malone.deliver(to: company.email,
            subject: "Password recovery",
            html: "Please follow this link to reset your password: " +
            RESET_URL + "/otp/%s" % signature)

          res.redirect "/login/?recovery=true", 303
        end

        on default do
          session[:error] = "Can't find a user with that e-mail."
          res.redirect("/forgot-password", 303)
        end
      end
    end

    on "otp/:signature" do |signature|
      on root do
        session[:error] = "Invalid URL. Please try again!"
        res.redirect("/forgot-password")
      end

      nobi = Nobi::TimestampSigner.new('my secret here')

      company =
        begin
          company_id = nobi.unsign(signature, max_age: 7200)

          Company[company_id]
        rescue Nobi::BadData
        end

      on company do
        on post, param("company") do |params|
          reset = PasswordRecovery.new(params)

          on reset.valid? do
            company.update(password: reset.password)

            authenticate(company)

            session[:success] = "You have successfully changed
            your password and logged in!"
            res.redirect "/", 303
          end

          on default do
            render("otp", title: "Password recovery",
              company: company, signature: signature, reset: reset)
          end
        end

        on default do
          reset = PasswordRecovery.new({})

          render("otp", title: "Password recovery",
            company: company, signature: signature, reset: reset)
        end
      end

      on(default) { not_found! }
    end

    on "search" do
      run Searches
    end

    on "apply/:id" do |id|
      on root do
        session[:apply_id] = id

        res.redirect "/github_oauth"
      end

      on(default) { not_found! }
    end

    on "favorite/:id" do |id|
      on root do
        session[:favorite_id] = id
        session[:origin] = { "guests" => "true" }

        res.redirect "/github_oauth"
      end

      on(default) { not_found! }
    end

    on "github_oauth" do
      on root do
        res.redirect GitHub.oauth_authorize
      end

      on param("code") do |code|
        access_token = GitHub.fetch_access_token(code)

        on access_token.nil? do
          session[:error] = "There were authentication problems."
          res.redirect "/"
        end

        on default do
          res.redirect GitHub.login_url(access_token)
        end
      end

      on(default) { not_found! }
    end

    on "github_login/:access_token" do |access_token|
      on root do
        apply_id = session[:apply_id]
        query = session[:query]
        favorite = session[:favorite_id]
        origin = session[:origin]

        github_user = GitHub.fetch_user(access_token)

        developer = Developer.fetch(github_user["id"])

        on developer.nil? do
          session[:github_id] = github_user["id"]
          session[:username] = github_user["login"]
          session[:avatar] = github_user["gravatar_id"]

          render("confirm", title: "Confirm your user details",
            github_user: github_user)
        end

        authenticate(developer)

        session[:success] = "You have successfully logged in."
        session[:apply_id] = apply_id
        session[:favorite_id] = favorite
        session[:query] = query
        session[:origin] = origin

        res.redirect "/dashboard"
      end

      on(default) { not_found! }
    end

    on "confirm" do
      apply_id = session[:apply_id]
      query = session[:query]
      favorite = session[:favorite_id]
      origin = session[:origin]

      on root do
        render("confirm", title: "Confirm your user details")
      end

      on post, param("developer") do |params|
        if !params["url"].empty? &&
          !params["url"].start_with?("http")
          params["url"] = "http://" + params["url"]
        end

        login = DeveloperLogin.new(params)

        on login.valid? do
          developer = Developer.create(
            github_id: session[:github_id],
            username: session[:username],
            name: params["name"],
            email: params["email"],
            url: params["url"],
            bio: params["bio"],
            avatar: session[:avatar])

          authenticate(developer)

          session[:apply_id] = apply_id
          session[:favorite_id] = favorite
          session[:query] = query
          session[:origin] = origin

          session[:success] = "You have successfully logged in!"
          res.redirect "/dashboard"
        end

        on default do
          session[:error] = "All fields are required and must be valid"
          render("confirm", title: "Confirm your user details",
            github_user: params)
        end
      end

      on(default) { not_found! }
    end

    on "admin" do
      on root do
        render("admin/login", title: "Admin Login", admin: "")
      end

      on post, param("email"), param("password") do |admin, pass|
        if login(Admin, admin, pass)
          session[:success] = "You have successfully logged in!"
          res.redirect "/dashboard"
        else
          session[:error] = "Invalid email/password combination"
          render("admin/login", title: "Admin Login", admin: admin)
        end
      end

      on post, param("email") do |admin|
        session[:error] = "No password provided"
        render("admin/login", title: "Admin Login", admin: admin)
      end

      on(default) { not_found! }
    end

    on(default) { not_found! }
  end
end
