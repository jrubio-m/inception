# DEV_DOC.md

## Environment Setup

This section explains how to set up the project from scratch, starting from a clean system.

The project is developed and tested inside a virtual machine to ensure isolation and reproducibility.

---

* ### _Virtual Machine Setup_

The first step is to create a virtual machine where the entire project will run.

A minimal installation of Lubuntu is used to reduce resource consumption and keep the environment clean.

Steps:

- Download Lubuntu Minimal ISO from the official website
- Create a new virtual machine using VirtualBox (or similar)
- Allocate resources:
  - RAM: at least 2GB (recommended 4GB)
  - CPU: 2 cores
  - Disk: at least 20GB (dynamic allocation is fine)
- Mount the Lubuntu ISO as boot device
- Start the VM and follow the installation process
- Select minimal installation when prompted

After installation:

- Update the system:
```bash
sudo apt update && sudo apt upgrade -y
```
---

* ### _Base System Preparation_

After installing the operating system, the system must be prepared with essential development tools and utilities required for building and managing the project.

Install the following packages:
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
These packages are required for:

- `build-essential`: compiling software if needed
- `curl` / `wget`: downloading external resources
- `git`: version control
- `vim`: file editing inside the VM
- `ca-certificates` and `gnupg`: required for secure package installation (important for Docker)
- `lsb-release`: helps identify the system version for repository setup

Keeping the system minimal avoids unnecessary overhead and improves performance inside the virtual machine.

---

* ### _SSH Installation (Optional)_

Install ssh:
```bash
sudo apt update 
sudo apt install -y ssh
```

Start and enable ssh service:
```bash
systemctl start ssh
systemctl enable ssh
```

Allow ssh in ufw:
```bash
sudo ufw allow
```

---

* ### _Docker Installation_

Docker must be installed using the official Docker repository to ensure up-to-date and secure packages.

Add Docker’s official GPG key:
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

Set up the Docker repository:
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Update package index:
```bash
sudo apt update
```

Install Docker and related tools:
```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

---

* ### _Docker Service Configuration_

* Starts Docker service immediately
* Enables Docker to start automatically on system boot

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

---

* ### _Docker Permissions Setup_

By default, Docker requires root privileges to run commands.

To avoid using `sudo` every time, add your user to the `docker` group:
```bash
sudo usermod -aG docker $USER
```

After this, you must log out and log back in (or reboot) for the changes to take effect.

To verify that Docker works without sudo:
```bash
docker run hello-world
```

A full logout/login is required for this change to take effect.

---
### `⚠️ Security Note: `

_Adding a user to the docker group effectively grants root-level privileges._

_This is because Docker can control the host system through containers._

_This setup is acceptable in a local development environment (such as this project), but should be carefully considered in production systems._

---

## Docker Compose Setup

Docker Compose is required to define and manage multi-container applications.

It is installed together with Docker as a plugin.

To verify that Docker Compose is available:
```bash
docker compose version
```

## Project Structure Initialization

The project must follow a strict structure.

Create the base directories:
```bash
mkdir -p ~/inception/srcs/requirements
mkdir -p ~/inception/secrets
```

Navigate into the project directory:
```bash
cd ~/inception
```
