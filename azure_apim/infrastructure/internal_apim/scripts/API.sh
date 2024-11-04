#!/bin/bash
set -euxo pipefail
# Install Python and pip if not already installed
if ! command -v python3 &> /dev/null
then
    echo "Python3 not found. Installing..."
    sudo apt update
    sudo apt install python3 -y
fi

# Install pip3 if not already installed
if ! command -v pip3 &> /dev/null
then
    echo "pip3 not found. Installing..."
    sudo apt update
    sudo apt install python3-pip -y
fi

# Install Flask for REST API
pip3 install Flask

# Install SOAP module if needed
pip3 install spyne
pip3 install lxml
pip3 install werkzeug

# Create the Flask application
APP_DIR="my_api_app"
mkdir -p $APP_DIR
cd $APP_DIR

# Create the REST and SOAP app script
cat <<EOL > app.py
from flask import Flask, request, jsonify
from spyne import Application, rpc, ServiceBase, Integer, Unicode
from spyne.protocol.soap import Soap11
from spyne.server.wsgi import WsgiApplication

app = Flask(__name__)

# In-memory data storage (shared by both REST and SOAP)
resources = [
    {"name": "John Doe", "id": 1, "info": "Some initial info"},
    {"name": "Jane Doe", "id": 2, "info": "Additional info"}
]

# REST API operations
@app.route('/api/resource', methods=['GET'])
def get_resource():
    return jsonify({"resources": resources})

@app.route('/api/resource', methods=['POST'])
def post_resource():
    data = request.get_json()
    resources.append(data)
    return jsonify({"message": "POST request successful", "data": data})

@app.route('/api/resource', methods=['PUT'])
def put_resource():
    data = request.get_json()
    for resource in resources:
        if resource["id"] == data["id"]:
            resource["name"] = data["name"]
            resource["info"] = data["info"]
            break
    return jsonify({"message": "PUT request successful", "data": data})

@app.route('/api/resource', methods=['DELETE'])
def delete_resource():
    data = request.get_json()
    global resources
    resources = [resource for resource in resources if resource["id"] != data["id"]]
    return jsonify({"message": "DELETE request successful"})

# SOAP API Service
class SoapService(ServiceBase):
    @rpc(Unicode, Integer, Unicode, _returns=Unicode)
    def get_resource(ctx, name, id, info):
        resources.append({"name": name, "id": id, "info": info})
        return f"Resource added: {name} (ID: {id}), Info: '{info}'"

    @rpc(_returns=Unicode)
    def list_resources(ctx):
        resource_list = "\n".join([f"Name: {r['name']}, ID: {r['id']}, Info: {r['info']}" for r in resources])
        return f"Resources:\n{resource_list}"

# Configure WSGI for SOAP
soap_app = Application([SoapService], 'spyne.examples.resource.soap',
                       in_protocol=Soap11(validator='lxml'),
                       out_protocol=Soap11())
wsgi_app = WsgiApplication(soap_app)

# Integrate the WSGI app with Flask
from werkzeug.middleware.dispatcher import DispatcherMiddleware
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/soap': wsgi_app
})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL
#creating a service
cat <<EOL > /etc/systemd/system/my_api_app.service
[Unit]
Description=My API App Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /my_api_app/app.py
WorkingDirectory=/my_api_app
Restart=always
User=adminuser

[Install]
WantedBy=multi-user.target
EOL

# Run the application
sudo systemctl daemon-reload
sudo systemctl start my_api_app.service
sudo systemctl enable my_api_app.service
echo "Starting the application..."
echo "Application is running on http://localhost:5000"
echo "REST API endpoints available at /api/resource"
echo "SOAP API available at /soap/"
