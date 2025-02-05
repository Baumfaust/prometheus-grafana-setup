#!/bin/bash

# ------------------- check if last command was successful -----------------
check_success() {
  if [ $? -ne 0 ]; then
    echo "❌ Error encountered in previous step. Exiting..."
    exit 1
  fi
}

# ---------------------- Detect System Architecture ----------------------
detect_architecture() {
  ARCH=$(uname -m)
  if [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
  elif [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
  else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
  fi
  echo "🚀 Detected Architecture: $ARCH"
}

# Function to update system
update_system() {
  echo "🚀 Updating System..."
  sudo apt update && sudo apt upgrade -y
  check_success
}

# ---------------------- Install Node Exporter ----------------------
install_node_exporter() {
  echo "📌 Fetching Latest Node Exporter Version..."
  NODE_EXPORTER_VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
  check_success

  echo "📌 Installing Node Exporter ($NODE_EXPORTER_VERSION)..."
  cd /usr/local/bin
  wget https://github.com/prometheus/node_exporter/releases/download/$NODE_EXPORTER_VERSION/node_exporter-${NODE_EXPORTER_VERSION#v}.linux-${ARCH}.tar.gz
  check_success

  tar xvf node_exporter-${NODE_EXPORTER_VERSION#v}.linux-${ARCH}.tar.gz
  check_success
  sudo mv node_exporter-${NODE_EXPORTER_VERSION#v}.linux-${ARCH}/node_exporter .
  rm -rf node_exporter-${NODE_EXPORTER_VERSION#v}*

  # Create Node Exporter Service
  sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

# ---------------------- Install Prometheus ----------------------
install_prometheus() {
  echo "📌 Fetching Latest Prometheus Version..."
  PROMETHEUS_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
  check_success

  echo "📌 Installing Prometheus ($PROMETHEUS_VERSION)..."
  sudo mkdir -p /etc/prometheus /var/lib/prometheus
  cd /usr/local/bin
  wget https://github.com/prometheus/prometheus/releases/download/$PROMETHEUS_VERSION/prometheus-${PROMETHEUS_VERSION#v}.linux-${ARCH}.tar.gz
  check_success

  tar xvf prometheus-${PROMETHEUS_VERSION#v}.linux-${ARCH}.tar.gz
  check_success
  sudo mv prometheus-${PROMETHEUS_VERSION#v}.linux-${ARCH}/prometheus prometheus-${PROMETHEUS_VERSION#v}.linux-${ARCH}/promtool .
  sudo mv prometheus-${PROMETHEUS_VERSION#v}.linux-${ARCH}/consoles prometheus-${PROMETHEUS_VERSION#v}.linux-${ARCH}/console_libraries /etc/prometheus/
  rm -rf prometheus-${PROMETHEUS_VERSION#v}*

  # Create Prometheus Configuration
  sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

  # Create Prometheus Service
  sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF
}

# ---------------------- Install Grafana ----------------------
install_grafana() {
  echo "📌 Installing musl (dependency for Grafana)..."
  sudo apt install musl -y
  check_success

  echo "📌 Fetching Latest Grafana Version..."
  GRAFANA_VERSION=$(curl -s https://api.github.com/repos/grafana/grafana/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
  check_success

  echo "📌 Installing Grafana ($GRAFANA_VERSION)..."
  wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION#v}_${ARCH}.deb
  check_success

  sudo dpkg -i grafana_${GRAFANA_VERSION#v}_${ARCH}.deb
  check_success
  rm -f grafana_${GRAFANA_VERSION#v}_${ARCH}.deb
}

# ---------------------- Start Services ----------------------
start_services() {
  echo "📌 Enabling Services..."
  sudo systemctl daemon-reload
  check_success

  sudo systemctl enable --now node_exporter
  check_success
  sudo systemctl enable --now prometheus
  check_success
  sudo systemctl enable --now grafana-server
  check_success
}

# ---------------------- Configure Firewall ----------------------
function update_firewall() {
    # Check if iptables is installed
    if ! command -v iptables &> /dev/null; then
        echo "⚠️ iptables is not installed. Skipping firewall configuration..."
        return 0
    fi

    info "Updating firewall rules"
    RULES=(
        "INPUT -p tcp -m state --state NEW -m tcp --dport 3000 -j ACCEPT"
        "INPUT -p tcp -m state --state NEW -m tcp --dport 9090 -j ACCEPT"
        "INPUT -p tcp -m state --state NEW -m tcp --dport 9100 -j ACCEPT"
    )
    FIREWALL_RULES_ADDED=false
    for RULE in "${RULES[@]}"; do
        # shellcheck disable=SC2086 # We need the variable to be split
        if ! sudo iptables -C ${RULE} 2>/dev/null; then
            # shellcheck disable=SC2086 # We need the variable to be split
            sudo iptables -I ${RULE}
            FIREWALL_RULES_ADDED=true
        fi
    done
    if $FIREWALL_RULES_ADDED; then
        sudo cp /etc/iptables/rules.v4{,.bak.monitor}
        TMP_FILE=$(mktemp)

        # shellcheck disable=SC2024 # We need to run the command as root
        sudo iptables-save >"${TMP_FILE}"
        sudo mv "${TMP_FILE}" /etc/iptables/rules.v4
        echo "📌 Firewall rules updated and saved."
    else
        echo "No new firewall rules to add. Firewall is up-to-date."
    fi
    echo "✅ Firewall configuration completed."
    check_success
}
# ---------------------- Final Status ----------------------
display_status() {
  echo "✅ Installation Complete!"
  echo "--------------------------------------"
  echo "🌐 Access Grafana: http://$(curl -s ifconfig.me):3000"
  echo "📊 Access Prometheus: http://$(curl -s ifconfig.me):9090"
  echo "📈 Node Exporter Metrics: http://$(curl -s ifconfig.me):9100/metrics"
  echo "--------------------------------------"

  # Show service statuses
  systemctl status prometheus --no-pager --lines 5
  systemctl status node_exporter --no-pager --lines 5
  systemctl status grafana-server --no-pager --lines 5
}

# Main function to execute all steps
main() {
  detect_architecture
  update_system
  install_node_exporter
  install_prometheus
  install_grafana
  start_services
  configure_firewall
  display_status
}

# Run main function and log output
main | tee setup.log
