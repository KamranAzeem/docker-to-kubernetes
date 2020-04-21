# Deploying applications locally on minikube:
If you are a developer (or even a system administrator), and you want to experiment with [Kubernetes](https://kubernetes.io), then [minikube](https://github.com/kubernetes/minikube) is something you should really look into. It is a simple single-node kubernetes cluster, which installs easy on your work computer - as a small virtual machine. It is open-source, and is free of cost. It is especially useful, when you want to learn / work with Kubernetes, but can't afford to run even a small Kubernetes cluster in a cloud environment, such as GCP, etc. 

The emphasis is on having minikube *running as a VM*, (not as a process on docker), because this takes away all the possible complexity away from your local computer. It (minikube VM) makes setting up and running the kubernetes cluster very easy. 

## What do you need to get it to work?
You need decently powered computer, with following specs:
* CPUs with hardware virtualization (Intel VT or AMD-V). Normally Intel's i3, i5, i7 (and now i9), and AMD's FX 63xx, 83xx, 9xxx, A10, A8, etc  are a good choices. 
* Minimum 4 GB RAM is good enough if you want to run Linux. Minikube takes 2 GB RAM from host computer, and assigns it to the minikube VM. If you are using Windows, then you need more, because windows is basically bloatware, and it just abuses RAM. 
* At least 20 GB free disk-space on your host OS, because minikube will create a 20 GB virtual disk. You can increase the size of the virtual disk at the time of minikube setup.
* A Hypervisor running on the computer, such as KVM. I don't recommend VirtualBox, or HyperV, or anything else. However, if you are on Windows or Mac, then you have no choice but to use one of these.
* Chromebooks will not work.

## Install and Setup Minikube on your local computer:
Lets install minikube on our system. The computer I am using is an Intel i7, 16 GB RAM, runs Fedora Linux 31, and runs KVM as Hypervisor. Just so you know, KVM is world's strongest, most efficient and most lightweight Hypervisor. It runs directly inside the Linux kernel - as a loadable kernel module. RedHat (world's largest open source company) uses KVM in the heart of it's **RedHat Enterprise Virtualization** product. AWS (the biggest cloud provider) is also moving it's infrastructure from XEN to KVM.

**Note:** This document was written for a computer, which has Fedora Linux as Host OS and KVM as Hypervisor. If you have a different OS or Hypervisor on your computer, then you need to consult a different guide for installing minikube on your computer.
 
### Prerequisites:
Besides OS and Hypervisor, you also need some additional software.

If you installed Google-Cloud-SDK on your computer, then you should know that it provides lots of packages, such as `kubectl`, *as well as* `minikube`! You can install these using gcloud commands:
```
gcloud components list

gcloud components install COMPONENT_ID
```

In case you installed google-cloud-sdk YUM repository, then installing these packages is as simple as `yum install <package-name>` 

```
[root@kworkhorse ~]# yum --disablerepo="*" --enablerepo="google-cloud-sdk" list available
Last metadata expiration check: 1:16:01 ago on Thu 16 Apr 2020 09:29:37 PM CEST.
Available Packages
google-cloud-sdk.noarch                                                        289.0.0-1            google-cloud-sdk
google-cloud-sdk-anthos-auth.x86_64                                            289.0.0-1            google-cloud-sdk
google-cloud-sdk-app-engine-go.x86_64                                          289.0.0-1            google-cloud-sdk
google-cloud-sdk-app-engine-grpc.x86_64                                        289.0.0-1            google-cloud-sdk
google-cloud-sdk-app-engine-java.noarch                                        289.0.0-1            google-cloud-sdk
google-cloud-sdk-app-engine-python.noarch                                      289.0.0-1            google-cloud-sdk
google-cloud-sdk-app-engine-python-extras.noarch                               289.0.0-1            google-cloud-sdk
google-cloud-sdk-bigtable-emulator.x86_64                                      289.0.0-1            google-cloud-sdk
google-cloud-sdk-cbt.x86_64                                                    289.0.0-1            google-cloud-sdk
google-cloud-sdk-cloud-build-local.x86_64                                      289.0.0-1            google-cloud-sdk
google-cloud-sdk-datalab.noarch                                                289.0.0-1            google-cloud-sdk
google-cloud-sdk-datastore-emulator.noarch                                     289.0.0-1            google-cloud-sdk
google-cloud-sdk-firestore-emulator.noarch                                     289.0.0-1            google-cloud-sdk
google-cloud-sdk-kind.x86_64                                                   289.0.0-1            google-cloud-sdk
google-cloud-sdk-kpt.x86_64                                                    289.0.0-1            google-cloud-sdk
google-cloud-sdk-minikube.x86_64                                               289.0.0-1            google-cloud-sdk                           
google-cloud-sdk-pubsub-emulator.noarch                                        289.0.0-1            google-cloud-sdk
google-cloud-sdk-skaffold.x86_64                                               289.0.0-1            google-cloud-sdk
google-cloud-sdk-spanner-emulator.x86_64                                       289.0.0-1            google-cloud-sdk
google-cloud-sdk-tests.noarch                                                  289.0.0-1            google-cloud-sdk
kubectl.x86_64                                                                 1.18.1-0             google-cloud-sdk
[root@kworkhorse ~]# 
```

