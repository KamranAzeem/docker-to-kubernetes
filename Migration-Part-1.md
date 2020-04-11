# Migrating from Docker-Compose to Kubernetes

This series of articles talks about the ways to move your applications running on docker-compose to a Kubernetes cluster on GCP (Google Cloud Platform). The audience of these articles are both the system admins and the application developers. The articles guide the system/cluster admins on how to migrate the various **infrastructure services** from docker-compose to the kubernetes cluster. It also guides the developers on how to migrate their **applications** from docker-compose to Kubernetes. All the steps are performed on an actual production setup, running applications on docker-compose. So this is a real deal!

Moving your applications to Kubernetes is not straight-forward. (Developing your apps for Kubernetes is not straight-forward either). **State is hard**. Kubernetes has a lot of moving parts. Many of the concepts are new. In short, there are many potential pitfalls. You really need to have a clear understanding of how your current application works. You also need to understand how Kubernetes works. It is going to be bit painful, feel complex; but it will reward you in spades. Trust me! :)

I hope that with this series of articles (and the related videos), I would be able to help my development team to understand how applications are deployed (differently) in Kubernetes, providing them with necessary skills to migrate their applications from docker-compose to Kubernetes. I also want to help anyone out there in the world , who is in the similar situation. I hope this work proves useful!


There are two very important things to remember before we start on this journey:
1. **Kubernetes != Docker/Compose**
2. **Kubernetes is not a magic wand**


## Prerequisites:
The following need to be installed and setup correctly on your computer, before we continue.
* gcloud
* kubectl

## Existing setup:
I am helping a friend of mine to manage his current setup on AWS, who wants to move to Kubernetes. The setup consists of three servers:
* A single database server running MySQL, Postgres and MongoDB instances
* Two servers running docker-compose on Fedora Linux. One of these servers is hosting some wordpress websites, running on docker-compose. The other server is running some applications being built in-house using various technologies (Node.js, C#, etc), on docker-compose.
* The domain I will use in these articles - for the demo purpose - is `demo.wbitt.com` . The main infrastructure and various services are currently running under the domain name `witpass.co.uk`
* The exiting services on these servers talk to each other on the internal domain named `aws.witpass.co.uk`.
* There is a separate Traefik reverse proxy instance running on each application server.

| ![images/current-setup.png](images/current-setup.png) |
| ----------------------------------------------------- |
| Current Setup |


**Important note:**
I am aware above is not an optimal setup, and there are single points of failure everywhere.(Very unlike me - you would say!). Well, this was actually a "proof-of-concept" move to the cloud, which **somehow** became **"production"**. We wanted to keep the cost to lowest possible, without sacrificing any functionality, thus the small/minimal amount of servers. I have been trying to move to a more robust / resilient setup for a long time, but many factors prevented that from happening. 


### Problems in existing setup:
* Of course there is no resilience, no fault tolerance.
* The DB server can go down any moment. If it goes down (crashes), we have to rebuild it from backups.
* The capacity on the current application servers is a constant problem.
* Applications on one server cannot talk to the applications on the other server, because all applications run on a separate internal docker network on each server.
* Setting up resource limits on docker-compose is not possible, unless one is using docker-swarm, which we don't.
* We cannot move one application to another server without manual/admin intervention. 
* The applications are being deployed manually, not through any CI/CD pipeline.
* The state of various applications is being maintained on local file-system of the servers.
* In case any of the application server fails (crashes), we would need to rebuild it from backups.

## Advantages in moving to Kubernetes:
* **Resilience**, because Kubernetes promises resilience on top of everything else.
* Pods can relocate to surviving nodes without admin intervention.
* Cluster capacity can be increased (or decreased) at will by adding (or removing) worker nodes.
* There is one large pod network, and all pods/containers talk to each other - except when prohibited by network policies, not discussed in this article.
* Setting up CPU and resource limits for applications/pods/containers are very easy.
* Most of the application deployment can be automated by CI/CD.
* Disk based state is maintained on persistent volumes provided by GCP, which are central to the entire cluster.
* Our applications simply move to a surviving worker node if a worker node crashes, eliminating the need to rebuild servers, or worker nodes. When worker nodes crash, then they are simply removed and new ones are added. Building new worker nodes is a task handled by GCP. 


## Why move to GCP/GKE? Why not AWS/EKS? or any other?
I have experience of setting up and using Kubernetes cluster on different cloud providers, and found GKE to be the best. We know that AWS being the first cloud provider, has a very large number of customers. That is true. But, when Kubernetes came out, AWS made a mistake of sticking to their guns (ECS). When Kubernetes got enough traction, they also decided to join the party, but were late. Their "Kubernetes as a Service" - EKS - is just plain horrible. It is a mess. Although we are currently running our setup on AWS, we are not married to it, and we don't have children with it (like using AWS's other services), so we can definitely move away to a more solid platform. GCP/GKE is the gold standard anyway. If I start writing about all the goodness GKE/GCP provides, this article will become a book! So, in short, our choice is GKE.


