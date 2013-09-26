function apply (id) {
  var post = document.getElementById("apply_" + id);
  var url = "/apply/" + id;

  if (window.XMLHttpRequest) {
    request = new XMLHttpRequest();
  } else {
    request = new ActiveXObject("Microsoft.XMLHTTP");
  }

  request.open("POST", url);

  request.onreadystatechange = function () {
    if ((request.readyState===4) && (request.status===200)) {
      if (post.innerHTML === "APPLIED") {
        post.innerHTML = "APPLY";
      } else {
        post.innerHTML = "APPLIED";
      }
    }
  };

  request.send();
}

function favorite (icon) {
  if (icon.className === "icon-heart red") {
    icon.className = "icon-heart";
  } else {
    icon.className = "icon-heart red";
  }
}

function favoritePost (id) {
  var post = document.getElementById(id);
  var url = "/favorite/" + id;

  if (window.XMLHttpRequest) {
    request = new XMLHttpRequest();
  } else {
    request = new ActiveXObject("Microsoft.XMLHTTP");
  }

  request.open("POST", url);

  request.onreadystatechange = function () {
    if ((request.readyState===4) && (request.status===200)) {
      favorite(post);
    }
  };

  request.send();
}

function favoriteApplicant (id) {
  var application = document.getElementById(id);
  var url = "/application/favorite/" + id;

  console.log(url);

  if (window.XMLHttpRequest) {
    request = new XMLHttpRequest();
  } else {
    request = new ActiveXObject("Microsoft.XMLHTTP");
  }

  request.open("POST", url);

  request.onreadystatechange = function () {
    if ((request.readyState===4) && (request.status===200)) {
      favorite(application);
    }
  };

  request.send();
}

function removePost (id) {
  var post = document.getElementById(id);
  var posts = document.getElementById("posts-list");
  var url = "post/remove/" + id;

  if (window.XMLHttpRequest) {
    request = new XMLHttpRequest();
  } else {
    request = new ActiveXObject("Microsoft.XMLHTTP");
  }

  request.open("POST", url);

  request.onreadystatechange = function () {
    if ((request.readyState===4) && (request.status===200)) {
      posts.removeChild(post);
    }
  };

  request.send();
}