from flask import Flask
import os

app = Flask(__name__)

@app.route('/hello')
def hello():
    hostname = os.getenv("INSTANCE_NAME", "unknown")
    return f"Hello version: v1, instance: {hostname}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