```
[root@kworkhorse ~]# yum search minikube
Last metadata expiration check: 0:39:56 ago on Thu 16 Apr 2020 09:29:40 PM CEST.
===================== Name Matched: minikube ======================
google-cloud-sdk-minikube.x86_64 : Google Cloud SDK
[root@kworkhorse ~]# 
``` 

### Install the minikube package:
``` 
[root@kworkhorse ~]# yum -y install google-cloud-sdk-minikube.x86_64
Last metadata expiration check: 0:41:25 ago on Thu 16 Apr 2020 09:29:40 PM CEST.
Dependencies resolved.
===================================================================
 Package                   Arch   Version   Repository        Size
===================================================================
Installing:
 google-cloud-sdk-minikube x86_64 289.0.0-1 google-cloud-sdk  13 M

Transaction Summary
===================================================================
Install  1 Package

Total download size: 13 M
Installed size: 43 M
Downloading Packages:
02311b8ff662232b90e0df30503bba809f 3.2 MB/s |  13 MB     00:04    
-------------------------------------------------------------------
Total                              3.2 MB/s |  13 MB     00:04     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                           1/1 
  Installing       : google-cloud-sdk-minikube-289.0.0-1.x86   1/1 
  Running scriptlet: google-cloud-sdk-minikube-289.0.0-1.x86   1/1 
  Verifying        : google-cloud-sdk-minikube-289.0.0-1.x86   1/1 

Installed:
  google-cloud-sdk-minikube-289.0.0-1.x86_64                       

Complete!
[root@kworkhorse ~]#
``` 


### Setup minikube VM:
```
[kamran@kworkhorse ~]$ minikube start --driver=kvm2
😄  minikube v1.9.2 on Fedora 31
    ▪ KUBECONFIG=/home/kamran/.kube/config:/home/kamran/.kube/kubeadm-cluster.conf
✨  Using the kvm2 driver based on user configuration
💾  Downloading driver docker-machine-driver-kvm2:
    > docker-machine-driver-kvm2.sha256: 65 B / 65 B [-------] 100.00% ? p/s 0s
    > docker-machine-driver-kvm2: 13.88 MiB / 13.88 MiB  100.00% 2.46 MiB p/s 5
💿  Downloading VM boot image ...
    > minikube-v1.9.0.iso.sha256: 65 B / 65 B [--------------] 100.00% ? p/s 0s
    > minikube-v1.9.0.iso: 174.93 MiB / 174.93 MiB [-] 100.00% 6.20 MiB p/s 29s
👍  Starting control plane node m01 in cluster minikube
💾  Downloading Kubernetes v1.18.0 preload ...
    > preloaded-images-k8s-v2-v1.18.0-docker-overlay2-amd64.tar.lz4: 542.91 MiB
🔥  Creating kvm2 VM (CPUs=2, Memory=3900MB, Disk=20000MB) ...
🐳  Preparing Kubernetes v1.18.0 on Docker 19.03.8 ...
🌟  Enabling addons: default-storageclass, storage-provisioner
🏄  Done! kubectl is now configured to use "minikube"

❗  /usr/local/bin/kubectl is v1.13.4, which may be incompatible with Kubernetes v1.18.0.
💡  You can also use 'minikube kubectl -- get pods' to invoke a matching version
[kamran@kworkhorse ~]$ 
```

