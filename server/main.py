from functools import reduce
import hashlib
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

app = Flask(
    __name__, static_url_path="", static_folder=os.path.join(base_path, "..", "build")
)
CORS(app)

config = ConfigParser()

## Application definitions
ml_apps = [
    {
        "title": "ML 101",
        "description": "Machine Learning starting point, requires K8s admin rights to create mlflow and source control.",
        "depends": ["kubeflow"],
        "deploy": [
            {"name": "kcsecret", "yaml": "kcsecret.yml"},
            {"name": "mlflow", "yaml": "mlflow.yml"},
            {"name": "sourcecontrol", "yaml": "sourcecontrol.yml"},
            {"name": "trainingcluster", "yaml": "training.yml"},
            {"name": "notebook", "yaml": "notebook.yml"},
        ],
    },
    {
        "title": "Jupyter Notebook",
        "description": "Just a Jupyter Notebook with pytorch, tensorflow and more libraries.",
        "depends": [],
        "deploy": [
            {"name": "kcsecret", "yaml": "kcsecret.yml"},
            {"name": "notebook", "yaml": "notebook.yml"},
        ],
    },
    {
        "title": "Hello World",
        "description": "Welcome to Kubernetes",
        "depends": [],
        "deploy": [{"name": "helloworld", "yaml": "helloworld.yml"}],
    },
]

## Pass environment variable to scripts, tell them they are running under web process
web_env = os.environ.copy()
web_env["EZWEB"] = "true"
web_env["EZWEB_TF"] = "-no-color"


def get_target_dir(target):
    return "dc" if target == "ovirt" or target == "vmware" else target


def get_base64_string(str):
    return base64.b64encode(str.encode()).decode()


@app.route("/")
@cross_origin()
def home():
    return app.send_static_file("index.html")


@app.route("/<target>/config", methods=["GET", "POST"])
def getset_config(target):
    search_path = os.path.join(base_path, get_target_dir(target))
    dc_file = os.path.join(base_path, "dc", "dc.ini")
    dc_template = os.path.join(base_path, "dc" "dc.ini-template")
    conf_file = os.path.join(search_path, "config.json")
    conf_template = os.path.join(search_path, "config.json-template")

    if request.method == "GET":
        response = None
        if target in ["vmware", "ovirt"]:
            config.read([dc_template, dc_file])
            response = dict(config.items(section="DEFAULT"))
        else:  # get cloud config settings
            for file in [conf_file, conf_template]:
                try:
                    with open(file, "r") as f:
                        response = json.load(f)
                        break
                except OSError as err:
                    print(file, err.strerror)
                    response = Response(status=HTTPStatus.NO_CONTENT)

        if "DEV" in os.environ:
            print("config read", response)

        return response
    else:  # GET request
        if target in ["aws", "azure"]:
            data = request.get_json(force=True, silent=True)
            with open(conf_file, "w") as f:
                if data["config"]:
                    json.dump(data["config"], f)
        else:
            data = request.get_json()
            with open(dc_file, "w") as f:
                if data["config"]:
                    config["DEFAULT"] = data[
                        "config"
                    ]  # Set default section with all values
                    config.write(f, space_around_delimiters=False)

        if "DEV" in os.environ:
            print("config write", data)

        return Response(status=HTTPStatus.OK)


@app.route("/usersettings", methods=["GET", "POST"])
def getset_usersettings():
    if request.method == "GET":
        response = None
        user_settings_file = "user.settings-template"
        if os.path.isfile(os.path.join(base_path, "user.settings")):
            print("existing settings file for the user")
            user_settings_file = "user.settings"
        with open(user_settings_file) as f:
            response = json.load(f)

        if "DEV" in os.environ:
            print("user settings read", response)

        return response
    else:  # POST Request
        data = request.get_json(force=True, silent=True)
        settings_file = base_path + "/" + "user.settings"

        if "DEV" in os.environ:
            print("user settings write", data["usersettings"])

        with open(settings_file, "w") as f:
            if data["usersettings"]:
                json.dump(data["usersettings"], f)

        return Response(status=HTTPStatus.OK)


@app.route("/<target>/deploy", methods=["POST"])
async def deploy(target: str):
    def inner():
        process = subprocess.Popen(
            ["./00-run_all.sh", get_target_dir(target)],
            cwd=base_path,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=web_env,
        )
        for line in iter(process.stdout.readline, ""):
            yield line

    return Response(inner(), mimetype="html/text")


