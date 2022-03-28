# Guide to Contribute

## High Level Design

This utility is divided into two main segments, **server** piece providing all the business logic and scripts (execution), and the **client** piece providing the interactive web UI.

### Server Component

Provides multi-stage operation to standardized deployment across different platforms/targets.
Stage 1: Initilization, setting up the requirements, checking params etc
Stage 2: Deploying the infrastructure that will support the Ezmeral installation at Stage 3
Stage 3: Installation of Ezmeral components (Runtime, Data Fabric on K8s / Standalone Data Fabric...)
Stage 4: Configuration of demos, including setting up K8s clusters, MLOps components and DF/Picasso registration etc

Stage 99: Is provided as the means to destroy the environment (to avoid cloud costs or clean up / fresh start).
Stop/Start/Refresh scripts are also available but not heavily tested.

Stage 1 & Stage 2 differs for each and every target platform, but Stage 3 and Stage 4 should be identical to any target. It is important to have this consistency to avoid duplicate scripting and/or branching of process.

Terraform is used to create infrastructure resources (better aligned with cloud providers), so used for Stage 1 and Stage 2.

Ansible is used to configure the operating system and applications, including the Ezmeral components, so it is used for Stage 3 and Stage 4.

Dummy processing is possible for Stage 1 and Stage 2. A .tf file to trigger a shell script and provide the expected output for later stages (used by refresh_files.sh in the beginning of Stage 3).

```terraform
resource "shell_script" "myshellscript" {
  
  count = 5
  lifecycle_commands {
    create = file("./create-vm.sh")
    delete = file("./delete-vm.sh")
  }

  interpreter = ["/bin/bash", "-c"]

  environment = {
    NAME        = local.NAMES[count.index]
    CPU         = local.CPUS[count.index]
    MEM         = local.MEMS[count.index]
  }
}
```

### User Interface

Web-based UI uses basic [Python](https://www.python.org)/[Flask](https://flask.palletsprojects.com/en/2.0.x/) framework (though flask capabilities are widely not utilized, yet).

User interface is written with [Grommet](https://v2.grommet.io) with [HPE Theme](https://github.com/grommet/grommet-theme-hpe), and [React](https://reactjs.org).

Port 4000 is exposed for both static pages (using javascript) and API (server) portion. API calls are designed to provide flexibility and extensibility.

#### TODO: Describe Functions and Flows

- the UI component

  - config.json keys with "is_???" is handled manually/specially

- the server/API component

## Providers / Targets

Each deployment target is a provider, such as AWS, Azure etc.

Even though this is designed to be packaged and deployed as a Linux container, it is possible to run this on any Linux and MacOS machine (including WSL and Multipass/Lima). ~~Some providers are only possible on certain operating systems (since no remote deployment is supported for those), such as, to use "mac" as target you should be running this on a MacOS machine. Similarly to use "kvm" target you need to use a Linux machine (and not the container image).~~ Container image is provided for convenience, as you would need to manually install required tools/utilities (such as awscli, jq, ansible etc).

### Add New Target

- Create a folder under "server", and add your provider/target name in ./server/providers file (case sensitive).
***TODO: main.py for WebUI still has providers hardcoded, should be manually adjusted to return the provider name, as well as to allow files to be downloaded in its folder***

- Create ./config.json-template under your target folder. This file should list all required parameters for user settings (in json format).

- Provide an optional ./init.sh that will be hooked in the init phase (01-init.sh). This is used to hook into provided options. For example, you can create your own terraform.tfvars file from ./config.json.

- Provide main.tf (and optionally a variables.tf) for stage2 (terraform apply). If your deployment doesn't use terraform, you can create a null_resource and run your own script to deploy resources. See main.tf and variables.tf under ./mac folder as an example. Your script should return json object to ensure "create" phase is completed successfully. If you are not returning json object as the last thing on stdout, terraform apply will fail with timeout.

- Your terraform run should generate outputs as highlighted under ./mac/main.tf file. These outputs will be used by Ansible scripts in stage3 (install) and stage4 (configure).

- Your delete script should clean up the created resources as part of stage 99 (destroy).

### Customizing Existing Targets

Top level system.settings file: used for options not exposed to users, read by outputs.sh, and provides inputs to "terraform and ansible"

Provider specific config.json file: used for user selection, such as deploy with HA, or provider specific settings, such as access key.