At this point, you should see minikube VM running in KVM:
|  ![images/minikube-vm-in-kvm.png](images/minikube-vm-in-kvm.png) |
| --------------------------------------------------------------- |



```
[kamran@kworkhorse ~]$ kubectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
minikube   Ready    master   2m    v1.18.0
[kamran@kworkhorse ~]$ 
```

### Minikube Addons:
By deafult, Minikube brings several addons with it in the deafult installation, but only few are enabled. Depending on your needs you can enable different addons.

```
[kamran@kworkhorse ~]$ minikube addons list
|-----------------------------|----------|--------------|
|         ADDON NAME          | PROFILE  |    STATUS    |
|-----------------------------|----------|--------------|
| dashboard                   | minikube | disabled     |
| default-storageclass        | minikube | enabled ✅   |
| efk                         | minikube | disabled     |
| freshpod                    | minikube | disabled     |
| gvisor                      | minikube | disabled     |
| helm-tiller                 | minikube | disabled     |
| ingress                     | minikube | disabled     |
| ingress-dns                 | minikube | disabled     |
| istio                       | minikube | disabled     |
| istio-provisioner           | minikube | disabled     |
| logviewer                   | minikube | disabled     |
| metrics-server              | minikube | disabled     |
| nvidia-driver-installer     | minikube | disabled     |
| nvidia-gpu-device-plugin    | minikube | disabled     |
| registry                    | minikube | disabled     |
| registry-aliases            | minikube | disabled     |
| registry-creds              | minikube | disabled     |
| storage-provisioner         | minikube | enabled ✅   |
| storage-provisioner-gluster | minikube | disabled     |
|-----------------------------|----------|--------------|
[kamran@kworkhorse ~]$ 
```

```
[kamran@kworkhorse ~]$ minikube addons enable dashboard
🌟  The 'dashboard' addon is enabled
[kamran@kworkhorse ~]$ 
```

To use the dashboard addon, run the `minikube dashboard` command:

```
[kamran@kworkhorse ~]$ minikube dashboard
🤔  Verifying dashboard health ...
🚀  Launching proxy ...
🤔  Verifying proxy health ...
🎉  Opening http://127.0.0.1:37419/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/ in your default browser...
Opening in existing browser session.
```

(At this point a browser window will open in your computer and Kubernetes dashboard will be running visible inside it.)

|  ![images/minikube-dashboard.png](images/minikube-dashboard.png) |
| --------------------------------------------------------------- |


One more addon that will surely prove useful is the `metrics-server`. It will help you figure out how much CPU and RAM your pods (and node) are consuming.

``` 
[kamran@kworkhorse ~]$ minikube addons enable metrics-server
🌟  The 'metrics-server' addon is enabled
[kamran@kworkhorse ~]$ 
``` 

Nodes - CPU and RAM usage:
```
[kamran@kworkhorse ~]$ kubectl top nodes
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
minikube   153m         7%     1193Mi          33%       
[kamran@kworkhorse ~]$ 
```

Pods - CPU and RAM usage:
```
[kamran@kworkhorse ~]$ kubectl top pods --all-namespaces
NAMESPACE              NAME                                         CPU(cores)   MEMORY(bytes)   
kube-system            coredns-66bff467f8-dww5p                     2m           6Mi             
kube-system            coredns-66bff467f8-hnbxp                     2m           6Mi             
kube-system            etcd-minikube                                24m          47Mi            
kube-system            kube-apiserver-minikube                      48m          281Mi           
kube-system            kube-controller-manager-minikube             20m          34Mi            
kube-system            kube-proxy-hdc9r                             0m           13Mi            
kube-system            kube-scheduler-minikube                      4m           10Mi            
kube-system            metrics-server-7bc6d75975-kp4kp              0m           10Mi            
kube-system            storage-provisioner                          0m           17Mi            
kube-system            tiller-deploy-58bf6f4995-nvwc6               0m           6Mi             
kubernetes-dashboard   dashboard-metrics-scraper-84bfdf55ff-jtp2z   0m           4Mi             
kubernetes-dashboard   kubernetes-dashboard-bc446cc64-wccx9         0m           7Mi             
[kamran@kworkhorse ~]$ 
```



