use std::io;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("io error: {0}")]
    Io(#[from] io::Error),

    #[error("http error: {0}")]
    Http(#[from] reqwest::Error),

    #[error("api error: status={status}, message={message}")]
    ApiError { status: u16, message: String },

    #[error("parse error: {0}")]
    ParseError(String),

    #[error("config error: {0}")]
    ConfigError(String),

    #[error("probe timeout for {target}")]
    ProbeTimeout { target: std::net::IpAddr },

    #[error("router {router} unreachable")]
    RouterUnreachable { router: String },

    #[error("socket error: {0}")]
    SocketError(String),

    #[error("json error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("toml error: {0}")]
    Toml(#[from] toml::de::Error),

    #[error("env error: {0}")]
    Env(#[from] std::env::VarError),
}

pub type Result<T> = std::result::Result<T, Error>;
