ruleset hello_world {
  meta {
    name "Hello World"
    description <<
  A first ruleset for the Quickstart
  >>
    author "Phil Windley"
    logging on
    shares hello, __testing
  }
    
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }
  }
    
  rule hello_world {
    select when echo hello
    pre {
      name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("say", {"something":"Hello " + name})
  }

  rule hello_monkey {
    select when echo monkey
    pre {
      name = event:attr("name")|| "Monkey"
      //name = event:attr("name") => event:attr("name") | "Monkey"
      log = name.klog("Our passed in name: ")
    }
    send_directive("say", {"something":"Hello " + name})
  }
     
}