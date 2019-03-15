#[macro_use] extern crate serde_derive;

use actix_web::{http, server, App, Query, Responder};


#[derive(Deserialize)]
struct SessionRequest {
  platform: String,
}

#[derive(Deserialize)]
struct VulnsRequest {
  session: String,
}

fn session(query: Query<SessionRequest>) -> String {
  format!("New session created for scanner on {}", query.platform)
}

fn vulnerabilities(query: Query<VulnsRequest>) -> String {
  format!("Fetching vulns for session {}", query.session)
}

fn main() {
  let server = server::new(|| {
    App::new()
      .resource("/vulnerabilities", |r| r.method(http::Method::GET).with(session))
      .resource("/vulnerabilities/poll", |r| r.method(http::Method::GET).with(vulnerabilities))
  });
    
  server
    .bind("127.0.0.1:9002")
    .unwrap()
    .run();
}
