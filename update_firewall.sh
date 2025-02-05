#!/bin/bash

# Function to check if last command was successful
check_success() {
  if [ $? -ne 0 ]; then
    echo "❌ Error encountered in previous step. Exiting..."
    exit 1
  fi
}

# Detect System Architecture (ARM or AMD64)
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

echo "🚀 Updating System..."
sudo apt update && sudo apt upgrade -y
check_success

# ---------------------- Configure Firewall ----------------------

echo ""
echo "📌 Ensuring iptables is installed..."
sudo apt install -y iptables iptables-persistent
check_success

echo "📌 Creating default iptables rules file if missing..."
if [ ! -f /etc/iptables/rules.v4 ]; then
    sudo mkdir -p /etc/iptables
    sudo tee /etc/iptables/rules.v4 > /dev/null <<EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
EOF
fi

echo ""
echo "📌 Configuring Firewall..."
info "Updating firewall rules"
RULES=(
    "INPUT -p tcp -m state --state NEW -m tcp --dport 3000 -j ACCEPT"
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
    info "Firewall rules updated and saved."
else
    notify "No new firewall rules to add. Firewall is up-to-date."
fi
check_success

echo ""
echo "📌 Saving firewall rules..."
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
