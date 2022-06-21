from functools import reduce
from urllib.parse import urlparse
from hpecp import ContainerPlatformClient
from http import HTTPStatus
from flask import Flask, jsonify, request, Response, send_from_directory
from flask_cors import CORS, cross_origin
from waitress import serve
import subprocess
import os, json, base64
from configparser import ConfigParser

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

def get_base64_string(str):
  return base64.b64encode(str.encode()).decode()

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
# @app.route('/projects', methods=['GET', 'PUT', 'DELETE'])
# def get_projects():
#   if request.method == 'GET':
#     return jsonify([d for d in os.listdir(base_path + '/projects/') if d != 'archived' ])
#   if request.method == 'PUT':
#     os.mkdir(base_path + '/projects/' + request.form['name'])
#     return Response(status=HTTPStatus.OK)
#   if request.method == 'DELETE':
#     os.rename(base_path + '/projects/' + request.form['name'], base_path + '/projects/archived/' + request.form['name'])
#     return Response(status=HTTPStatus.OK)

# @app.route('/yaml/<filename>', methods=['GET'])
# def get_yaml(filename):
#   if request.method == 'GET':
#     try:
#       return send_from_directory(directory=base_path + '/files/yaml/', path=filename)
#     except:
#       return Response(status=HTTPStatus.NOT_FOUND)

@app.route('/platform/<op>', methods=['POST', 'DELETE'])
def platform(op=None):
  data = request.get_json(force=True)
  try:
    url = urlparse(data['url'])
  except Exception as err:
    print('Invalid request', f"{err=}")
    return Response(status=HTTPStatus.UNAUTHORIZED)

  if data['payload'] is not None and 'tenant' in data['payload']:
    client = ContainerPlatformClient(
            username=data['username'],
            password=data['password'],
            api_host=url.hostname,
            api_port=int(url.port or 8080),
            use_ssl=url.scheme == 'https',
            verify_ssl=False,
            tenant=data['payload']['tenant']['_links']['self']['href']
          )
  else:
    client = ContainerPlatformClient(
            username=data['username'],
            password=data['password'],
            api_host=url.hostname,
            api_port=int(url.port or 8080),
            use_ssl=url.scheme == 'https',
            verify_ssl=False
          )

  if request.method == 'POST':
    try:
      if op == 'connect':
        client.create_session() # Login
        return jsonify(client.config.get())
      elif op == 'list':
        client.create_session() # Login
        # try: # get cluster list if user has access
        #   clusters = { 'clusters' : [({ 'id': x.id, 'name': x.name, 'description': x.description, 'k8s_version': x.k8s_version, 'status': x.status}) for x in client.k8s_cluster.list()] }
        # except Exception:
        #   clusters = { 'clusters' : [] }
        # query details for each tenant
        tenants = { 'tenants' : [ y.json for y in [ client.tenant.get(t) for t in [ x.id for x in client.tenant.list() ] ] ] }
        # or get simple information about tenants
        # tenants = { 'tenants' : [({ 'id': x.id, 'name': x.name, 'description': x.description,'status': x.status, 'tenant_type': x.tenant_type }) for x in client.tenant.get('/api/v1/tenant/')] }
        return jsonify(tenants)
        # return jsonify({**clusters, **tenants})
      # elif op == 'tenants':
      #   client.create_session() # Login
      #   return jsonify([({ 'id': x.id, 'name': x.name, 'description': x.description,'status': x.status, 'tenant_type': x.tenant_type }) for x in client.tenant.list()])
      elif op == 'apply' or op == 'delete':
        tenant = data['payload']['tenant']
        app = data['payload']['app']
        client.create_session() # Login

        # TODO: ensure mlops enabled and datatap/tenantstorage configured in the tenant etc

        if not tenant['features']['ml_project'] or not tenant['state'] == 'ready':
          return jsonify('Tenant not ready')

        # get replacement parameters
        # t_id = client.tenant_config
        ns = tenant['namespace']
        kubeconfig = get_base64_string(client.tenant.k8skubeconfig())

        # Replacements
        repls = (
          ('TENANTNS', ns),
          ('KUBECONFIG', kubeconfig),
          ('USERNAME', data['username']),
          ('USERID', data['username']),
          ('STORAGECLASS', 'CHANGEME'),
          ('KCSECRET', 'CHANGEME'),
          ('NBCLUSTER', data['username'] + '_Notebook'),
          ('TRAINING_CLUSTER', data['username'] + '_Training'),
          ('MLFLOW_CLUSTER', data['username'] + '_Mlflow')
        )
        # update yaml files
        for file in app['deploy']:
          loaded_yaml = ""
          with open(os.path.join(base_path, 'yaml', file['yaml']), 'r') as stream:
            for line in stream:
              loaded_yaml += line
          # submit jobs
          try:
            cleaned_yaml = reduce(lambda a, kv: a.replace(*kv), repls, loaded_yaml)
            return jsonify(client.k8s_cluster.run_kubectl_command(tenant['k8s_cluster'], op, get_base64_string(cleaned_yaml)))
          except BaseException as err:
            print(f"{err=}")
            return jsonify(err.message), HTTPStatus.NOT_ACCEPTABLE
                
        return Response(status=HTTPStatus.OK)

    except Exception as err:
      print(f"{err=}")
      return Response(format(err), status=HTTPStatus.UNAUTHORIZED)

    return Response(status=HTTPStatus.NOT_IMPLEMENTED)
      
  if request.method == 'DELETE':
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