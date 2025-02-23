from flask import Flask, request, jsonify
from spyne import Application, rpc, ServiceBase, Integer, Unicode
from spyne.protocol.soap import Soap11
from spyne.server.wsgi import WsgiApplication  # Use WsgiApplication instead of FlaskApplication

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