Install Helm-Tiller addon, which is good to install helm charts on your minikube cluster:
```
[kamran@kworkhorse ~]$ minikube addons enable helm-tiller
🌟  The 'helm-tiller' addon is enabled
[kamran@kworkhorse ~]$ 
```


The plugins you enable will show up as pods in the `kube-system` name-space.

```
[kamran@kworkhorse ~]$ kubectl --namespace=kube-system get pods
NAME                               READY   STATUS    RESTARTS   AGE
coredns-66bff467f8-dww5p           1/1     Running   0          47m
coredns-66bff467f8-hnbxp           1/1     Running   0          47m
etcd-minikube                      1/1     Running   0          47m
kube-apiserver-minikube            1/1     Running   0          47m
kube-controller-manager-minikube   1/1     Running   0          47m
kube-proxy-hdc9r                   1/1     Running   0          47m
kube-scheduler-minikube            1/1     Running   0          47m
metrics-server-7bc6d75975-kp4kp    1/1     Running   0          11m     <--- Addon added later
storage-provisioner                1/1     Running   1          47m
tiller-deploy-58bf6f4995-nvwc6     1/1     Running   0          89s     <--- Addon added later
[kamran@kworkhorse ~]$ 
```

## Stopping and starting minikube:

You can stop the VM using:
```
[kamran@kworkhorse ~]$ minikube stop
✋  Stopping "minikube" in kvm2 ...
🛑  Node "m01" stopped.
[kamran@kworkhorse ~]$ 
```

You can start an existing minikube VM by simply running the `minikube start` command. It will pick up all the configuration from files inside `~/.minikube/*` , and bring up the minikube VM in the same state as it was before (including addons). i.e. In such case, it will not create a new minikube VM.

```
[kamran@kworkhorse ~]$ minikube start
😄  minikube v1.9.2 on Fedora 31
    ▪ KUBECONFIG=/home/kamran/.kube/config:/home/kamran/.kube/kubeadm-cluster.conf
✨  Using the kvm2 driver based on existing profile
👍  Starting control plane node m01 in cluster minikube
🔄  Restarting existing kvm2 VM for "minikube" ...
🐳  Preparing Kubernetes v1.18.0 on Docker 19.03.8 ...
🌟  Enabling addons: dashboard, default-storageclass, helm-tiller, metrics-server, storage-provisioner
🏄  Done! kubectl is now configured to use "minikube"

❗  /usr/local/bin/kubectl is v1.13.4, which may be incompatible with Kubernetes v1.18.0.
💡  You can also use 'minikube kubectl -- get pods' to invoke a matching version
[kamran@kworkhorse ~]$ 
```

```
[kamran@kworkhorse ~]$ minikube status
m01
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

[kamran@kworkhorse ~]$ 
```

## Lets just verify host to minikube VM connectivity:

Find the IP of your minikube machine. This is important for understanding, but we will talk about this in a moment.
```
[kamran@kworkhorse ~]$ minikube ip
192.168.39.174
```

```
[kamran@kworkhorse ~]$ ping 192.168.39.174
PING 192.168.39.174 (192.168.39.174) 56(84) bytes of data.
64 bytes from 192.168.39.174: icmp_seq=1 ttl=64 time=0.195 ms
64 bytes from 192.168.39.174: icmp_seq=2 ttl=64 time=0.272 ms
^C
--- 192.168.39.174 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1009ms
rtt min/avg/max/mdev = 0.195/0.233/0.272/0.038 ms
[kamran@kworkhorse ~]$ 
```


For any OS related maintenance (or exploration), log onto the minikube vm directly, using `minikube ssh` command:
```
[kamran@kworkhorse ~]$ minikube ssh
                         _             _            
            _         _ ( )           ( )           
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __  
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ 

$ sudo -i
sudo: /etc/environment: No such file or directory
# 
```
(Ignore the error message about `/etc/environment`) 


## Setup `/etc/hosts` on host computer:
On the host computer, add an entry for minikube in the `/etc/hosts` file.

```
[root@kworkhorse ~]# head /etc/hosts
127.0.0.1  localhost localhost.localdomain

# minikube VM
192.168.39.174	minikube
[root@kworkhorse ~]#
```


