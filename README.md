# Docker-Compose to Kubernetes

This article talks about the ways to move your applications running on docker-compose to a Kubernetes cluster on GCP. It also shows how to achieve "continuous delivery" to get this done. The audience of this article are both the system admins and the developers. The article guides the system/cluster admins on how to migrate the various infrastructure services from docker-compose to the kubernetes cluster. It also guides the developers on how to migrate their applications from docker-compose to kubernetes, and most importantly how to "continuously" deploy their applications on a kubernetes cluster using a CD tool.

Moving to Kubernetes for existing applications is not straight-forward. There are many potential pitfalls. You really need to have a clear understanding of how your current application works. You also need to understand how Kubernetes works. It is going to be bit painful, or feel complex, but in reality, it is not. It will reward you in spades.

There are two very important things to remember before we start on this journey:
1. **Kubernetes is not a  magic wand**, and,
2. **Kubernetes != Docker-Compose**


This article will show all the steps performed on an actual production setup, running applications on docker-compose. So this is a real deal!

## Existing setup:
I am helping a friend of mine to manage his current setup on AWS, who wants to move to Kubernetes. The setup consists of three servers:
* A single database server running MySQL, Postgres and MongoDB instances
* Two servers running docker-compose on Fedora Linux. One of these servers is hosting some wordpress websites, running on docker-compose. The other server is running some applications being built in-house using various technologies (Node.js, C#, etc), on docker-compose.
* The domain I will use in this article for the demo purpose is `demo.wbitt.com` . The main infrastructure and various services run under the domain name `witpass.co.uk`
* The services talk to each other on the internal domain named `aws.witpass.co.uk`.
* There is a separate Traefik reverse proxy instance running on each application server.

| ![images/current-setup.png](images/current-setup.png) |
| ----------------------------------------------------- |
| Current Setup |


**Important note:**
I am aware this is not an optimal setup, and there are few single points of failure. This was actually a "proof-of-concept" move to the cloud, which suddenly became "production". We wanted to keep the cost to lowest possible, without sacrificing any functionality, thus the small/minimal amount of servers.

### Problems in existing setup:
* Of course there is no resilience, no fault tolerance.
* The DB server can go down any moment. If it goes down, we have to rebuild it from backups.
* The capacity on the current application servers is a constant problem.
* Applications on one server cannot talk to the applications on the other server, because all applications run on an internal docker network on each server.
* Setting up resource limits on docker-compose is a problem.
* We cannot move one application to another server without manual/admin intervention. 
* The applications are being deployed manually, not through any CI/CD pipeline.
* The state of various applications is being maintained on local file-system of the servers.
* In case any of the application server fails, we would need to rebuild it from backups.

## Advantages in moving to Kubernetes:



## Why move to GCP/GKE? Why not AWS/EKS? or any other?
First, we don't want to be managing the kubernetes cluster ourselves. So the choices were AWS or GCP. 

I have experience of setting up and using Kubernetes cluster on different cloud providers, and found GKE to be the best. We know that AWS being the first cloud provider, has a very large number of customers. That is true. But when Kubernetes came out, AWS made a mistake of sticking to their guns (ECS). When Kubernetes got enough traction, they also decided to join the party, but were late. Their "Kubernetes as a Service" - EKS - is just plain horrible. It is a mess. Although we are currently running our setup on AWS, we are not married to it, we don't have children with it (like using AWS's other services), so we can definitely move away to a more solid platform. GCP/GKE is the gold standard anyway, so our choice is GKE.


## Two sample applications running on my servers:
I have two simple applications running on my current server(s), which I will use to explain various concepts.

