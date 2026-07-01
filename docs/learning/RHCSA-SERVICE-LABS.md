# RHCSA Service Labs — hands-on NFS / Apache / BIND / SELinux / firewalld

The exam is **practical**: you're dropped at a shell and told to *make services work and survive a reboot*.
These labs run on the offline lab nodes (`naviops-web` 172.28.0.10, `naviops-db` 172.28.0.11). Do them
until you can from memory. Ties to Lesson 27 (RHCSA prep). *(The base image is Ubuntu; where a step is
RHEL-specific — `dnf`, `firewalld`, `semanage` — the RHEL command is given so it maps 1:1 to the exam.)*

> Start: `./infra/bootstrap.sh up` → `docker exec -it naviops-web bash`. On RHEL swap `apt` for `dnf`.

## Rule 0 — "survive a reboot" (the #1 RHCSA failure)
Every service you configure: **`systemctl enable --now <svc>`** and every mount: **add to `/etc/fstab`**.
A task that works now but not after reboot scores **zero**. Verify with `systemctl is-enabled` and
`mount -a` (no errors).

## Lab 1 — Apache/Nginx virtual host
```bash
dnf install -y httpd            # (apt install -y apache2)
systemctl enable --now httpd
echo "NaviOps web node" > /var/www/html/index.html
firewall-cmd --permanent --add-service=http && firewall-cmd --reload   # RHEL
curl http://localhost                                                   # expect the page
```
**Break/fix drill:** `chmod 000 /var/www/html/index.html` → curl gives 403 → fix perms → 200.

## Lab 2 — NFS export (server on db, client on web)
```bash
# on naviops-db (server):
dnf install -y nfs-utils && systemctl enable --now nfs-server
mkdir -p /srv/share && chmod 0777 /srv/share && echo "shared" > /srv/share/hello
echo "/srv/share 172.28.0.0/24(rw,sync)" >> /etc/exports && exportfs -rav
# on naviops-web (client):
mkdir -p /mnt/share && mount -t nfs 172.28.0.11:/srv/share /mnt/share
cat /mnt/share/hello                                   # expect: shared
echo "172.28.0.11:/srv/share /mnt/share nfs defaults 0 0" >> /etc/fstab   # survive reboot
```

## Lab 3 — BIND / local DNS
```bash
dnf install -y bind bind-utils   # (apt install -y bind9 dnsutils)
# add a forward zone naviops.lab mapping web->.10, db->.11 in /etc/named.conf + zone file
systemctl enable --now named
dig @localhost web.naviops.lab +short     # expect 172.28.0.10
```
**Break/fix drill:** introduce a syntax error → `named-checkconf` / `named-checkzone` to find it.

## Lab 4 — SELinux troubleshooting (RHEL exam favourite)
```bash
getenforce                                  # Enforcing
# Move web content to a non-standard dir -> SELinux denies httpd reading it:
mkdir /web && echo hi > /web/index.html
semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?" && restorecon -Rv /web
setsebool -P httpd_can_network_connect on   # common "why can't my app connect" fix
ausearch -m avc -ts recent                  # read the denials like an analyst
```
**Mental model:** if a service works with SELinux `Permissive` but fails `Enforcing`, it's a **label or
boolean** problem — not a permissions or firewall problem. Fix the context, don't disable SELinux.

## Lab 5 — firewalld zones & rules
```bash
firewall-cmd --get-active-zones
firewall-cmd --permanent --add-port=8080/tcp && firewall-cmd --reload
firewall-cmd --list-all                      # confirm the port is listed
```
Audit any node fast with the repo tool: `./scripts/firewall_audit.sh`.

## Lab 6 — users, sudo, storage (round it out)
```bash
useradd -m -s /bin/bash navi && echo 'navi:Passw0rd!' | chpasswd
usermod -aG wheel navi                       # sudo group (RHEL 'wheel', Debian 'sudo')
# LVM: create PV/VG/LV on a spare loop device, mkfs, mount, add to fstab, then grow it:
lvextend -r -L +200M /dev/vg/lv              # -r resizes the fs too
```

## Self-test (can you, from memory, in < 15 min each?)
- [ ] Stand up Apache with a custom docroot that survives reboot + SELinux.
- [ ] Export NFS from db, mount persistently on web.
- [ ] Resolve a name via your own BIND zone.
- [ ] Diagnose an SELinux AVC denial and fix it with `semanage`/`restorecon` (not by disabling SELinux).
- [ ] Open a port in firewalld permanently and prove it.
- [ ] Grow an LVM filesystem online.

> Every lab here is Artifact-Contract material: capture the config + a break/fix drill + a NAVI ticket
> ("web returns 403 after content move" → SELinux label → `restorecon` → root cause).