@app.route("/<target>/destroy", methods=["POST"])
async def destroy(target: str):
    def inner():
        process = subprocess.Popen(
            ["./99-destroy.sh", get_target_dir(target)],
            cwd=base_path,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=web_env,
        )
        for line in iter(process.stdout.readline, ""):
            yield line

    return Response(inner(), mimetype="html/text")


allowed_files = [
    "aws/run.log",
    "azure/run.log",
    "dc/run.log",
    "generated/controller.prv_key",
]


@app.route("/isfile/<path:logfile>")
def isFile(logfile: str):
    print(logfile) if "DEV" in os.environ else None
    file_path = os.path.join(
        get_target_dir(logfile.split("/")[0]), logfile.split("/")[1]
    )
    print(file_path) if "DEV" in os.environ else None
    print(file_path in allowed_files) if "DEV" in os.environ else None
    if file_path in allowed_files and os.path.exists(
        os.path.join(base_path, file_path)
    ):
        print("log found") if "DEV" in os.environ else None
        return Response(status=HTTPStatus.OK)
    else:
        print("no log found") if "DEV" in os.environ else None
        return Response(status=HTTPStatus.NO_CONTENT)


@app.route("/log/<target>")
def getlog(target: str):
    try:
        return send_from_directory(
            directory=base_path + "/" + get_target_dir(target), path="run.log"
        )
    except FileNotFoundError:
        return Response(status=HTTPStatus.NO_CONTENT)