* A simple static/HTML website [https://github.com/KamranAzeem/simple.demo.wbitt.com](https://github.com/KamranAzeem/simple.demo.wbitt.com)
* A simple WordPress website [https://github.com/KamranAzeem/testblog.demo.wbitt.com](https://github.com/KamranAzeem/testblog.demo.wbitt.com)


### A simple static HTML website:
The simple static/HTML website has the following properties:

* Site name: `simple.demo.wbitt.com` , which points to the IP address of `web.witpass.co.uk` where all our wordpress based websites are running as docker containers.
* This website has static HTML content and builds a nginx based docker image at the time of start-up.
* One (imaginary) requirement is that the resulting docker image should be a private image. So this will need to be stored inside a private container repository. On GCP this is easily achievable. 
* This site does not need any secrets, so it does not use any environment variables.
* This site does not need to store any state in any database
* This site does not need to store any state on file-system
* This site uses a configuration file for it's internal use, and expects it at a location `/config/site.conf` on the file system of the running container.

**Note:** I know this is a simple/static/HTML file, and it does not need a config file. This (config file thing) is completely made-up, because I want to demonstrate something important around this, when we move this to Kubernetes. So there is no harm in assuming that there is a config file.

| ![images/simplesite.png](images/simplesite.png) |
| ----------------------------------------------- |


### A simple Wordpress website:
The WordPress website has the following properties:

* Site name: `testblog.demo.wbitt.com` , which points to the IP address of `web.witpass.co.uk` where all our wordpress based websites are running as docker containers.
* This website used an existing/official Wordpress docker image: `wordpress:latest`
* The `testblog.env` file is used to provide secrets (DB access details) to the WordPress image at run time.
* Site's **DB state** is saved in a database created manually in the database server: `db.witpass.co.uk`. Internally known as `db.aws.witpass.co.uk`
* Site's **File/disk state** is saved under a directory: `/home/containers-data/testblog.demo.wbitt.com/`. This is where all the wordpress software, uploads, and plugins, etc, are saved.

**Note:** I personally dislike the idea of storing entire wordpress installation as a **state**, and that is why I created a custom wordpress image, which only saves the state of `uploads`, and nothing else. This is a separate topic. The improved version of the wordpress image I just mentioned is here: [https://github.com/WITPASS/witpass-wordpress-docker-image](https://github.com/WITPASS/witpass-wordpress-docker-image)

| ![images/testblog.png](images/testblog.png) |
| ------------------------------------------- |


## Kubernetes setup:

To move our applications to Kubernetes, we would need to ensure that the individual needs of these applications are met. Certain things need to be in place. These are discussed next.

### The database service:
In current setup we have a single database server running three different database software. Currently all applications connect to this database server on desired ports. We can have a similar setup in a slightly different way on Kubernetes. We can have three individual database services running as three separate"StatefulSet". This helps the database software to save it's state in a disk volume acquired using a "PersistentVolumeClaimTemplate". So MySQL , Postgres and MongoDB can have their individual StatefulSets. 

Lets talk about MySQL only. In Kubernetes terms, the MySQL instance needs:

* to be a StatefulSet object instead of Deployment. 
* a publicly accessible docker container image. This will be `mysql:5.7` in our case.
* a disk volume to save it's data files. This will be a PVC of size 10 GB - for now.
* a secret (`MYSQL_ROOT_PASSWORD`), which will be used by the MySQL image to setup the MySQL instance correctly at first boot. 
* an internal/cluster service, so MySQL is accessible to all the services wishing to connect to it, within the same namespace.
* a way to be accessible / used by the admin from the internet, to be able to create databases and users for various applications / websites. For this, we would setup a very small and secure web interface for mysql, named `Adminer`. This Adminer software will have a "Deployment", a "Service" and an "Ingress", so we can access it from the internet. 

**Note:** The database service will be setup by the main cluster administrator, and will be a one time activity. Though the process of creation of this service can be defined / saved as a github repository , in the form of `yaml` files. This does not need to be part of a CI/CD pipeline.

### The ingress controller:
Since the Adminer interface needs to be accessed over the internet, we already defined an ingress object for it. But for Ingress object to work, we need an Ingress-Controller. The ingress controller will be a service defined as `type: LoadBalancer`. Just like in the docker-compose setup, we have Traefik running as the ingress controller - sort of, we will use Traefik as Ingress controller in this situation as well. 

**Note:** The setup of Ingress Controller will also be a one time activity by the administrator.

### The individual applications:
Now we discuss the Kubernetes related needs of our applications. This is where developers will have the main interest, and they will have the main responsibility for deploying their applications on the cluster.

#### The WordPress application will have the following Kubernetes related needs:
* It needs to be a "Deployment" , so we can scale up (and down) the number of replicas, depending on the load, which still able to serve the files on the (shared) disk from all the instances. This is only possible when you use a Deployment object, and not StatefulSet.
* The Deployment will need an image. In this case, it uses a publicly available docker container image, so that is not a problem.
* The Deployment will need to know the location of MySQL database server, the DB for this wordpress installation , the DB username and passwords to connect to that database. This information cannot be part of the repository, so it is provided manually on the docker servers as `wordpress.env` file (as an example). On Kubernetes this information needs to be provided as environment variables as well. The question is, how? There are two ways. One, we create the secret manually from command line. The other way way is to setup the secrets as environment variables in the CI server. We will be using CircleCI for our CI/CD needs. We will see both methods to get this done. 
* The Deployment will also need a persistent storage for storing various files this wordpress software will create. The same location will also hold any content uploaded by the user, for example pictures, etc. This will be a PVC, and will be created separately. IT's definition of creation will not be part of the same file as the `deployment.yaml` . This to prevent any accidents of old PVCs being deleted and new ones being created automatically resulting in data loss. This problem has been explain in another article of mine: [https://github.com/KamranAzeem/kubernetes-katas/blob/master/08-storage-basic-dynamic-provisioning.md](https://github.com/KamranAzeem/kubernetes-katas/blob/master/08-storage-basic-dynamic-provisioning.md) . Anyhow, the developer will be required to create the necessary PV/PVC once, and then make sure to **never delete the PVC**. Till the time the PVC is there, the data will be safe. 

**Note:** This example uses with wordpress, which is quite "stateful". What we want, from the developers is: applications as stateless as possible. i.e. There should be no involvement of saving any state, eliminating a need to acquire and maintain PVCs and PVs, even the database. **This is very important in application design.** 

#### The simple static/HTML site has the following Kubernetes related needs:
* It needs to be a "Deployment" , so we can scale up (and down) the number of replicas, depending on the load, which still able to serve the files on the (shared) disk from all the instances. This is only possible when you use a Deployment object, and not StatefulSet.
* The Deployment will need to build a private image, which is impossible. Kubernetes objects cannot build container images. (Recall: Kubernetes != Docker). So, for this to work, the image needs to be built outside/before the deployment process is carried out. IF the image needs to be a private image, then GCP's gcr.io is ideal, as it can create private container images without doing any extra steps. 
* The Deployment will also need a (imaginary) configuration file mounted at `/config/site.conf` . One can argue that a configuration file (or files) can be baked into the image itself. For the sake of this example, we will create a config map everytime before creating the main deployment. This can be done manually, or through the CI server. In case of CI server, the entire configuration file will need to be stored an an environment variable in the CI server and then be used inside the deployment pipeline. We will show you that too.


## Kubernetes setup:

We have a GCP/GKE cluster. We will first deploy the wordpress based application to Kubernetes. To be able to deploy that, we would need to perform the following steps, in order:

* Deploy MySQL as StatefulSet, and create related service
* Deploy Adminer as Deployment, and create its related service and ingress
* Deploy Traefik Ingress Controller, and create it's related service as `type:LoadBalancer` and obtain the public IP. Traefik will be deployed in the very basic form without HTTPS , because this is just a demo, and HTTPS is simply beyond the scope. If you are interested, please consult: [https://github.com/KamranAzeem/kubernetes-katas/tree/master/ingress-traefik/https-letsencrypt-HTTP-Challenge](https://github.com/KamranAzeem/kubernetes-katas/tree/master/ingress-traefik/https-letsencrypt-HTTP-Challenge)
* Modify our DNS zone for `demo.wbitt.com` and add an entry for `k8s.demo.wbitt.com` and point it to this public IP obtained in the previous step
* Add another CNAME entry in the same DNS zone for `adminer.demo.wbitt.com` pointing to `k8s.demo.wbitt.com`
* Verify that Adminer can connect to the backend MySQL server by using the user root, and the password set as ENV variable for mysql
* Once Adminer is connected, create a database, user and password for the wordpress application which we need to migrate.
* If you want to setup fresh WordPress instance, and don't want to bother with backups and restores, then the next steps are easy.
* Create a PV and PVC for the wordpress database.
* Create the secrets for connecting the wordpress Deployment to the MySQL instance, and make sure that the wordpress deployment is configured to uses those secrets.
* Stop the related wordpress docker-compose application on the docker server. This will ensure that when you change it's IP address in next steps, Traefik will not panic in trying to arrange SSL certificates for it.
* In the DNS server, point `testblog.demo.wbitt.com` to `k8s.demo.wbitt.com`
* Deploy the wordpress deployment, service and ingress. Once successful, try accessing the site using `testblog.demo.wbitt.com`.


If you want to actually migrate the MySQL database and the software files for this wordpress application from docker server to Kubernetes, there are some extra steps:

* Perform a database dump of the existing MySQL database of this wordpress website from the old server, and copy the file to your local work computer. 
* Load the database dump in the new database through adminer.
* Make a tarball/zip/etc of the web content of this wordpress website, and copy it to your local work computer. Then, setup a small test deployment , which simply runs a multitool, and mounts this PVC onto a mount point. 
* Once the multitool deployment is up and running, use `kubectl cp ...` command to copy the tarfile inside the multiool container , inside that PVC, and untar the files. Make sure you change ownership of all files to a user which the webserver will run as (probably UID 33, GID 33). 
* Once complete, stop the  multitool container and start the actual wordpress container. Since both the database and other upload files are already there, this wordpress instance should start without any problem, showing the correct blog page and showing the media/pictures attached with this blog post.







