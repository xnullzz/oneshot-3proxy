# Oneshot-3proxy

Just a simple set of scripts that create a container with 3proxy running and temporary credentials

## Installation

To use this script, follow these steps:

1.  Clone this repository:

```bash
git clone https://github.com/xnullzz/oneshot-3proxy.git && cd oneshot-3proxy
```

2. Build the Docker image:

```bash
docker build -t 3proxy .
```

## Usage

1. Generating the 3proxy Container

To create the 3proxy container with random credentials, run the oneshot-3proxy.sh script:

```bash
sh oneshot-3proxy.sh
```

This script will output the temporary credentials (username and password) required to access the proxy server. Please note that these credentials will only be valid until the Docker container is stopped.

2. Cleaning Up

To stop and remove the created container, use the cleanup.sh script (it also removes configuration files e.g. 3proxy.cfg):

```bash
sh cleanup.sh
```

This script will read the container ID from the .env file and stop and remove the container associated with that ID
.

## Generating pretty html output for your webserver

`update.py` will generate html file that can be served by reverse-proxy like nginx or apache. When you add/remove users or fully upgrading configuration it will be enough to run

```bash
python3 update.py -o /var/www/html/index.html
```

The `-o` argument is path to your html location. 

The `-h` argument can be used to check other available customization options. 
