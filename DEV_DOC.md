# DEV_DOC.md

## Development Environment Setup

### Overview

The goal of this step is to prepare a clean and stable development environment for the Inception project using a virtual machine based on Lubuntu (Ubuntu LTS). This ensures reproducibility and avoids inconsistencies caused by customized systems.

---

## Why a Virtual Machine?

A virtual machine is used to:

* Ensure a clean and controlled environment
* Avoid conflicts with the host system (e.g., Kali Linux)
* Reproduce the same setup used during evaluation
* Isolate dependencies and configurations

---

## Operating System Choice

We use **Lubuntu LTS**, which is based on Ubuntu LTS.

### Reasons:

* Lightweight (ideal for virtual machines)
* Stable and widely supported
* Compatible with Docker official repositories
* Minimal resource consumption

---

## System Update

```bash
sudo apt update
sudo apt upgrade -y
```

### Purpose

* Refresh package lists (`apt update`)
* Upgrade installed packages to latest versions (`apt upgrade`)
* Prevent dependency issues and outdated software

---

## Required Base Packages

```bash
sudo apt install -y \
    build-essential \
    curl \
    wget \
    git \
    vim \
    ca-certificates \
    gnupg \
    lsb-release
```

### Purpose of each package

* `build-essential`: Provides compilers and build tools (gcc, make)
* `curl` / `wget`: Download files from the internet
* `git`: Version control system
* `vim`: Text editor for configuration files
* `ca-certificates`: Enables secure HTTPS communication
* `gnupg`: Used for verifying package signatures
* `lsb-release`: Provides distribution information

---

## Docker Installation

### 6.1 Add Docker GPG Key

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

### Purpose

* Adds Docker’s official GPG key
* Ensures downloaded packages are authentic and not tampered with

---

### Add Docker Repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Purpose

* Adds Docker’s official repository to the system
* Allows installation of up-to-date Docker versions

---

### Install Docker Engine

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Components Installed

* `docker-ce`: Docker Engine
* `docker-ce-cli`: Docker command-line interface
* `containerd.io`: Container runtime
* `docker-buildx-plugin`: Advanced build features
* `docker-compose-plugin`: Enables `docker compose`

---

## Docker Service Configuration

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Purpose

* Starts Docker service immediately
* Enables Docker to start automatically on system boot

---

## User Permissions

```bash
sudo usermod -aG docker $USER
```

### Purpose

* Adds the current user to the `docker` group
* Allows running Docker commands without `sudo`

⚠️ Important:
A full logout/login is required for this change to take effect.
