#!/usr/bin/env bashio
WAIT_PIDS=()
CONFIG_PATH='/share/frpc.toml'

function stop_frpc() {
    bashio::log.info "Shutdown frpc client"
    kill -15 "${WAIT_PIDS[@]}"
}

bashio::log.info "Generating frpc.toml from UI config"

cat <<EOF > $CONFIG_PATH
serverAddr = "$(bashio::config 'serverAddr')"
serverPort = 7000
auth.method = "token"
auth.token = "yourStrongSecretToken"

log.to = "/share/frpc.log"
log.level = "trace"
log.maxDays = 3

# webServer.addr = "0.0.0.0"
# webServer.port = $(bashio::config 'webServerPort')
# webServer.user = "$(bashio::config 'webServerUser')"
# webServer.password = "$(bashio::config 'webServerPassword')"

[[proxies]]
name = "Home Assistant"
type = "tcp"
transport.useEncryption = true
transport.useCompression = true
remotePort = $(bashio::config 'remotePort')
localPort = 8123
localIP = "0.0.0.0"
EOF

bashio::log.info "Starting frp client"
cat $CONFIG_PATH

cd /usr/src
./frpc -c $CONFIG_PATH & WAIT_PIDS+=($!)
tail -f /share/frpc.log &

trap "stop_frpc" SIGTERM SIGHUP
wait "${WAIT_PIDS[@]}"
