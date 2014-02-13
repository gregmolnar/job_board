require_relative "../app"

Ost[:deleted_post].each do |id|
  post = Post[id]
  developers = post.developers

  developers.each do |developer|
    text = Mailer.render("deleted_post", { post: post, developer: developer })

    Malone.deliver(
      to: developer.email,
      subject: "[Job Board] " + post.title + " post has been removed",
      text: text)
  end

  post.delete
end