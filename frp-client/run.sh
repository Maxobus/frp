#!/usr/bin/env bashio
WAIT_PIDS=()
CONFIG_PATH='/share/frpc.toml'
HA_IP=$(ip route get 1 | awk '{print $7; exit}')
# HA_ID=$(bashio::config 'id')

function stop_frpc() {
    bashio::log.info "Shutdown frpc client"
    kill -15 "${WAIT_PIDS[@]}"
}

bashio::log.info "Generating frpc.toml from UI config"

mkdir -p /share

cat <<EOF > $CONFIG_PATH
serverAddr = "$(bashio::config 'serverAddr')"
serverPort = 7000
auth.method = "token"
auth.token = "22d8ce655c6a6e8286a659618f70adb8"

log.to = "/share/frpc.log"
log.level = "trace"
log.maxDays = 3

[[proxies]]
name = "$(bashio::config 'serverAddr')"
type = "tcp"
transport.useEncryption = true
transport.useCompression = true
remotePort = $(bashio::config 'remotePort')
localPort = 8123
# localIP = "0.0.0.0"
localIP = "$HA_IP"
EOF

bashio::log.info "Starting frp client"
cat $CONFIG_PATH

cd /usr/src
./frpc -c $CONFIG_PATH & WAIT_PIDS+=($!)
# tail -f /share/frpc.log &
( while [ ! -f /share/frpc.log ]; do sleep 1; done; tail -f /share/frpc.log ) &

trap "stop_frpc" SIGTERM SIGHUP
wait "${WAIT_PIDS[@]}"