@app.route("/logstream/<target>")
def getlogstream(target: str):
    def inner():
        process = subprocess.Popen(
            ["tail", "-2000f", get_target_dir(target) + "/run.log"],
            cwd=base_path,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        for line in iter(process.stdout.readline, ""):
            yield line

    return Response(inner(), mimetype="html/text")


@app.route("/key")
def getkey():
    try:
        return send_from_directory(
            directory=base_path + "/generated", path="controller.prv_key"
        )
    except FileNotFoundError:
        return Response(status=HTTPStatus.NO_CONTENT)


### v2 functions
# @app.route("/projects", methods=["GET", "PUT", "DELETE"])
# def get_projects():
#   if request.method == "GET":
#     return jsonify([d for d in os.listdir(base_path + "/projects/") if d != "archived" ])
#   if request.method == "PUT":
#     os.mkdir(base_path + "/projects/" + request.form["name"])
#     return Response(status=HTTPStatus.OK)
#   if request.method == "DELETE":
#     os.rename(base_path + "/projects/" + request.form["name"], base_path + "/projects/archived/" + request.form["name"])
#     return Response(status=HTTPStatus.OK)

# @app.route("/yaml/<filename>", methods=["GET"])
# def get_yaml(filename):
#   if request.method == "GET":
#     try:
#       return send_from_directory(directory=base_path + "/files/yaml/", path=filename)
#     except:
#       return Response(status=HTTPStatus.NOT_FOUND)


@app.route("/mlapps")
def getmlapps():
    return jsonify(ml_apps)


@app.route("/platform/<op>", methods=["POST", "DELETE"])
def platform(op=None):
    data = request.get_json(force=True)
    try:
        url = urlparse(data["url"])
    except Exception as err:
        print("Invalid request", f"{err=}")
        return Response(status=HTTPStatus.UNAUTHORIZED)

    if data["payload"] is not None and "tenant" in data["payload"]:
        client = ContainerPlatformClient(
            username=data["username"],
            password=data["password"],
            api_host=url.hostname,
            api_port=int(url.port or 8080),
            use_ssl=url.scheme == "https",
            verify_ssl=False,
            tenant=data["payload"]["tenant"]["_links"]["self"]["href"],
        )
    else:
        client = ContainerPlatformClient(
            username=data["username"],
            password=data["password"],
            api_host=url.hostname,
            api_port=int(url.port or 8080),
            use_ssl=url.scheme == "https",
            verify_ssl=False,
        )

    if request.method == "POST":
        try:
            if op == "test":
                client.create_session()  # Login
                res = "Success!"
                return jsonify(res)
            elif op == "connect":
                client.create_session()  # Login
                return jsonify(client.config.get())
            elif op == "list":
                client.create_session()  # Login
                # try: # get cluster list if user has access
                #   clusters = { "clusters" : [({ "id": x.id, "name": x.name, "description": x.description, "k8s_version": x.k8s_version, "status": x.status}) for x in client.k8s_cluster.list()] }
                # except Exception:
                #   clusters = { "clusters" : [] }
                # query details for each tenant
                tenants = {
                    "tenants": [
                        y.json
                        for y in [
                            client.tenant.get(t)
                            for t in [x.id for x in client.tenant.list()]
                        ]
                    ]
                }
                # or get simple information about tenants
                # tenants = { "tenants" : [({ "id": x.id, "name": x.name, "description": x.description,"status": x.status, "tenant_type": x.tenant_type }) for x in client.tenant.get("/api/v1/tenant/")] }
                return jsonify(tenants)
                # return jsonify({**clusters, **tenants})
            # elif op == "tenants":
            #   client.create_session() # Login
            #   return jsonify([({ "id": x.id, "name": x.name, "description": x.description,"status": x.status, "tenant_type": x.tenant_type }) for x in client.tenant.list()])
            elif op == "apply" or op == "delete":
                tenant = data["payload"]["tenant"]
                app = data["payload"]["app"]
                client.create_session()  # Login

                # TODO: ensure mlops enabled and datatap/tenantstorage configured in the tenant etc

                if (
                    not tenant["features"]["ml_project"]
                    or not tenant["state"] == "ready"
                ):
                    return jsonify("Tenant not ready")

                # get replacement parameters
                # t_id = client.tenant_config
                ns = tenant["namespace"]
                kubeconfig = get_base64_string(client.tenant.k8skubeconfig())
                userid_href = [
                    id
                    for id in [users.json for users in client.user.list()]
                    if id["label"]["name"] == data["username"]
                ][0]["_links"]["self"]["href"]
                userid = userid_href.split("/")[-1]
                userhash = hashlib.md5(
                    (userid + "-" + data["username"]).encode("utf-8")
                ).hexdigest()
                kcsecret = "hpecp-kc-secret-" + userhash
                client_config = client.config.get()
                storageclass = client_config["objects"]["tenant_storage_root"][
                    "endpoint"
                ]["cluster_name"]

                # Replacements
                repls = (
                    ("TENANTNS", ns),
                    ("KUBECONFIG", kubeconfig),
                    ("USERNAME", data["username"]),
                    ("USERID", userid),
                    ("STORAGECLASS", "CHANGEME"),
                    ("KCSECRET", kcsecret),
                    ("NOTEBOOK_CLUSTER", "eznotebook"),
                    ("TRAINING_CLUSTER", "eztraining"),
                    ("MLFLOW_CLUSTER", "ezmlflow"),
                    ("MLFLOW_ADMIN_USER", get_base64_string(data["username"])),
                    ("MLFLOW_ADMIN_PASSWORD", get_base64_string(data["password"])),
                    ("STORAGECLASS", storageclass),
                )

                result = ""
                for file in app["deploy"]:
                    loaded_yaml = ""
                    with open(
                        os.path.join(base_path, "yaml", file["yaml"]), "r"
                    ) as stream:
                        for line in stream:
                            loaded_yaml += line
                    try:
                        # update yaml files
                        cleaned_yaml = reduce(
                            lambda a, kv: a.replace(*kv), repls, loaded_yaml
                        )
                        # submit the file and save the result
                        result += client.k8s_cluster.run_kubectl_command(
                            tenant["k8s_cluster"], op, get_base64_string(cleaned_yaml)
                        )
                    except BaseException as err:
                        print(f"{err=}")
                        return jsonify(err.message), HTTPStatus.NOT_ACCEPTABLE

                # Return all submission results
                return jsonify(result)

        except Exception as err:
            print(f"{err=}")
            return Response(format(err), status=HTTPStatus.UNAUTHORIZED)

        return Response(status=HTTPStatus.NOT_IMPLEMENTED)

    if request.method == "DELETE":
        return Response(status=HTTPStatus.OK)


if __name__ == "__main__":
    if "DEV" in os.environ:
        app.run(host="0.0.0.0", debug=True, port=4001)
    else:
        serve(app, host="0.0.0.0", port=4000)
