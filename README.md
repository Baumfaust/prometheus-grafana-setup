# 🚀 Prometheus & Grafana Auto-Installer  

![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-orange?style=for-the-badge) 
![Grafana](https://img.shields.io/badge/Grafana-Dashboard-blue?style=for-the-badge) 
![Automation](https://img.shields.io/badge/Automation-Bash-green?style=for-the-badge)  

## 🎯 **Overview**  
This **automated setup script** installs and configures:  
✅ [Prometheus](https://prometheus.io/) - **Metrics Collection**  
✅ [Node Exporter](https://github.com/prometheus/node_exporter) - **Server Monitoring**  
✅ [Grafana](https://grafana.com/) - **Data Visualization**  
✅ **Firewall Configuration** (optional, auto-detected)  

---

## 🛠 **Installation**  

### 1️⃣ **Download & Run the Script**  
```
git clone https://github.com/your-repo/prometheus-grafana-setup.git
cd prometheus-grafana-setup
chmod +x install_monitoring.sh
./install_monitoring.sh
```

### 2️⃣ **Wait for Installation**  
The script will:  
✔️ Detect your system architecture  
✔️ Install necessary packages  
✔️ Set up services for **Prometheus, Grafana, and Node Exporter**  
✔️ Optionally configure **iptables firewall**  

---

## 🌐 **Access Your Services**  

| Service      | URL                                      |
|-------------|------------------------------------------|
| 📊 **Grafana**  | [http://your-server-ip:3000](http://your-server-ip:3000) |
| 📈 **Prometheus**  | [http://your-server-ip:9090](http://your-server-ip:9090) |
| 🔍 **Node Exporter** | [http://your-server-ip:9100/metrics](http://your-server-ip:9100/metrics) |

---

## 🔥 **Features**  
✨ **Fully Automated** – One command to set up everything  
✨ **Firewall Rules** – **Only if** iptables is installed  
✨ **Service Management** – Enables & starts systemd services  
✨ **Logging Enabled** – Outputs to `setup.log`  

---

## 📌 **Requirements**  
- ✅ Ubuntu / Debian (64-bit)  
- ✅ `sudo` permissions  
- ✅ Internet connection  

---

## ❌ **Uninstall**  
To remove all services and configurations:  
```
sudo systemctl stop prometheus node_exporter grafana-server
sudo systemctl disable prometheus node_exporter grafana-server
sudo rm -rf /usr/local/bin/node_exporter /usr/local/bin/prometheus /etc/prometheus /var/lib/prometheus
sudo apt remove --purge grafana -y
```

---

## 💡 **Contributions & Support**  
📌 Feel free to **fork, improve, and submit PRs**!  
💬 **Questions?** Open an issue or reach out!  

🚀 Happy Monitoring! 🎯  