## Use kubectl to interact with kuberntes cluster running in minikube:
Now we have minikube installed. It is time to start using it. We already have kubectl installed on the host computer, and minikube has already created a `kube/config` for us. Minikube also sets the context for kubectl to use minikube cluster. So if we run `kubectl` commands against this cluster, the commands will work. 

```
[kamran@kworkhorse ~]$ kubectl config get-contexts
CURRENT   NAME                                                    CLUSTER                                                 AUTHINFO                                                NAMESPACE
          gke_trainingvideos_europe-north1-a_docker-to-k8s-demo   gke_trainingvideos_europe-north1-a_docker-to-k8s-demo   gke_trainingvideos_europe-north1-a_docker-to-k8s-demo   
          kubernetes-admin@kubernetes                             kubernetes                                              kubernetes-admin                                        
*         minikube                                                minikube                                                minikube                                                
[kamran@kworkhorse ~]$ 
```

```
[kamran@kworkhorse ~]$ kubectl get nodes -o wide
NAME       STATUS   ROLES    AGE     VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE               KERNEL-VERSION   CONTAINER-RUNTIME
minikube   Ready    master   3d22h   v1.18.0   192.168.39.174   <none>        Buildroot 2019.02.10   4.19.107         docker://19.3.8
[kamran@kworkhorse ~]$ 
```

## Create our first deployment on this cluster:
Lets create our first deployment on this cluster, and then access it from our host computer.

```
[kamran@kworkhorse ~]$ kubectl create deployment nginx --image=nginx:alpine
deployment.apps/nginx created

[kamran@kworkhorse ~]$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
nginx-745b4df97d-wjrtr   1/1     Running   0          14s
[kamran@kworkhorse ~]$ 
```

Lets expose this deployment as a service of `type: NodePort`, so we can access it from our host computer. 

```
[kamran@kworkhorse ~]$ kubectl expose deployment nginx --type=NodePort --port 80
service/nginx exposed


[kamran@kworkhorse ~]$ kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        4d1h
nginx        NodePort    10.98.136.156   <none>        80:31255/TCP   6s
[kamran@kworkhorse ~]$ 

```

Now, we can access this service using our minikube VM's IP address and the NodePort assigned to the service.

```
[kamran@kworkhorse ~]$ curl 192.168.39.174:31255
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
. . . 
</head>
<h1>Welcome to nginx!</h1>
</html>
[kamran@kworkhorse ~]$ 
```

Great! So we can access the service using VM's IP and the NodePort of the service.


## Update `/etc/hosts` with the IP address of the minikube VM:
Now, two things. 
* Accessing your kubernetes services using node's IP address is kind of silly. Because you need to remember the IP address of the VM. Or, obtain it from `minikube ip` command each time before doing anything useful. For this, we can put it in our `/etc/hosts` 
* The IP of the minikube VM may change from time to time, which means you will be required to update `/etc/hosts` almost always.

So the above will send you running in circles. My suggestion is to keep the IP in the `/etc/hosts`, and then create a script which you can use to simply update the `/etc/hosts` file without much hassle. Since `/etc/hosts` is only writable by user `root`, you will either need to run this script as `sudo` , or run it directly as `root`. A better work-around is that you change the group ownership of the `/etc/hosts` file to your the group your user belongs to (e.g. `sudo chgrp kamran /etc/hosts`). Then also add write permissions to the group (i.e. `sudo chmod g+w /etc/hosts`). This way you will be able to edit the /etc/hosts file without `sudo` or being `root`, and it will still be safe.

First, lets add this in /etc/hosts:
```
[root@kworkhorse ~]# cat /etc/hosts
127.0.0.1  localhost localhost.localdomain

# minikube VM
192.168.39.174	minikube
[root@kworkhorse ~]# 
```


```
#!/bin/bash
MINIKUBE_IP=$(minikube ip)
if [ $? -eq 0 ]; then
  echo "Updating /etc/hosts file ..."
  sed s/^.*[[:space:]]minikube/${MINIKUBE_IP}\ minikube/g /etc/hosts
else
  echo "'minikube ip' command did not return a valid IP address. Skipping update."
fi 
```


# Some limitations of minikube:

* The IP address of the minikube VM may change during subsequent `stop` , `start` operations. 
* MiniKube does provides you the ability to create services as `type: LoadBalancer`. 
* Can't setup any HTTPS reverse proxy with LetsEncrypt's HTTP challenge because you will most probably be behind a home router/firewall. If you install Traefik with HTTPS support enabled, (without enabling LetsEncrypt), you can still access your apps over HTTPS using TRAEFIK_DEFAULT_CERT. This certificate is self signed, but at least you will get HTTPS URLs working. 
* Though you can use LetsEncrypt DNS challenge to get valid certificates for your apps running in your minikube cluster, and have your apps served through HTTPS. 

------

# How minikube works - the networking part - Advanced topic

First, if you installed minikube **on Linux** *and* **used KVM for Virtualization**, then congratulations, you made the best choice! :) The reason is, Linux and KVM setup is very simple and straight-forward. There is nothing hidden, complicated, fearful or frustrating - as it is the case with Windows and VirtualBox/HyperV. (I will discuss this at a later time.)

This article discusses a minikube VM, running in KVM, on Fedora Linux.

## KVM virtual networks:
By default, KVM (libvirt) sets up a virtual network on your Linux host, and calls it `virbr0` (or, Virtual Bridge - Zero). This is a **NAT** type network,(Network Address Translation), which NATs any traffic coming in from inside this virtual network, trying to reach the internet, via any of the physical devices on your host. i.e either your wireless adapter, or network/ethernet port, or modem. So, this way, not only you can access the VMs you create (on this network), the VMs (on this network) can easily reach the internet also. 

When you install `minikube` , it creates an additional **isolated** virtual network inside KVM, and connects the minikube VM to both of these networks. i.e. it attaches itself to the NAT network as well as the isolated network. Like so:

| ![images/minikube-network.png](images/minikube-network.png) |
| ----------------------------------------------------------- |


# Why minikube uses two different networks?
Basically, I found no documentation on this topic so far. Minikube's documentation is completely silent about it. It is not discussed in any discussion forums, or GitHub issues, etc. Some people have asked somewhat similar questions, but either the discussion went into another direction, or the issue/thread simply died.

Below is my understanding so far. 

I think that minikube simply wants to deliver a development environment **completely local** to your work-computer. It does not want the kubernetes cluster (running inside the minikube VM) to be reached from the any other network. It also does not want to step on anyone else's toes in terms of IP addresses or networking in general - on this computer. That is why it simply sets up a new **"isolated"** virtual network, and sets up the VM to run on this network. Since the minikube VM needs to pull necessary software from the internet, such as `boot2docker.iso` and `minikube-v.x.y.z.iso`, and other things, it also connects the VM to a **NAT** network, which is normally the **default** network on any Hypervisor.

The minikube bootstrap process talks to the Hypervisor - KVM in our case - and dictates how the VM will be setup, such as:
* number of CPU cores
* amount of RAM
* size of disk
* network cards, and which network card connects to which network

When you pass the `--driver=kvm2` - or whatever Hypervisor you have on your computer - on the `minikube start` command, minikube configures itself to talk to that particular Hypervisor and get things done. That handles the "talking to the Hypervisor" part. When the VM is being created, the DHCP service attached to the virtual network assigns an IP address to it. This IP address can be queried/obtained directly from the hypervisor. e.g.

```
[root@kworkhorse ~]# virsh net-list
 Name              State    Autostart   Persistent
----------------------------------------------------
 default           active   yes         yes
 k8s-kubeadm-net   active   yes         yes
 minikube-net      active   yes         yes


[root@kworkhorse ~]# virsh net-dhcp-leases minikube-net
 Expiry Time           MAC address         Protocol   IP address          Hostname   Client ID or DUID
-----------------------------------------------------------------------------------------------------------
 2020-04-21 00:05:03   30:e0:ec:bf:64:8e   ipv4       192.168.39.174/24   minikube   01:30:e0:ec:bf:64:8e

[root@kworkhorse ~]# 
```

The minikube IP address discussed everywhere in this document is `192.168.39.174` .

During the bootstrap process minikube uses this IP address to configure various aspects of kubernetes components, and also places certain SSH keys inside the VM. It then does a ssh fingerprint scan against that IP address and keeps that in your local user's local config files specific to minikue, inside `~/.minikube` directory. It also configures a context for this newly created single-node kubernetes cluster, and places that inside your `~/.kube/config` file - using the same IP. Inside the VM, minikube configures kubernetes API server to only bind to the IP address from the isolated network. 

