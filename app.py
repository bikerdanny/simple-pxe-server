from flask import Flask, request, render_template
from flask_cors import CORS
import subprocess
import os

app = Flask(__name__)
CORS(app)

@app.route("/deploy/<string:mac>")
def deploy(mac):
    result = subprocess.run(['./deploy.sh', f"{mac}"], capture_output=True, text=True)
    return result.stdout

@app.route("/finish")
def finish():
    result = subprocess.run(['./finish.sh', f"{request.remote_addr}"], capture_output=True, text=True)
    return result.stdout

@app.route("/hosts")
def hosts():
    result = subprocess.run(['./hosts.sh'], capture_output=True, text=True)
    return app.response_class(response=result.stdout, status=200, mimetype='application/json')

@app.route("/")
def root():
    return render_template("index.html")
