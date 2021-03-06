export RUST_LOG := "wascc_host=debug,wascc_provider=debug,wasi_provider=debug,main=debug"
export PFX_PASSWORD := "testing"

run: run-wascc

build:
    cargo build

prefetch:
    cargo fetch --manifest-path ./Cargo.toml

test:
    cargo fmt --all -- --check
    cargo clippy --workspace
    cargo test --workspace

run-wascc: _cleanup_kube bootstrap-ssl
    # Change directories so we have access to the ./lib dir
    cd ./crates/wascc-provider && cargo run --bin krustlet-wascc --manifest-path ../../Cargo.toml

run-wasi: _cleanup_kube bootstrap-ssl
    # HACK: Temporary step to change to a directory so it has access to a hard
    # coded module. This should be removed once we have image support
    cd ./crates/wasi-provider && cargo run --bin krustlet-wasi --manifest-path ../../Cargo.toml

dockerize:
    docker build -t technosophos/krustlet:latest .

push:
    docker push technosophos/krustlet:latest

bootstrap-ssl:
    mkdir -p ~/.krustlet/config
    test -f  ~/.krustlet/config/host.key && test -f ~/.krustlet/config/host.cert || openssl req -x509 -sha256 -newkey rsa:2048 -keyout ~/.krustlet/config/host.key -out ~/.krustlet/config/host.cert -days 365 -nodes -subj "/C=AU/ST=./L=./O=./OU=./CN=."
    test -f ~/.krustlet/config/certificate.pfx || openssl pkcs12 -export -out  ~/.krustlet/config/certificate.pfx -inkey  ~/.krustlet/config/host.key -in  ~/.krustlet/config/host.cert -password "pass:${PFX_PASSWORD}"
    chmod 400 ~/.krustlet/config/*

itest:
    kubectl create -f examples/greet.yaml
    sleep 5
    for i in 1 2 3 4 5; do sleep 3 && kubectl get po greet; done

_cleanup_kube:
    kubectl delete no $(hostname | tr '[:upper:]' '[:lower:]') || true
    kubectl delete po greet || true

testfor:
    for i in 1 2 3 4 5; do sleep 3 && echo hello $i; done