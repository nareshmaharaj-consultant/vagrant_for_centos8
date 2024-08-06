# Monitoring
wget -q https://github.com/prometheus/prometheus/releases/download/v2.48.0-rc.1/prometheus-2.48.0-rc.1.linux-amd64.tar.gz
tar -xvf prometheus-2.48.0-rc.1.linux-amd64.tar.gz
cd prometheus-2.48.0-rc.1.linux-amd64/
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus
sudo mkdir -p /data
sudo cp prometheus promtool /usr/local/bin/
sudo cp -R consoles/ console_libraries/ /etc/prometheus/
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
prometheus --version
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/  /var/lib/prometheus/ /data
sudo chmod -R 775 /etc/prometheus/ /var/lib/prometheus/
sudo chown -R 1000:1000 /data/

sudo tee /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Restart=always
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries --web.listen-address=0.0.0.0:9090
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo sed -i "s/- job_name\: \"prometheus\"/- job_name\: \"aerospike\"/g" /etc/prometheus/prometheus.yml
sudo sed -i "s/- targets\: \[\"localhost\:9090\"\]/- targets\: \[\"asd01\:9145\",\"asd02\:9145\",\"asd03\:9145\",\"asd04\:9145\",\"asd05\:9145\",\"asd06\:9145\"\]/g" /etc/prometheus/prometheus.yml
sudo sed -i "s/\# \- \"first_rules.yml\"/\- \"\/etc\/prometheus\/aerospike_rules.yml\"/g" /etc/prometheus/prometheus.yml
wget -q https://raw.githubusercontent.com/aerospike/aerospike-monitoring/master/config/prometheus/aerospike_rules.yml
sudo mv aerospike_rules.yml /etc/prometheus/aerospike_rules.yml
sudo systemctl restart prometheus

# Grafana
sudo tee /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
sudo yum install grafana -y
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo sed -i "s/\;provisioning \= conf\/provisioning/provisioning \= \/etc\/grafana\/provisioning/g" /etc/grafana/grafana.ini
sudo mkdir -p /etc/grafana/provisioning/datasources
sudo mkdir -p /etc/grafana/provisioning/dashboards
sudo mkdir -p /var/lib/grafana/dashboards
wget -q https://raw.githubusercontent.com/aerospike/aerospike-monitoring/master/config/grafana/provisioning/dashboards/all.yaml
sudo mv all.yaml /etc/grafana/provisioning/dashboards
wget -q https://raw.githubusercontent.com/aerospike/aerospike-monitoring/master/config/grafana/provisioning/dashboards/all.yaml
sudo mv all.yaml /etc/grafana/provisioning/datasources/
sudo grafana-cli plugins install camptocamp-prometheus-alertmanager-datasource
rm -fr aerospike-monitoring
git clone https://github.com/aerospike/aerospike-monitoring.git
cd aerospike-monitoring/config/grafana/dashboards
sudo cp -r * /var/lib/grafana/dashboards/
sudo chown -R grafana: /var/lib/grafana
sudo systemctl restart grafana-server
