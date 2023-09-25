# kubernetes-vagrant
Kubernetes From Scratch using vagrant

---
## Cluster Details
* Kubernetes Version : 1.28.1
* etcd : 3.5.9
* CNI Plugin : 1.3.0

---
## Current State.
Now This code can create 1 master with 3 workers. ( ~~Although workers cannot accept load just yet. But thats next step.~~)
* Update1 - CNI working now. End to End test pending.


---
## USE

```bash
git clone https://github.com/devidasjadhav/kubernetes-vagrant
cd kubernetes-vagrant
./scripts/setup
```

---
## Requirements

To use this there are following requirements.
1. Linux ( I haven't yet tested this on any other platform).
2. [VirtualBox](https://www.virtualbox.org)
3. [Vagrant](https://www.vagrantup.com)

---
## Details

|  Node | IP | OS | 
|---|---|---|
| kubemaster | 192.168.199.10 | Debian 12 |
| worker0 | 192.168.199.20 | Debian 12 |
| worker1 | 192.168.199.21 | Debian 12 |
| worker2 | 192.168.199.22 | Debian 12 |

---
## Note

* I am getting started in this field. Please consider raising PR to correct, improve.
* Please consider creating issue. If you have any issue to report. Do share steps, logs and setup details.
