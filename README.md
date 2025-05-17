# Porkbun DNS Updater
A simple Bash script to keep Porkbun DNS A-record in sync with home/cluster's changing public IP. Running locally can be done with a `.env` file, build & run it in docker, or pulling the prebuilt image from Docker Hub.

## Features
- Fetches your current WAN IP (`api.ipify.org`)
- Retrieves your Porkbun A record via the Porkbun API
- Updates the record only if the IP has changed.
- Configurable via environment variables or a `.env` file
- Distributed as a tiny Alpine-based Docker image (multi-arch ready)

## Prerequisites
- **Bash**, **curl**, **jp** (if running the script directly)
- Docker (if building or running the container)
- A Porkbun API key & secret (generate in your **Porkbun Dashboard**)

## Configuration 
Create a file named `.env` alongside the script with the following entries:
```ini
PORKBUN_API_KEY=sk1_yourapikey
PORKBUN_API_SECRET=sk1_yoursecretkey
DOMAIN=yourdomain.tld
SUBDOMAIN=              # leave empty for the root record, or e.g., "www"
TTL=300                 # record TTL in seconds
```
> **Or** export these variables directly in your shell:
> ``` bash
> export PORKBUN_API_KEY=sk1_yourapikey
> export PORKBUN_API_SECRET=sk1_yoursecretkey
> export DOMAIN=yourdomain.tld
> export SUBDOMAIN=""   # or "www"
> export TTL=300
> ```

## Usage
### 1. Running the script locally 
```bash
# Ensure .env exists or env vars are set 
./porkbun-dns-updater-new.sh
```
You should see output like: 
```bash
-> Payload: {"apiKey":"...","secretapikey":"..."}
No changeL still 1.2.3.4
```
or, if your IP changed
```bash
IP changed: 1.2.3.4 -> 5.6.7.8, updating...
Update successful
```

### 2. Building the Docker image manually
```bash
# From this folder (where the Dockerfile lives):
docker build -t youruser/porkbun-ddns:latest .
```
Then run it:
```bash
docker run --rm --env-file .env youruser/porkbun-ddns:latest
```

### 3. Pulling the image from DockerHub
```bash
docker pull cyrof/porkbun-ddns:latest 
docker run --rm --env-file .env cyrof/porkbun-ddns:latest
```

## Kubernetes / k3s CronJob
If you want to automate it on a k3s (or any Kubernetes) cluster, use a simple CronJob:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
    name: porkbun-ddns
    namespace: porkbun-ddns
spec:
    schedule: "0 7 * * *"       # every day at 07:00
    successfulJobsHistoryLimit: 10
    failedJobsHistoryLimit: 5
    jobTemplate:
        spec:
            ttlSecondsAfterFinished: 604800     # keep jobs for 7 days
            template:
                spec:
                    restartPoly: OnFailure
                    containers:
                        - name: ddns-updater
                          image: cyrof/porkbun-ddns:latest
                          imagePullPolicy: IfNotPresent
                          envFrom:
                            - secretRef:
                                    name: porkbun-creds
```

## Contributing
Contributions, issues and feature requests are welcome! Feel free to:
- Fork the repository 
- Open a pull request with your changes
- Submit issues for bugs or enhancement ideas

## License
This project is licensed under the [Apache 2.0](https://github.com/Cyrof/Porkbun-dns/blob/main/LICENSE) License.
