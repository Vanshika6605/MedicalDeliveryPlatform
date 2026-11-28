# MediFlow web deployment with Ansible

MediFlow represents a medical delivery platform for customers, pharmacy retailers, and delivery agents. This lab deploys its existing React frontend to Nginx on one Ubuntu WSL instance. The Ubuntu instance is both the control node and the managed node. The inventory uses Ansible's local connection and the managed service listens on loopback port 8094.

## Prepare and build

Use Node.js 22.12+ or 24, and Ubuntu with systemd and Python 3.12+ as the control environment. From the repository root, install the locked dependencies, run the existing backend authentication unit tests, and build the frontend with a same-origin API path.

```bash
npm ci
npm --prefix backend ci
npm test
VITE_API_URL=/api npm run build
```

If building in Windows PowerShell, use `$env:VITE_API_URL = '/api'; npm.cmd run build`. Ubuntu WSL can access the same checkout through `/mnt/c/`. For a fresh WSL installation, confirm systemd is running with `ps -p 1 -o comm=`.

## Validate and deploy

From the repository root in Ubuntu, use a user with sudo privileges. Install the Python virtual environment package once if required.

```bash
sudo apt-get update
sudo apt-get install -y python3-venv
python3 -m venv ~/.venvs/mediflow-ansible
source ~/.venvs/mediflow-ansible/bin/activate
python -m pip install -r deploy/ansible/requirements.txt
cd deploy/ansible
ansible-inventory -i inventory.ini --graph
ansible-playbook -i inventory.ini site.yml --syntax-check
ansible -i inventory.ini mediflow_web -m ansible.builtin.ping
ansible-playbook -i inventory.ini site.yml --ask-become-pass
ansible-playbook -i inventory.ini site.yml --ask-become-pass
```

The first run installs Nginx, publishes the Vite build, validates the Nginx configuration, and enables the dedicated systemd unit. The next run with the same files should report `changed=0`. In an existing privileged shell, omit `--ask-become-pass`.

## Verify and monitor

```bash
systemctl is-active mediflow-web
systemctl is-enabled mediflow-web
curl -i http://127.0.0.1:8094/health
curl -I http://127.0.0.1:8094/login
curl -i http://127.0.0.1:8094/api/health
sudo journalctl -u mediflow-web -n 20 --no-pager
sudo tail -n 20 /var/log/nginx/mediflow-access.log
```

Open `http://127.0.0.1:8094/home` for the homepage and `http://127.0.0.1:8094/login` to verify SPA routing. The Nginx health endpoint should return HTTP 200 with service name `mediflow-web`. The lab returns HTTP 503 for API and Socket.IO requests. Live authentication, orders, tracking, and PostgreSQL belong to the full-stack application and are outside this web-tier deployment. The backend unit tests are a source-level check.

To stop the lab and disable automatic startup, run `sudo systemctl disable --now mediflow-web`.

## Assessment evidence

- [Execution output and screenshots](evidence/)
- [Recorded demonstration (MP4)](demo/mediflow-ansible-demo.mp4)

The terminal images contain excerpts from the adjacent raw transcripts. The browser screenshots were captured from the running local service.
