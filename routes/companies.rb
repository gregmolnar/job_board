class Companies < Cuba
  define do
    on "dashboard" do
      render("company_dashboard", title: "Company dashboard")
    end

    on "logout" do
      logout(Company)
      session[:success] = "You have successfully logged out!"
      res.redirect "/", 303
    end

    on default do
      res.write "/dashboard"
    end
  end
end