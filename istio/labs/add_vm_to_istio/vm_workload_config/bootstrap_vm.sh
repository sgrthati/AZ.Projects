#!/bin/bash
set -euxo pipefail
# This script must be run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Attempting to elevate privileges..."
  sudo "$0" "$@"
  exit $?
fi
# # Update and install Docker if not already installed
# sudo apt-get update
# sudo apt-get install -y docker.io
# # Start Docker service
# sudo systemctl start docker
# sudo systemctl enable docker
# # Pull the Docker image
# sudo docker pull docker.io/istio/examples-helloworld-v2:1.0
# # Run the Docker container and expose it on port 5000
# sudo docker run -d -p 5000:5000 docker.io/istio/examples-helloworld-v2:1.0

# Update the system
sudo apt-get update && sudo apt-get upgrade -y
# Install Python and pip
sudo apt-get install python3 python3-pip -y
# Create the application directory
mkdir -p ~/myflaskapp
cd ~/myflaskapp
hostname=$(hostname)
# Create the Flask application
echo "from flask import Flask
app = Flask(__name__)
@app.route('/hello')
def hello():
    return \"Hello version: v2, instance: $hostname\"
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)" > app.py
# Install Flask
pip3 install flask
# Allow traffic on port 5000
sudo ufw allow 5000
# Run the application
nohup python3 app.py &


#Install the root certificate at /etc/certs
sudo mkdir -p /etc/certs
sudo cp /tmp/root-cert.pem /etc/certs/root-cert.pem

#Install the token at /var/run/secrets/tokens
sudo  mkdir -p /var/run/secrets/tokens
sudo cp /tmp/istio-token /var/run/secrets/tokens/istio-token

#Install the package containing the Istio virtual machine integration runtime
curl -LO https://storage.googleapis.com/istio-release/releases/1.22.2/deb/istio-sidecar.deb
sudo dpkg -i istio-sidecar.deb

#Install cluster.env within the directory /var/lib/istio/envoy/
sudo cp /tmp/cluster.env /var/lib/istio/envoy/cluster.env

#Install the Mesh Config to /etc/istio/config/mesh
sudo cp /tmp/mesh.yaml /etc/istio/config/mesh

#Add the istiod host to /etc/hosts
sudo  echo $(cat /tmp/hosts) >> /etc/hosts

#hostname of the machine to the hosts file
echo "$(hostname --all-ip-addresses | cut -d ' ' -f 1) $(hostname)" | sudo sh -c 'cat >> /etc/hosts'

#Transfer ownership of the files in /etc/certs/ and /var/lib/istio/envoy/ to the Istio proxy
sudo mkdir -p /etc/istio/proxy
sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem

#start istio-sidecar service 
sudo systemctl start istio