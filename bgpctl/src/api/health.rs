use crate::api::MetricsExporter;
use crate::decision::Optimizer;
use http_body_util::Full;
use hyper::body::Bytes;
use hyper::server::conn::http1;
use hyper::service::service_fn;
use hyper::{Request, Response, StatusCode};
use hyper_util::rt::TokioIo;
use std::convert::Infallible;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::net::TcpListener;
use tokio::sync::RwLock;
use tracing::{error, info};

/// http server for health checks and metrics
pub struct HealthServer {
    listen_addr: SocketAddr,
    metrics_path: String,
    metrics: Arc<MetricsExporter>,
    optimizer: Arc<RwLock<Optimizer>>,
}

impl HealthServer {
    pub fn new(
        listen_addr: SocketAddr,
        metrics_path: String,
        metrics: Arc<MetricsExporter>,
        optimizer: Arc<RwLock<Optimizer>>,
    ) -> Self {
        Self {
            listen_addr,
            metrics_path,
            metrics,
            optimizer,
        }
    }

    pub async fn run(self, mut shutdown: tokio::sync::watch::Receiver<bool>) {
        let listener = match TcpListener::bind(&self.listen_addr).await {
            Ok(l) => l,
            Err(e) => {
                error!(error = %e, addr = %self.listen_addr, "failed to bind health server");
                return;
            }
        };

        info!(addr = %self.listen_addr, "health server listening");

        let metrics = self.metrics.clone();
        let optimizer = self.optimizer.clone();
        let metrics_path = self.metrics_path.clone();

        loop {
            tokio::select! {
                result = listener.accept() => {
                    match result {
                        Ok((stream, _)) => {
                            let io = TokioIo::new(stream);
                            let metrics = metrics.clone();
                            let optimizer = optimizer.clone();
                            let metrics_path = metrics_path.clone();

                            tokio::spawn(async move {
                                let service = service_fn(move |req| {
                                    let metrics = metrics.clone();
                                    let optimizer = optimizer.clone();
                                    let metrics_path = metrics_path.clone();
                                    async move {
                                        handle_request(req, metrics, optimizer, &metrics_path).await
                                    }
                                });

                                if let Err(e) = http1::Builder::new()
                                    .serve_connection(io, service)
                                    .await
                                {
                                    error!(error = %e, "http connection error");
                                }
                            });
                        }
                        Err(e) => {
                            error!(error = %e, "accept error");
                        }
                    }
                }
                _ = shutdown.changed() => {
                    if *shutdown.borrow() {
                        info!("health server shutting down");
                        break;
                    }
                }
            }
        }
    }
}

async fn handle_request(
    req: Request<hyper::body::Incoming>,
    metrics: Arc<MetricsExporter>,
    optimizer: Arc<RwLock<Optimizer>>,
    metrics_path: &str,
) -> Result<Response<Full<Bytes>>, Infallible> {
    let path = req.uri().path();

    let response = match path {
        "/health" | "/healthz" => {
            Response::builder()
                .status(StatusCode::OK)
                .body(Full::new(Bytes::from("ok")))
                .unwrap()
        }
        "/ready" | "/readyz" => {
            Response::builder()
                .status(StatusCode::OK)
                .body(Full::new(Bytes::from("ready")))
                .unwrap()
        }
        p if p == metrics_path => {
            // update metrics before serving
            {
                let opt = optimizer.read().await;
                metrics.update(&*opt).await;
            }

            let body = metrics.encode();
            Response::builder()
                .status(StatusCode::OK)
                .header("Content-Type", "text/plain; version=0.0.4")
                .body(Full::new(Bytes::from(body)))
                .unwrap()
        }
        "/status" => {
            let opt = optimizer.read().await;
            let summary = opt.get_summary().await;
            let body = format!("{}", summary);

            Response::builder()
                .status(StatusCode::OK)
                .header("Content-Type", "text/plain")
                .body(Full::new(Bytes::from(body)))
                .unwrap()
        }
        _ => {
            Response::builder()
                .status(StatusCode::NOT_FOUND)
                .body(Full::new(Bytes::from("not found")))
                .unwrap()
        }
    };

    Ok(response)
}
