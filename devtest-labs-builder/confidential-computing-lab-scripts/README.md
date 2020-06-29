# Confidential Computing (CC) Hands-On Lab (HOL) Builder

This folder is intended to be used as a quick way to build a complete DevTest Lab environment about Confidential Computing.

This automation script will deploy on Azure one Windows Server 2019 Datacenter virtual machine (VM), and two Ubuntu Server 18.04 virtual machines (VMs), using for the latter an SSH key to connect.

Please refer to the Please refer to the [Hands-On Labs Deployment Instructions](https://github.com/microsoft/data-in-use-protection-compass/blob/master/hands-on-labs/Hands-on%20labs%20-%20%20Deployment%20instructions.pdf) for more information.

## Quick start

The whole deployment configuration is available in config.ps1. Please note that you must have a SSH key pair created to deploy the DevTest Lab in Azure. 

First, fill out all the configuration variables in **config.sh**. Values delimited with "<>" are placeholders and must be changed.

### Using Docker

```sh
    #Build the container
    docker build -t labcc .
    # Connect to the container (replace \ by ` on windows)
    docker run -it \
        # Share config file with the container
        -v $PWD/config.ps1:/app/config.ps1 \
        # Share ssh keys (This is the default location for keys, adapt to your own needs)
        -v $HOME/.ssh:/root/.ssh \
        labcc 
    # Log into Azure
    az login
    # Deploy the lab !
    ./deploy.ps1
    
```

### Native execution

```sh
    # Be sure to have the Azure-cli installed beforehand
    # Windows
    ./deploy.ps1
    # Linux
    ./deploy.ps1
```

## Project structure

```sh
├───ARM-generated-templates
├───ARM-parameters
├───ARM-templates
├───json
├───config.ps1
└───deploy.ps1
```

Files in **ARM-templates** are specifications of VMs' types, for the sake of this hands-on lab, one Windows Server 2019 Datacenter VM and two Ubuntu Server 18.04 VMs as indicated above. These are purely generic templates that can be reused by any project, as deployment-bound values aren't specified here.

Files in **ARM-parameters** contains most of these deployment-bound values, except for a few value, indicated by [[value_name]]. These are left for the user to modify and will be added to the template at runtime.

At runtime, values in `config.ps1` are used to generate files in **ARM-generated-templates**, which are then used to deploy the actual VM.

**json** directory contains the JSON descriptions files for this hands-on lab VMs.