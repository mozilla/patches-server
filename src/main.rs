#[macro_use] extern crate serde_derive;
#[macro_use] extern crate redis_async;

mod persist;

use std::sync::{Arc, Mutex};

use actix_redis::{RedisActor, Command};
use actix_web::{http, server, Addr, App, State, Query, Responder};

use persist::{Persistent, Redis};


#[derive(Clone)]
struct State {
  application: AppState,
  configuration: Config,
  redis: Addr<RedisActor>,
}

struct Config {
}

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

fn unit1<T>(_any: T) -> () { () }

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

impl Persist<Addr<RedisActor>> for AppState {
  type Error = {};

  fn persist(&self, redis_actor: &Addr<RedisActor>) -> Result<(), ()> {
    let num_sessions = format!("{}", self.sessions);

    redis_actor
      .try_send(Command(resp_array!["SET", "sessions", num_sessions]))
      .map_err(unit1)
      .map(unit1)
  }

  fn rebuild(redis_actor: &Addr<RedisActor>) -> Result<AppState, ()> {
    let response = redis_actor
      .try_send(Command(resp_array!["GET", "sessions"]))
      .map_err(unit1);

    match response {
      Ok(RespValue::SimpleString(value)) => {
        let num_sessions = value.parse::<u32>().map_err(unit1)?;

        Ok(AppState{ sessions: num_sessions })
      },

      Ok(RespValue::BulkString(bytes)) => {
        let num_sessions = String::from_utf8(bytes)
          .and_then(|string| string.parse::<u32>().map_err(unit1))
          .map_err(unit1)?;

        Ok(AppState{ sessions: num_sessions })
      },

      _ => Err(()),
    }
  }
}