All of above happens when you use `minikube start --driver=kvm2` command. (The driver can be a different one depending on your hypervisor). Minikube perform all these checks every time you `start` the VM from the stopped state. If, for some reason, the IP changes, minikube bootstrap process updates all necessary file. 

This is the reason that `minikube ip` command **never** returns you the IP of the VM when the minikube VM is in stopped state. It does not just read the IP from config file and shows it to you. It actually queries the hypervisor each time `minikube ip` command is issued and depending on the VM's state, either shows the IP currently assigned to the VM by KVM's DHCP service, or refuses to show it to you if the VM is found in the stopped state. Below are examples of both cases:

```
[kamran@kworkhorse ~]$ minikube ip
🤷  The control plane node must be running for this command
👉  To fix this, run: "minikube start"
[kamran@kworkhorse ~]$
```

```
[kamran@kworkhorse ~]$ minikube ip
192.168.39.174
[kamran@kworkhorse ~]$
```

By the way, networking perspective, the minikube VM is accessible from the host, over both isolated and NAT networks. It is just that the kubectl commands will expect to connect to the IP of the API server listed in `.kube/config` file. This IP will always be from the isolated network. 

Below I have shown that this VM is accessible using standard network tools over both networks it is connected to. First, I find the IP addresses assigned to this VM by each virtual network's DHCP service.

```
[root@kworkhorse ~]# virsh net-dhcp-leases minikube-net
 Expiry Time           MAC address         Protocol   IP address          Hostname   Client ID or DUID
-----------------------------------------------------------------------------------------------------------
 2020-04-21 00:05:03   30:e0:ec:bf:64:8e   ipv4       192.168.39.174/24   minikube   01:30:e0:ec:bf:64:8e

[root@kworkhorse ~]# 
```


```
[root@kworkhorse ~]# virsh net-dhcp-leases default
 Expiry Time           MAC address         Protocol   IP address           Hostname   Client ID or DUID
------------------------------------------------------------------------------------------------------------
 2020-04-21 00:32:39   e8:94:3e:a6:a5:a7   ipv4       192.168.122.134/24   minikube   01:e8:94:3e:a6:a5:a7

[root@kworkhorse ~]# 
```

Now I can ping both IP addresses from my computer:

```
[root@kworkhorse ~]# ping -c 2 192.168.39.174
PING 192.168.39.174 (192.168.39.174) 56(84) bytes of data.
64 bytes from 192.168.39.174: icmp_seq=1 ttl=64 time=0.188 ms
64 bytes from 192.168.39.174: icmp_seq=2 ttl=64 time=0.276 ms

--- 192.168.39.174 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1031ms
rtt min/avg/max/mdev = 0.188/0.232/0.276/0.044 ms
[root@kworkhorse ~]# 
```

```
[root@kworkhorse ~]# ping -c 2 192.168.122.134
PING 192.168.122.134 (192.168.122.134) 56(84) bytes of data.
64 bytes from 192.168.122.134: icmp_seq=1 ttl=64 time=0.160 ms
64 bytes from 192.168.122.134: icmp_seq=2 ttl=64 time=0.121 ms

--- 192.168.122.134 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1042ms
rtt min/avg/max/mdev = 0.121/0.140/0.160/0.019 ms
[root@kworkhorse ~]# 
```

Minikube creates a RSA keypair in `.minikube/machines/minikube/`, which I can use to login to the VM as user `docker`. Actually the `minikube ssh` command also logs you in this VM using the user `docker`.

```
[kamran@kworkhorse ~]$ ssh -i .minikube/machines/minikube/id_rsa docker@192.168.39.174
                         _             _            
            _         _ ( )           ( )           
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __  
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ 
```


I can also log in to the same VM using the other IP address:

```
[kamran@kworkhorse ~]$ ssh -i .minikube/machines/minikube/id_rsa docker@192.168.122.134
The authenticity of host '192.168.122.134 (192.168.122.134)' can't be established.
ECDSA key fingerprint is SHA256:5Fy2a0TdCmA4+UbR7zDYF0cMOsOjcU10hdrYFeYo4pQ.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.122.134' (ECDSA) to the list of known hosts.
                         _             _            
            _         _ ( )           ( )           
  ___ ___  (_)  ___  (_)| |/')  _   _ | |_      __  
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ 
```






