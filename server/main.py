from crypt import methods
from email.quoprimime import unquote
from http import HTTPStatus
import itertools
from flask import Flask, jsonify, request, Response, send_from_directory, abort
from flask_cors import CORS, cross_origin
from waitress import serve
# from sys import platform
import subprocess
import os, json
from configparser import ConfigParser

# from werkzeug.wrappers import response

base_path = os.path.dirname(__file__)

app = Flask(__name__, static_url_path='', static_folder=os.path.join(base_path, '..', 'build'))
CORS(app)

ProviderName = {
  'aws': 'AWS',
  'azure': 'Azure',
  'dc': 'Data Centre'
}
# if (platform == 'darwin'):
#   ProviderName['mac'] = 'Mac'
config = ConfigParser()

## Pass environment variable to scripts, tell them they are running under web process
web_env = os.environ.copy()
web_env['EZWEB'] = 'true'
web_env['EZWEB_TF'] = '-no-color'

def get_target_dir(env):
  return [x for x,y in ProviderName.items() if y.lower() == env.lower()][0]

@app.route('/')
@cross_origin()
def home():
  return app.send_static_file('index.html')

@app.route('/<target>/config')
def get_config(target):
  response = None
  search_path = os.path.join(base_path, get_target_dir(target))
  conf_file =  os.path.join(search_path, 'config.json')
  conf_template = os.path.join(search_path, 'config.json-template')
  dc_file = os.path.join(search_path, 'dc.ini')
  for file in [conf_file, conf_template, dc_file]:
    try:
      with open(file, "r") as f:
        try:
          response = json.load(f)
          break
        except json.JSONDecodeError:
          config.read(file)
          js = {}
          for k,v in [ pair for items in [ config.items(section) for section in config.sections() ] for pair in items ]:
            js[k] = v
          response = js
          break
    except OSError as err:
      print(file, err.strerror)
      response = Response(status=HTTPStatus.NO_CONTENT)
  return response

@app.route('/usersettings')
def get_usersettings():
  response = None
  with open('user.settings') as f:
    response=json.load(f)
  return response

@app.route('/<target>/deploy', methods = ['POST'])
async def deploy(target: str):
  data = request.get_json(force=True, silent=True)
  conf_file = base_path + '/' + get_target_dir(target) + '/config.json'
  with open(conf_file, 'w') as f:
    if data['config']:
      json.dump(data['config'], f)
  settings_file = base_path + '/' + 'user.settings'
  with open(settings_file, 'w') as f:
    if data['usersettings']:
      json.dump(data['usersettings'], f)
  def inner():
    process = subprocess.Popen(['./00-run_all.sh', get_target_dir(target)], cwd=base_path, universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=web_env)
    for line in iter(process.stdout.readline,''):
      yield line
  return Response(inner(), mimetype='html/text')
  
@app.route('/<target>/destroy', methods = ['POST'])
async def destroy(target: str):
  def inner():
    process = subprocess.Popen(['./99-destroy.sh', get_target_dir(target)], cwd=base_path, universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=web_env)
    for line in iter(process.stdout.readline,''):
      yield line
  return Response(inner(), mimetype='html/text')

@app.route('/providers')
def read_providers():
    return jsonify(list(ProviderName[x] for x in ProviderName))

allowed_files = ['aws/run.log', 'azure/run.log', 'dc/run.log', 'generated/controller.prv_key']

@app.route('/isfile/<path:logfile>')
def isFile(logfile: str):
  file_path = os.path.join(get_target_dir(logfile.split('/')[0]), logfile.split('/')[1])
  if file_path in allowed_files and os.path.exists(os.path.join(base_path, file_path)):
    return Response(status=HTTPStatus.OK)
  else:
    return Response(status=HTTPStatus.NO_CONTENT)

@app.route('/log/<target>')
def getlog(target: str):
  try:
    return send_from_directory(directory=base_path + '/' + get_target_dir(target), path='run.log')
  except FileNotFoundError:
    return Response(status=HTTPStatus.NO_CONTENT)

@app.route('/logstream/<target>')
def getlogstream(target: str):
  def inner():
    process = subprocess.Popen(['tail', '-f', get_target_dir(target) + '/run.log'], cwd=base_path, universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in iter(process.stdout.readline,''):
      yield line
  return Response(inner(), mimetype='html/text')

@app.route('/key')
def getkey():
  try:
    return send_from_directory(directory=base_path + '/generated', path='controller.prv_key')
  except FileNotFoundError:
    return Response(status=HTTPStatus.NO_CONTENT)

### v2 functions
@app.route('/projects', methods=['GET', 'PUT', 'DELETE'])
def get_projects():
  if request.method == 'GET':
    return jsonify([d for d in os.listdir(base_path + '/projects/') if d != 'archived' ])
  if request.method == 'PUT':
    os.mkdir(base_path + '/projects/' + request.form['name'])
    return Response(status=HTTPStatus.OK)
  if request.method == 'DELETE':
    os.rename(base_path + '/projects/' + request.form['name'], base_path + '/projects/archived/' + request.form['name'])
    return Response(status=HTTPStatus.OK)

if __name__ == '__main__':
  if 'DEV' in os.environ:
   app.run(
     host='0.0.0.0',
     debug = True,
     port=4000
    )
  else:
    serve(app, host='0.0.0.0', port=4000)