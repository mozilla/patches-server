#[macro_use] extern crate serde_derive;

use std::sync::{Arc, Mutex};

use actix_web::{http, server, App, State, Query, Responder};


#[derive(Clone)]
struct AppState {
  sessions: Arc<Mutex<u32>>
}

#[derive(Deserialize)]
struct SessionRequest {
  platform: String,
}

#[derive(Deserialize)]
struct VulnsRequest {
  session: String,
}

fn session(state: State<AppState>, query: Query<SessionRequest>) -> impl Responder{
  *(state.sessions.lock().unwrap()) += 1;

  let now_serving = state.sessions.lock().unwrap();

  format!("New session created for scanner on {}. Now serving {} sessions",
    query.platform, now_serving)
}

fn vulnerabilities(_state: State<AppState>, query: Query<VulnsRequest>) -> String {
  format!("Fetching vulns for session {}", query.session)
}

fn main() {
  let sessions = Arc::new(Mutex::new(0));

  let server = server::new(move || {
    let state = AppState {
      sessions: sessions.clone(),
    };

    App::with_state(state)
      .resource("/vulnerabilities", |r| r.method(http::Method::GET).with(session))
      .resource("/vulnerabilities/poll", |r| r.method(http::Method::GET).with(vulnerabilities))
  });
    
  server
    .bind("127.0.0.1:9002")
    .unwrap()
    .run();
}