The two files, where some of this information is written are:
* ~/.minikube/profiles/minikube/config.json
* ~/.minikube/machines/minikube/config.json
 

```
[kamran@kworkhorse ~]$ cat ~/.minikube/profiles/minikube/config.json
{
	"Name": "minikube",
	"KeepContext": false,
	"EmbedCerts": false,
	"MinikubeISO": "https://storage.googleapis.com/minikube/iso/minikube-v1.9.0.iso",
	"Memory": 3900,
	"CPUs": 2,
	"DiskSize": 20000,
	"Driver": "kvm2",
. . . 
. . . 
	},
	"Nodes": [
		{
			"Name": "m01",
			"IP": "192.168.39.174",
			"Port": 8443,
			"KubernetesVersion": "v1.18.0",
			"ControlPlane": true,
			"Worker": true
		}
	],
	"Addons": {
		"dashboard": true,
		"default-storageclass": true,
		"helm-tiller": true,
		"metrics-server": true,
		"storage-provisioner": true
	},
	"VerifyComponents": {
		"apiserver": true,
		"system_pods": true
	}
}
[kamran@kworkhorse ~]$ 
```


```
[kamran@kworkhorse ~]$ cat .minikube/machines/minikube/config.json 
{
    "ConfigVersion": 3,
    "Driver": {
        "IPAddress": "192.168.39.174",
        "MachineName": "minikube",
        "SSHUser": "docker",
        "SSHPort": 22,
        "SSHKeyPath": "/home/kamran/.minikube/machines/minikube/id_rsa",
        "StorePath": "/home/kamran/.minikube",
        "SwarmMaster": false,
        "SwarmHost": "",
        "SwarmDiscovery": "",
        "Memory": 3900,
        "CPU": 2,
        "Network": "default",
        "PrivateNetwork": "minikube-net",
        "DiskSize": 20000,
        "DiskPath": "/home/kamran/.minikube/machines/minikube/minikube.rawdisk",
        "Boot2DockerURL": "file:///home/kamran/.minikube/cache/iso/minikube-v1.9.0.iso",
        "ISO": "/home/kamran/.minikube/machines/minikube/boot2docker.iso",
        "MAC": "e8:94:3e:a6:a5:a7",
        "PrivateMAC": "30:e0:ec:bf:64:8e",
        "GPU": false,
        "Hidden": false,
        "DevicesXML": "",
        "ConnectionURI": "qemu:///system"
    },
    "DriverName": "kvm2",
    "HostOptions": {
        "Driver": "",
        "Memory": 0,
        "Disk": 0,
        "EngineOptions": {
            "ArbitraryFlags": null,
            "Dns": null,
            "GraphDir": "",
            "Env": null,
            "Ipv6": false,
            "InsecureRegistry": [
                "10.96.0.0/12"
            ],
. . . 
        },
. . . 
        "AuthOptions": {
            "CertDir": "/home/kamran/.minikube",
            "CaCertPath": "/home/kamran/.minikube/certs/ca.pem",
            "CaPrivateKeyPath": "/home/kamran/.minikube/certs/ca-key.pem",
            "CaCertRemotePath": "",
            "ServerCertPath": "/home/kamran/.minikube/machines/server.pem",
            "ServerKeyPath": "/home/kamran/.minikube/machines/server-key.pem",
            "ClientKeyPath": "/home/kamran/.minikube/certs/key.pem",
            "ServerCertRemotePath": "",
            "ServerKeyRemotePath": "",
            "ClientCertPath": "/home/kamran/.minikube/certs/cert.pem",
            "ServerCertSANs": null,
            "StorePath": "/home/kamran/.minikube"
        }
    },
    "Name": "minikube"
}
[kamran@kworkhorse ~]$ 
```


# Further reading:
* [https://wiki.libvirt.org/page/VirtualNetworking](https://wiki.libvirt.org/page/VirtualNetworking)
* [https://kubernetes.io/docs/setup/learning-environment/minikube/](https://kubernetes.io/docs/setup/learning-environment/minikube/)
* [https://docs.gitlab.com/charts/development/minikube/](https://docs.gitlab.com/charts/development/minikube/)
* [https://minikube.sigs.k8s.io/docs/handbook/](https://minikube.sigs.k8s.io/docs/handbook/)

