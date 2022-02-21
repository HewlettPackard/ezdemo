from enum import Enum
from http import HTTPStatus
from flask import Flask, jsonify, request, Response, send_from_directory, abort
from flask_cors import CORS, cross_origin
from waitress import serve
from sys import platform
import subprocess
import os, json

# from werkzeug.wrappers import response

base_path = os.path.dirname(__file__)

app = Flask(__name__, static_url_path='', static_folder=os.path.join(base_path, '..', 'build'))
CORS(app)

ProviderName = {
  "aws": "AWS",
  "azure": "Azure",
  # vmware = "VMWare"
  # kvm = "KVM"
  # ovirt = "OVirt"
}
if (platform == "darwin"):
  ProviderName["mac"] = "Mac"

## Pass environment variable to scripts, tell them they are running under web process
web_env = os.environ.copy()
web_env["EZWEB"] = "true"
web_env["EZWEB_TF"] = "-no-color"

@app.route('/')
@cross_origin()
def home():
  return app.send_static_file('index.html')

@app.route('/<target>/config')
def get_config(target):
  response = None
  conf_file = base_path + '/' + target + '/config.json'
  if os.path.isfile(conf_file) and os.path.getsize(conf_file) > 0:
    with open(conf_file) as f:
      response = json.load(f)
  else:
    with open(conf_file + '-template') as f:
      response = json.load(f)
  return response

@app.route('/<target>/deploy', methods = ['POST'])
async def init(target: str):
  conf_file = base_path + '/' + target + '/config.json'
  with open(conf_file, 'w') as f:
    json.dump(request.get_json(force=True, silent=True), f)
  def inner():
    process = subprocess.Popen(['./00-run_all.sh', target], cwd=base_path, universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=web_env)
    for line in iter(process.stdout.readline,''):
      yield line
  return Response(inner(), mimetype='html/text')
  
@app.route('/<target>/destroy', methods = ['POST'])
async def destroy(target: str):
  def inner():
    process = subprocess.Popen(['./99-destroy.sh', target], cwd=base_path, universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=web_env)
    for line in iter(process.stdout.readline,''):
      yield line
  return Response(inner(), mimetype='html/text')

# @app.route('/<target>/log')
# async def log(target: str):
#   def inner():
#     process = subprocess.Popen(['tail', '-f', target + '/run.log'], cwd=base_path, universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
#     for line in iter(process.stdout.readline,''):
#       yield line
#   return Response(inner(), mimetype='html/text')

@app.route('/providers')
def read_providers():
    return jsonify(list(ProviderName[x] for x in ProviderName))

allowed_files = ['aws/run.log', 'azure/run.log', 'mac/run.log','generated/controller.prv_key']

@app.route('/isfile/<path:logfile>')
def isFile(logfile: str):
  if logfile not in allowed_files or not os.path.exists(logfile):
    return Response(status=HTTPStatus.NO_CONTENT)
  else:
    return Response(status=HTTPStatus.OK)

@app.route('/log/<target>')
def getlog(target: str):
  try:
    return send_from_directory(directory=base_path + '/' + target, path='run.log')
  except FileNotFoundError:
    return Response(status=HTTPStatus.NO_CONTENT)

@app.route('/key')
def getkey():
  try:
    return send_from_directory(directory=base_path + '/generated', path='controller.prv_key')
  except FileNotFoundError:
    return Response(status=HTTPStatus.NO_CONTENT)

if __name__ == '__main__':
  if "DEV" in os.environ:
   app.run(
     host="0.0.0.0",
     debug = True,
     port=4000
    )
  else:
    serve(app, host="0.0.0.0", port=4000)