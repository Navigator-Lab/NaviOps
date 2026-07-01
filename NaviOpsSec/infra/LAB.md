# NaviOpsSec — offline SIEM lab (quick start)

A real **Wazuh** single-node SIEM (manager + indexer + dashboard) + a **victim** target to attack and
detect on. This is what Lessons 14–20 (deploy, rules, triage) are meant to be *done* on, not just read.

> ⚠️ **Heavy:** needs ~**4 GB free RAM** and `vm.max_map_count=262144`. Runs offline after one image pull.
> Sanitized only — no real agent/cluster keys, IPs, or hostnames committed (Hard Rule #1).

## First-time setup (once)
```bash
./infra/bootstrap.sh sysctl    # set vm.max_map_count (sudo, resets on reboot)
./infra/bootstrap.sh pull      # fetch images (internet once)
./infra/bootstrap.sh certs     # generate SSL certs -> lab/config/wazuh_indexer_ssl_certs/
./infra/bootstrap.sh up        # start the SIEM
```
Open **https://localhost:8443** → `admin` / `SecretPassword` (change it immediately). The indexer takes
1–2 minutes to go green.

## Enroll the victim agent (Lesson 14)
```bash
docker exec -it siem-victim bash
# inside the victim: install + point the agent at the manager
curl -so wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb
WAZUH_MANAGER='wazuh.manager' dpkg -i ./wazuh-agent.deb
/var/ossec/bin/wazuh-control start
```
The agent appears under **Agents** in the dashboard.

## Generate detections to triage (Lessons 18–20)
```bash
# from the host, brute-force the victim's sshd to trigger the brute-force rule:
for i in $(seq 1 10); do sshpass -p wrong ssh -o StrictHostKeyChecking=no root@localhost -p 2222 true; done
```
Then in the dashboard: **Threat Hunting / Security Alerts** → find the failed-login + brute-force alerts →
practice the triage workflow (true/false positive, severity, escalate/close) from Lesson 17.

## Test custom rules without waiting for an event
```bash
docker exec -it wazuh.manager /var/ossec/bin/wazuh-logtest
# paste a sample log line; see which decoder + rule (from infra/wazuh/local_rules.xml) fire
```

## Wire your detection content in
The sanitized `infra/wazuh/` (local_rules.xml, local_decoders.xml, fim.conf, active-response.conf) is the
version-controlled detection content — mount/copy it into `wazuh.manager:/var/ossec/etc/` and reload.

## Guardrails
Active response (auto-block) is a **Danger Zone** — lab-only, console fallback. Change the default password.
Never commit real keys/IPs/hostnames or raw captures.
