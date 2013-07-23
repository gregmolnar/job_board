require "cuba/test"
require_relative "../app"

prepare do
  Ohm.flush
end

scope do
  test "should display homepage" do
    get "/"
    assert_equal 200, last_response.status
  end

  test "should display company signup" do
    get "/company_signup"
    assert_equal 200, last_response.status
  end

  test "should inform User in case of incomplete or invalid fields" do
    post "/company_signup", { company: { name: "",
          email: "punchgirls@mail.com",
          url: "http://www.punchgirls.com",
          password: "1234",
          password_confirmation: "1234" }}
    assert last_response.body["All fields are required and must be valid"]
  end

  test "should inform User of successfull signup" do
    post "/company_signup", { company: { name: "Punchgirls",
          email: "punchgirls@mail.com",
          url: "http://www.punchgirls.com",
          password: "1234",
          password_confirmation: "1234" }}
    assert last_response.body["You have successfully signed up!"]
  end

  # test "should inform User of email already registered" do
  #   post "/company_signup", { company: { name: "Punchgirls",
  #         email: "punchgirls@mail.com",
  #         url: "http://www.punchgirls.com",
  #         password: "1234",
  #         password_confirmation: "1234" }}
  #   assert last_response.body["This e-mail is already registered"]
  # end
end