use actix_web::{server, App, Path, Responder};

fn index(_path: Path<()>) -> impl Responder {
  format!("Hello, world!")
}

fn main() {
  let server = server::new(|| {
    App::new().resource("/", |r| r.with(index))
  });
    
  server
    .bind("127.0.0.1:9002")
    .unwrap()
    .run();
}