## Two sample applications running on my servers:
I have two simple applications running on my current server(s), which I will use to explain various concepts.

* A simple WordPress website [https://github.com/KamranAzeem/testblog.demo.wbitt.com](https://github.com/KamranAzeem/testblog.demo.wbitt.com)
* A simple HTML/PHP website [https://github.com/KamranAzeem/simple.demo.wbitt.com](https://github.com/KamranAzeem/simple.demo.wbitt.com)


### The Wordpress website:

Here is the `docker-compose.server.yml` file for my (test) blog website:

```
$ cat docker-compose.server.yml 

version: "3"
services:
  testblog.demo.wbitt.com:
    image:  wordpress:latest
    labels:
      - traefik.enable=true
      - traefik.port=80
      - traefik.frontend.rule=Host:testblog.demo.wbitt.com

    env_file:
      - testblog.env

    volumes:
      - /home/containers-data/testblog.demo.wbitt.com:/var/www/html

    networks:
      - services-network

networks:
  services-network:
    external: true
```

Here are the secrets I am passing to this container:
```
$ cat testblog.env

WORDPRESS_DB_HOST=db.aws.witpass.co.uk
WORDPRESS_DB_NAME=db_testblog_demo_wbitt_com
WORDPRESS_DB_USER=user_testblog_demo_wbitt_com
WORDPRESS_DB_PASSWORD=+GmNr+EYYT3LdHb/lYO5/w==
WORDPRESS_TABLE_PREFIX=wp_
APACHE_RUN_USER=#1001
APACHE_RUN_GROUP=#1001
```


Based on the information we see in the docker-compose file above, the WordPress website has the following properties:

* Site name: `testblog.demo.wbitt.com` , which points to the IP address of `web.witpass.co.uk` where all our wordpress based websites are running as docker containers.
* This website used an existing/official Wordpress docker image: `wordpress:latest`
* The `testblog.env` file is used to provide secrets (DB access details) to the WordPress image at run time.
* Site's **DB state** is saved in a database created manually in the database server: `db.aws.witpass.co.uk`
* Site's **File/disk state** is saved under a directory: `/home/containers-data/testblog.demo.wbitt.com/`. This is where all the wordpress software, uploads, and plugins, etc, are saved.

**Note:** I personally dislike the idea of storing "entire" wordpress installation as a **state**, and that is why I created a custom wordpress image, which only saves the state of `uploads`, and nothing else. This is a separate topic. The improved version of the wordpress image I just mentioned is here: [https://github.com/WITPASS/witpass-wordpress-docker-image](https://github.com/WITPASS/witpass-wordpress-docker-image)

| ![images/testblog.png](images/testblog.png) |
| ------------------------------------------- |

### The HTML+PHP website:
The simple HTML/PHP website has the following properties:

* Site name: `simple.demo.wbitt.com` , which points to the IP address of `web.witpass.co.uk` where all our wordpress based websites are running as docker containers.
* This website has static HTML content and builds a nginx based docker image at the time of start-up.
* This website also has some PHP files representing a simple dynamic (yet stateless) application. This would need to run through some PHP parser.
* One (imaginary) requirement is that the resulting docker image should be a private image. So this will need to be stored inside a private container repository. On GCP this is easily achievable. 
* This site/application needs some MySQL credentials to talk to a MySQL database. This information will be passed as environment variables.
* **The application uses environment variables in DB connection.** This is very important. There are no usernames and passwords stored with the code. If your application does that, use this example to convert it to use environment variables instead. It is very easy!
* This site does not need to store any state on file-system
* This site uses a configuration file for it's internal use, and expects it at a location `/config/site.conf` on the file system of the running container.

**Note:** I know this is a simple/HTML/PHP website, and it does not need a config file. This (config-file thing) is completely made-up, because I want to demonstrate something important around this, when we move this to Kubernetes. So there is no harm in assuming that there is a config file.

| ![images/simplesite.png](images/simplesite.png) |
| ----------------------------------------------- |


## Kubernetes setup:

To move our applications to Kubernetes, we would need to ensure that the individual needs of these applications are met. Certain things need to be in place. These are discussed next.

### The database service:
In current setup we have a single database server running three different database software, i.e. MySQL Postgres, MongoDB. Currently all applications connect to this database server on desired ports. We can have a similar setup in a slightly different way on Kubernetes. We can have three individual database services running as three separate "StatefulSet". This helps the database software to save it's state in a disk volume acquired using a "PersistentVolumeClaimTemplate". So MySQL , Postgres and MongoDB can have their individual StatefulSets. 

Lets talk about MySQL only. In Kubernetes terms, the MySQL instance needs:

* to be a StatefulSet object instead of Deployment. Read [this](https://github.com/KamranAzeem/kubernetes-katas/blob/master/08-storage-basic-dynamic-provisioning.md) to understand the "why".
* a publicly accessible docker container image. This will be `mysql:5.7` in our case.
* a disk volume to save it's data files. This will be a PVC of size 1 GB - for now.
* a secret (`MYSQL_ROOT_PASSWORD`), which will be used by the MySQL image to setup the MySQL instance correctly at first boot. 
* an internal/cluster service, so MySQL is accessible to all the services wishing to connect to it, within the same namespace.
* a way to be accessible / used by the admin from the internet, to be able to create databases and users for various applications / websites. For this, we would setup a very small and secure web interface for mysql, named `Adminer`. This Adminer software will have a "Deployment", a "Service" and an "Ingress", so we can access it from the internet. See note below.

**Note:** The database service will be setup by the main cluster administrator, so **this will be one time activity**. Though the process of creation of this service can be defined / saved as a github repository , in the form of `yaml` files, it does not need to be part of a CI/CD pipeline.

**Note:** Personally, I dislike the idea of providing global access to my database instance through any web interface. Refer to `The best way to access your database instance in Kubernetes` in this article.

### The ingress controller:
We will be setting up our website to be accessible over the internet. For that to work, we need an **ingress controller** in the cluster. This ingress controller will be a service - defined as `type: LoadBalancer`. In the docker-compose setup, we have Traefik running as the ingress controller - sort of. In our Kubernetes setup, we will continue to use Traefik (1.7) as Ingress controller. 

**Note:** The setup of Ingress Controller will also be a **one time activity** by the administrator.

### The individual applications:
Now we discuss the Kubernetes related needs of our applications. This is where developers will have the main interest, and they will have the main responsibility for deploying their applications on the cluster.

#### The WordPress application , and it's needs:
* It needs to be a **"Deployment"** , so we can scale up (and down) the number of replicas, depending on the load, which still able to serve the files on the (shared) disk from all the instances. This is only possible when you use a Deployment object, and not StatefulSet object.
* The Deployment will need an image. In this case, it uses a publicly available docker container image, so that is not a problem.
* The Deployment will need to know the location of MySQL database server, the DB for this wordpress installation , the DB username and passwords to connect to that database. This information cannot be part of the repository, so it is provided manually on the docker servers as `wordpress.env` file (as an example). On Kubernetes this information needs to be provided as environment variables. The question is, how? There are two ways. One, we create the secret manually from command line. The other way way is to setup the secrets as environment variables in the CI server. We will be using CircleCI for our CI/CD needs. We will see both methods to get this done. 
* The Deployment will also need a persistent storage for storing various files this wordpress software will create. The same location will also hold any content uploaded by the user, for example pictures, etc. This will be a PVC, and will be created separately. It's definition of creation will not be part of the same file as the `deployment.yaml` . This is to prevent any accidents of old PVCs being deleted and new ones being created automatically resulting in data loss. This problem has been explain in another article of mine: [https://github.com/KamranAzeem/kubernetes-katas/blob/master/08-storage-basic-dynamic-provisioning.md](https://github.com/KamranAzeem/kubernetes-katas/blob/master/08-storage-basic-dynamic-provisioning.md) . Anyhow, the developer will be required to create the necessary PV/PVC once, and then make sure to **never delete the PVC**. Till the time the PVC is there, the data will be safe. 

**Note:** This example uses with wordpress, which is quite "stateful". What we want, from the developers is: applications as stateless as possible. i.e. There should be no involvement of saving any state, eliminating a need to acquire and maintain PVCs and PVs. **This is very important in application design.** 

#### The simple static/HTML/PHP application and it's needs:
* It needs to be a **"Deployment"** , so we can scale up (and down) the number of replicas, depending on the load, which still able to serve the files on the (shared) disk from all the instances. This is only possible when you use a Deployment object, and *not* StatefulSet object.
* The Deployment will need to use the docker image of our application. Kubernetes objects cannot build container images. (Recall: Kubernetes != Docker). So, for this to work, the image needs to be built outside/before the deployment process is carried out. If the image needs to be a private image, then GCP's [gcr.io](gcr.io) is ideal, as it can create private container images without requiring any extra steps at our end. Though you can choose any container registry of your choice.
* The Deployment will also need a (imaginary) configuration file mounted at `/config/site.conf` . One can argue that a configuration file (or files) can be baked into the image itself. In our case, the image will come with a default *site.conf*  file, and we can override it anytime by creating a config map with custom configuration, before creating the main deployment. This can be done manually, or through the CI server. In case of CI server, the entire configuration file will need to be stored an an environment variable in the CI server and then be used inside the deployment pipeline. I will show you that too.


So, the first thing at hand is to setup a Kubernetes cluster, and then setup MySQL database service and Traefik Ingress Controller inside it.


## Kubernetes setup plan:

* Open DNS zone file in a separate browser tab, and let it remain open. We will come back to it later.
* Deploy Traefik Ingress Controller, and create it's related service as `type:LoadBalancer` and obtain the public IP. Configure Traefik to use HTTPS using LetsEncrypt **Staging server**. You can use this guide: [https://github.com/KamranAzeem/kubernetes-katas/tree/master/ingress-traefik/https-letsencrypt-HTTP-Challenge](https://github.com/KamranAzeem/kubernetes-katas/tree/master/ingress-traefik/https-letsencrypt-HTTP-Challenge). It is best to keep the Traefik deployment and Traefik service definition files separate.
* Once you have the IP address for the load balancer, you create a DNS record `traefik.demo.wbitt.com` in the DNS zone file for `demo.wbitt.com`domain, and update that with the IP address assigned to the Traefik load-balancer service. 
* Now you setup ingress for `traefik-ui.demo.wbitt.com` , and see if Traefik can get staging certificate for it. If it does, (which it should), then it means LetsEncrypt is correctly setup.
* Reconfigure Traefik to use SSL certificates from LetsEncrypt's **Production servers**.
* Deploy MySQL as StatefulSet, and create related service. Do not setup MySQL as type LoadBalancer, NodePort; nor setup an ingress object against it. It must not be accessible directly from outside the cluster.

**Note:** It is VERY important that you set TTL for the DNS zone of the related domain to a low value, say "5 minutes". This will ensure that when you change DNS records, the change is propagated quickly across DNS servers around the world.

## Kubernetes setup:

I have setup a Kubernetes cluster on GCP/GKE. I have also ensured that I can access it using kubectl on my local work computer:

```
[kamran@kworkhorse mysql]$ kubectl get cs
NAME                 STATUS    MESSAGE              ERROR
etcd-1               Healthy   {"health": "true"}   
scheduler            Healthy   ok                   
controller-manager   Healthy   ok                   
etcd-0               Healthy   {"health": "true"}   
[kamran@kworkhorse mysql]$ kubectl get nodes
NAME                                           STATUS   ROLES    AGE     VERSION
gke-docker-to-k8s-default-pool-b0b5bbac-dx7z   Ready    <none>   6m25s   v1.14.10-gke.17
[kamran@kworkhorse mysql]$ 
```

### Setup Traefik:

The first step is to setup Traefik with HTTPS enabled, using HTTP challenge. To achieve this, we use some extra files, i.e. `traefik.toml` and `dashboard-users.htpasswd`.

**Note:** Keep the deployment and service objects in separate files. [To do]

Remember to fix the email address in `traefik.toml` file.

```
[kamran@kworkhorse kubernetes]$ pwd
/home/kamran/Projects/Personal/github/docker-to-kubernetes/traefik/kubernetes

[kamran@kworkhorse kubernetes]$ kubectl  --namespace=kube-system  create configmap configmap-traefik-toml --from-file=traefik.toml
configmap/configmap-traefik-toml created

[kamran@kworkhorse kubernetes]$ htpasswd -c -b dashboard-users.htpasswd admin secretpassword

[kamran@kworkhorse kubernetes]$ kubectl  --namespace=kube-system  create secret generic secret-traefik-dashboard-users --from-file=dashboard-users.htpasswd
secret/secret-traefik-dashboard-users created

[kamran@kworkhorse kubernetes]$ kubectl apply -f traefik-rbac.yaml 
clusterrole.rbac.authorization.k8s.io/traefik-ingress-controller created
clusterrolebinding.rbac.authorization.k8s.io/traefik-ingress-controller created


[kamran@kworkhorse kubernetes]$ kubectl apply -f traefik-deployment.yaml
serviceaccount/traefik-ingress-controller created
persistentvolumeclaim/pvc-traefik-acme-json created
deployment.extensions/traefik-ingress-controller created
service/traefik-ingress-service created
[kamran@kworkhorse kubernetes]$ 
```

Verify:
```
[kamran@kworkhorse kubernetes]$ kubectl --namespace=kube-system get pods
NAME                                                       READY   STATUS    RESTARTS   AGE
. . . 
traefik-ingress-controller-d76466dfc-zd59d                 1/1     Running   0          72s
```

```
[kamran@kworkhorse kubernetes]$ kubectl --namespace=kube-system get svc
NAME                      TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)                                     AGE
default-http-backend      NodePort       10.0.15.173   <none>         80:31416/TCP                                21m
heapster                  ClusterIP      10.0.0.16     <none>         80/TCP                                      21m
kube-dns                  ClusterIP      10.0.0.10     <none>         53/UDP,53/TCP                               22m
metrics-server            ClusterIP      10.0.9.117    <none>         443/TCP                                     21m
traefik-ingress-service   LoadBalancer   10.0.14.84    35.228.250.6   80:30307/TCP,443:30999/TCP,8080:31041/TCP   111s
```



#### Deploy Traefik UI:

Find the IP of Traefik LB `35.228.250.6`, and adjust the DNS domain, so everything points to the traefik lb . Make sure that DNS has propagated:

```
[kamran@kworkhorse kubernetes]$ dig traefik-ui.demo.wbitt.com

;; QUESTION SECTION:
;traefik-ui.demo.wbitt.com.	IN	A

;; ANSWER SECTION:
traefik-ui.demo.wbitt.com. 299	IN	CNAME	traefik.demo.wbitt.com.
traefik.demo.wbitt.com.	299	IN	A	35.228.250.6

. . . 
[kamran@kworkhorse kubernetes]$ 
```

Create Traefik-web-UI deployment:

```
[kamran@kworkhorse kubernetes]$ kubectl apply -f traefik-webui-ingress.yaml 
service/traefik-web-ui created
ingress.extensions/traefik-web-ui created
[kamran@kworkhorse kubernetes]$ 

```

Verify by looking at Traefik web interface.


| ![images/traefik-web-ui-intial.png](images/traefik-web-ui-intial.png) |
| --------------------------------------------------------------------- |


**Note:** If you configured Traefik to obtain SSL certificates from **staging servers** , then at this point in time re-configure Traefik to use LetsEncrypt **production servers** . Perform the following steps:
* Delete the Traefik deployment
* Delete PVC used by Traefik
* Delete Traefik configmap (used for `traefik.toml`)
* Edit `traefik.toml` file and update address of certificate servers
* Re-create configmap for `traefik.toml`
* Re-create Traefik deployment and the related PVC by: `kubectl apply -f traefik-deployment.yaml`


### Setup MySQL:

The MySQL setup runs a MySQL:5.7 docker container image. This image is capable of creating an additional database (and username and password) if certain environment variables are passed to it . We can very easily use this feature to create a database and related user for our WordPress website, but, we would be moving in more databases from our current/old DB server to this instance. For that reason, creating this addition database (and related user) is not very useful. It is best to setup this database instance using only the `MYSQL_ROOT_PASSWORD`. Later, when we need to create various databases and their related users, we can connect to this instance as the root user, and get all these tasks done. So this would be just like any other regular/normal database instance.

**Note:** In this repository, there is another file named `mysql-statefulset-for-wordpress.yaml` . Use that if all you want to do is run a database instance for a single wordpress website. 

#### Create secret for MySQL:
There is a file in this repository, named `mysql.env`. Update the value for `MYSQL_ROOT_PASSWORD`. Then, use the `create-mysql-credentials.sh` file to create `MYSQL_ROOT_PASSWORD` as a **secret**  in your kubernetes cluster. For the sake of example, everything will be deployed in the `default` namespace.

```
[kamran@kworkhorse mysql]$ ./create-mysql-credentials.sh 
First delete the old secret: mysql-credentials
Error from server (NotFound): secrets "mysql-credentials" not found
Found mysql.env file, creating kubernetes secret: mysql-credentials
secret/mysql-credentials created
[kamran@kworkhorse mysql]$ 
```



#### Create Statefulset for MySQL:

Adjust cpu/memory limits, and the size of PVC in `mysql-statefulset.yaml`, then create the Statefulset for MySQL.

```
[kamran@kworkhorse mysql]$ kubectl apply -f mysql-statefulset.yaml
statefulset.apps/mysql created
service/mysql created
[kamran@kworkhorse mysql]$
```

Verify:

```
[kamran@kworkhorse mysql]$ kubectl get statefulset
NAME    READY   AGE
mysql   1/1     86s


[kamran@kworkhorse mysql]$ kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   1/1     Running   0          80s

[kamran@kworkhorse kubernetes]$ kubectl get pvc
NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-persistent-storage-mysql-0   Bound    pvc-b03e5db9-60b8-11ea-9327-42010aa600a1   1Gi        RWO            standard       90s
[kamran@kworkhorse kubernetes]$ 
```


```
[kamran@kworkhorse mysql]$ kubectl exec -it mysql-0 bash

root@mysql-0:/# mysql -u root -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.7.29 MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.04 sec)

mysql> 

```

MySQL running properly. No more to be done about MySQL.


### Setup adminer [OPTIONAL]

This step is completely un-necessary for most setups. I strongly discourage exposing your database instance to the entire world through a web interface such as `adminer` or `phpmyadmin`, etc.

Still, if some setup requires it, then the steps to set it up are provided below:

(To do)


Now, we move forward to migrating our first application to this Kubernetes cluster. The steps to do that are here: [Migration-Part-2.md](Migration-Part-2.md)

# Additional Notes:
* To generate random passwords, I use: `openssl rand -base64 18`. I have set it up as an alias in my `~/.bashrc` as: `alias generate_random_16='openssl rand -base64 18'`
