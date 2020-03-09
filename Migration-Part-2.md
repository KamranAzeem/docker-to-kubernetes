# Using CircleCI as CD (Continuous Delivery) server to deploy applications on Kubernetes:

This is part 2 of the Docker to Kubernetes migration. In this part, I am going to use another example of a simple web application, which does not maintain state, but it builds it's private image every time. This example is suitable to explain the concepts of CD, especially on GCP.

**Note:** This document does not cover the CI (Continuous Integration) aspect of application development. That is a topic for later.

The CD server of our choice is CircleCI. 

The repository used is:
* https://github.com/KamranAzeem/simpleapp.demo.wbitt.com

## Analysis of existing application:
This simple web application was running as a docker-compose application on a production server. We are moving it to Kubernetes. The first step is to make sure that the DNS is updated, which means that `simpleapp.demo.wbitt.com` points to the IP address of our Traefik load balancer.

```
[kamran@kworkhorse docker-to-kubernetes]$ dig simpleapp.demo.wbitt.com

;; QUESTION SECTION:
;simpleapp.demo.wbitt.com.		IN	A

;; ANSWER SECTION:
simpleapp.demo.wbitt.com.	299	IN	CNAME	traefik.demo.wbitt.com.
traefik.demo.wbitt.com.	299	IN	A	35.228.250.6

[kamran@kworkhorse docker-to-kubernetes]$
```

Examine the existing `docker-compose.server.yml` file for this application:
```
version: "3"
services:
  simpleapp.demo.wbitt.com:

    build: .

    labels:
      - traefik.enable=true
      - traefik.port=80
      - traefik.frontend.rule=Host:simpleapp.demo.wbitt.com

    volumes:
      - ${PWD}/simpleapp.conf:/config/simpleapp.conf

    env_file:
    - simpleapp.env

    networks:
      - services-network

networks:
  services-network:
    external: true
```

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ cat simpleapp.env 
MYSQL_HOST=db.aws.witpass.co.uk
MYSQL_DATABASE=simpleapp_demo_wbitt_com
MYSQL_USER=simpleapp_demo_wbitt_com
MYSQL_PASSWORD=zxSVgF9OC7O3bCOqsLOe4Q==
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```


From the docker-compose file, we have gathered the following facts:

* The application runs as `simpleapp.demo.wbitt.com`. This can be handled by defining an **Ingress** object in Kubernetes.
* This application "builds" its image every time it runs. i.e. It does not use a pre-built image. This is going to be a problem when we move this to Kubernetes. Kubernetes does not allow building an image on-the-fly. Instead, Kubernetes expects the container image to exist before it is used in the pod/container. We will handle this by always **creating a docker image through a CircleCI**, on each commit to the repository, and **push that image to Google's container registry `gcr.io`**. That way before we run the application as a deployment, the container image will be available.
* It mounts a (bogus) configuration file under `/config/simpleapp.conf` . This can be handled by creating a **configmap** of this configuration file. 
* Certain files in this application uses a database connection to MySQL server. To get this to work in Kubernetes, we need to pass some ENV variables as **secret**. 
* It connects to an external network. This network is actually the network on which Traefik is configured to serve. In Kubernetes, this is not needed. 



Here is the `Dockerfile` which is used to build the image:

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ cat Dockerfile 
FROM php:7-apache
COPY htdocs/ /var/www/html/
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

Below is an `index.html` file from the `htdocs` directory. This file will experience constant changes during this exercise, resulting in a need to re-create the related docker image on each commit. I will simply append a new line of bogus text in this file to represent change in the repository , or "change in application", so to speak.

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ cat htdocs/index.html 
<h1>Simple website - This is index.html!</h1>
<hr>
<a href=index.php>index.php</a><br>
<a href=phpinfo.php>phpinfo.php</a><br>
<a href=createfile.php>createfile.php</a><br>
<a href=dbconnection.php>dbconnection.php</a><br>
<hr>
``` 



The biggest hurdle in such applications is to create the image. The problem is that even if the image is a public image, we would not know what is the tag/version number of the latest image. The work around is to (a) always use `latest` , or (b) create/assign version numbers yourself and assign them as tags to the image. Doing any of (a) or (b) is **not** recommended. This means, we would definitely need to involve CircleCI for this. 


## Prepare to deploy on Kubernetes - manually:

To test things first, I will show you the manual way of creating this deployment. For this I will "risk" creating a public docker image. "Risk" because in our hypothesis, this application is sensitive in nature, and it's image cannot exist on public internet. Anyhow, for ease of understanding, lets create the image and store it as a public docker image. This is just an example - right!

### Create docker image for SimpleApp:
Create a docker image and save it as a public image on docker hub. 

Build the image:
```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ docker build  -t kamranazeem/simpleapp:php-7-apache-2.4 .
Sending build context to Docker daemon  100.4kB
Step 1/2 : FROM php:7-apache
 ---> d753d5b380a1
Step 2/2 : COPY htdocs/ /var/www/html/
 ---> Using cache
 ---> 056524a540f8
Successfully built 056524a540f8
Successfully tagged kamranazeem/simpleapp:php-7-apache-2.4
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

Push to docker hub:
```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ docker push kamranazeem/simpleapp:php-7-apache-2.4
The push refers to repository [docker.io/kamranazeem/simpleapp]
f0f442497cc4: Pushed 
a616f8ab5356: Mounted from kamranazeem/php 
079d43545924: Mounted from kamranazeem/php 
d97484483f49: Mounted from kamranazeem/php 
b242745ebda2: Mounted from kamranazeem/php 
d0d3b2f87351: Mounted from kamranazeem/php 
be73e3c8f219: Mounted from kamranazeem/php 
0fc284fc9cf5: Mounted from kamranazeem/php 
732057c800a3: Mounted from kamranazeem/php 
4cc11613548d: Mounted from kamranazeem/php 
df6c050501b6: Mounted from kamranazeem/php 
b4bfb20b5f05: Mounted from kamranazeem/php 
2e8cc9f5313f: Mounted from kamranazeem/php 
f2cb0ecef392: Mounted from kamranazeem/php 
php-7-apache-2.4: digest: sha256:a5cdf1339c75106d5d1cf9d98d56230d382fac81e3241c245fceae156b77f826 size: 3243
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

Alright, just so you know , for now our image is: `kamranazeem/simpleapp:php-7-apache-2.4` . The naming is not very practical, but I will come to that later. 


### Create configmap:

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ cat simpleapp.conf 
dir=/home
user=someone
demo=true
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ ./create-simpleapp-configmap.sh 
First, deleting the old configmap: configmap-simpleapp-conf
Error from server (NotFound): configmaps "configmap-simpleapp-conf" not found

Creating the new configmap: configmap-simpleapp-conf
configmap/configmap-simpleapp-conf created
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

### Create secret:
We know that the name of mysql service in our kubernetes cluster is `mysql`, so we need to adjust the `simpleapp.env` file before we create a secret for it:

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ cat simpleapp.env 
MYSQL_HOST=mysql
MYSQL_DATABASE=simpleapp_demo_wbitt_com
MYSQL_USER=simpleapp_demo_wbitt_com
MYSQL_PASSWORD=zxSVgF9OC7O3bCOqsLOe4Q==
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

Create the secret:
```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ ./create-simpleapp-credentials.sh 
First, deleting the old secret: simpleapp-credentials
Error from server (NotFound): secrets "simpleapp-credentials" not found
Found simpleapp.env file, creating kubernetes secret: simpleapp-credentials
secret/simpleapp-credentials created
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

Verify:
```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get configmap
NAME                       DATA   AGE
configmap-simpleapp-conf   1      94s


[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get secret
NAME                    TYPE                                  DATA   AGE
default-token-5hdzn     kubernetes.io/service-account-token   3      29h
mysql-credentials       Opaque                                1      26h
simpleapp-credentials   Opaque                                4      41s
simpleapp-credentials   Opaque                                4      24h
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

### Deploy the application:

Here is the deployment.yaml file for the same simpleapp, now in Kubernetes format - with some additional features.

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ cat deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simpleapp
  labels:
    app: simpleapp
spec:
  selector:
    matchLabels:
      app: simpleapp
      tier: frontend
  template:
    metadata:
      labels:
        app: simpleapp
        tier: frontend
    spec:
      containers:
      - name: simpleapp
        image: kamranazeem/simpleapp:php-7-apache-2.4
        env:
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: simpleapp-credentials
              key: MYSQL_HOST
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: simpleapp-credentials
              key: MYSQL_DATABASE
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: simpleapp-credentials
              key: MYSQL_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: simpleapp-credentials
              key: MYSQL_PASSWORD

        ports:
        - containerPort: 80

        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 5m
            memory: 10Mi

        volumeMounts:
        - mountPath: "/config/"
          name: vol-simpleapp-conf

      volumes:
      - name: vol-simpleapp-conf
        configMap:
          name: configmap-simpleapp-conf

[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

We also need a service and ingress for this deployment. This is a separate file, as we don't expect service and ingress definition to change constantly. Though this can be part of the main `deployment.yaml` file without any harm.

```
[kamran@kworkhorse docker-to-kubernetes]$ cat simpleapp-service-ingress.yaml 

apiVersion: v1
kind: Service
metadata:
  name: simpleapp
  labels:
    app: simpleapp
spec:
  ports:
    - port: 80
  selector:
    app: simpleapp
    tier: frontend
  type: ClusterIP

---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: simpleapp
spec:
  rules:
  - host: simpleapp.demo.wbitt.com
    http:
      paths:
      - path: /
        backend:
          serviceName: simpleapp
          servicePort: 80

[kamran@kworkhorse docker-to-kubernetes]$ 
```

Deploy the application:

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl apply -f deployment.yaml
deployment.apps/simpleapp-deployment created


[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
mysql-0                                 1/1     Running   0          26h
simpleapp-deployment-5d7dc79f7c-ctqx8   1/1     Running   0          71s
testblog-54f855f697-5qdmz               1/1     Running   0          24h
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

Setup service and ingress:
```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl apply -f service-ingress.yaml 
service/simpleapp created
ingress.extensions/simpleapp created
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```


Verify:
```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
simpleapp   1/1     1            1           81s
testblog    1/1     1            1           25h


[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get services
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.0.0.1      <none>        443/TCP    29h
mysql        ClusterIP   None          <none>        3306/TCP   26h
simpleapp    ClusterIP   10.0.14.240   <none>        80/TCP     58s
testblog     ClusterIP   10.0.14.118   <none>        80/TCP     25h


[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get endpoints
NAME         ENDPOINTS           AGE
kubernetes   35.228.53.139:443   29h
mysql        10.32.0.14:3306     26h
simpleapp    10.32.0.20:80       66s
testblog     10.32.0.17:80       25h


[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get ingress
NAME        HOSTS                      ADDRESS   PORTS   AGE
simpleapp   simpleapp.demo.wbitt.com             80      70s
testblog    testblog.demo.wbitt.com              80      25h
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

Here are some screenshots:

| ![images/traefik-with-simpleapp.png](images/traefik-with-simpleapp.png) |
| --------------------------------------------------------- |


| ![images/simpleapp-main-page.png](images/simpleapp-main-page.png) |
| ----------------------------------------------------------------- |


| ![images/simpleapp-php-dbconnection.png](images/simpleapp-php-dbconnection.png) |
| ------------------------------------------------------------------------------- |


**It works!**

------


## Prepare to deploy on Kubernetes - through CircleCI:

### Add service account under IAM & Admin - for GCR and GKE access:

Create a new service account named "circleci-access" under "IAM & Admin"

Give some access Roles to this newly created service account. For example's sake we will use a bit relaxed permissions:
* Storage/Storage Admin
* Kubernetes Engine/Kubernetes Engine Developer


After setting permissions, create a key for this service account, by using "Create Key" button on next screen. Use type JSON. The key will download immediately to your computer, only once. Make a note of it's location. Keep it safe.


| ![images/ci_1.png](images/ci_1.png) |
| ----------------------------------- |

| ![images/ci_2.png](images/ci_2.png) |
| ----------------------------------- |

| ![images/ci_3.png](images/ci_3.png) |
| ----------------------------------- |

| ![images/ci_4.png](images/ci_4.png) |
| ----------------------------------- |

| ![images/ci_5.png](images/ci_5.png) |
| ----------------------------------- |

| ![images/ci_6.png](images/ci_6.png) |
| ----------------------------------- |


Find the JSON file, and `cat` it on the terminal. Leave this here as it is, until we setup CircleCI.

| ![images/ci_8.png](images/ci_8.png) |
| ----------------------------------- |

You also need to know ID of the current GKE project, which you can obtain by simply visiting the Home section of the current project. The Project ID is listed over there. For my project, the id is: `trainingvideos` .


### Add new CircleCI project:
We start by setting up a new CircleCI project in CircleCI web interface. Click "Add Project" on left pane, and connect this repository to that project.


Select "Start Building". Select "Add Manually" on next screen. Click "Start Building" again on yet another screen. No need to download the `.circleci/config.yml`, because we are going to create it manually. Note that the first build **"will fail"**. That is ok.

| ![images/ci-start-build-1.png](images/ci-start-build-1.png) |
| ----------------------------------------------------------- |


| ![images/ci-start-build-2.png](images/ci-start-build-2.png) |
| ----------------------------------------------------------- |


| ![images/ci-start-build-3.png](images/ci-start-build-3.png) |
| ----------------------------------------------------------- |


| ![images/ci-start-build-4.png](images/ci-start-build-4.png) |
| ----------------------------------------------------------- |


We setup `GCLOUD_CREDENTIALS	` as environment variable . In the Project settings of this project, go to Environment variables, and add an environment variable called `GCLOUD_CREDENTIALS`. Copy the text of the `JSON` file from the text terminal and paste it in as a value for this variable.

| ![images/ci_8.png](images/ci_8.png) |
| ----------------------------------- |

| ![images/ci_7.png](images/ci_7.png) |
| ----------------------------------- |


We need to configure `.circleci/config.yml` to do the following:
* create and push a container image to GCR
* create necessary configmap
* create necessary secret
* deploy our application as a deployment
* create related service and ingress objects 


The `deployment.yaml` file expects an image name and tag. But remember, we can never know the tag/hash of the image in advance. The image will always be created by circleCI as part of a pipeline-job, and therefore we can't have a fixed image tag/hah in the `deployment.yaml` file. We must use some sort of "template" file, which will have only a "place-holder" for the image tag/hash. We will replace the placeholder with the actual value of the image tag/hash while processing it through CircleCI.

To be able to deploy any objects in Kubernetes cluster, you will need to connect to it through CircleCI. So we need a connection string   - so to speak, which will create a `.kube/config` inside the CircleCI environment. We obtain that by choosing to connect to the cluster, which shows us the correct command.

| ![images/ci_9.png](images/ci_9.png) |
| ----------------------------------- |


Create CircleCI environment variables for our fictional configuration file and the `MYSQL_*` environment variables.


| ![images/ci_10.png](images/ci_10.png) |
| ----------------------------------- |

| ![images/ci_11.png](images/ci_11.png) |
| ----------------------------------- |

| ![images/ci_12.png](images/ci_12.png) |
| ----------------------------------- |

| ![images/ci_13.png](images/ci_13.png) |
| ----------------------------------- |

| ![images/ci_14.png](images/ci_14.png) |
| ----------------------------------- |

| ![images/ci_15.png](images/ci_15.png) |
| ----------------------------------- |

| ![images/ci_16.png](images/ci_16.png) |
| ----------------------------------- |


Update `.circleci/config.yml` to use these environment variables as needed. Then, push this updated `.circleci/config.yml` to the repository. CircleCI will see the change and will start processing it. You will notice a "workflow" showing up in CircleCI web interface.


At this point, CircleCI will perform all the steps configured in it's `config.yml` file. Configmap will be (re)created, Secret will be (re)created, application will be deployed as a Deployment, and related Service and Ingress objects will be created.

| ![images/ci_22.png](images/ci_22.png) |
| ------------------------------------- |

| ![images/ci_23.png](images/ci_23.png) |
| ------------------------------------- |


Here is the complete `.circleci/config.yml` file:

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ cat .circleci/config.yml | grep -v ^$
version: 2
jobs:
  build:
    docker:
      - image: google/cloud-sdk
    steps: 
      - run: 
          name: authenticate with gcloud
          command: |
            echo $GCLOUD_CREDENTIALS > ${HOME}/gcloud-service-key.json
            gcloud auth activate-service-account --key-file=${HOME}/gcloud-service-key.json
      - checkout             
      - setup_remote_docker
      - run: |
          gcloud auth configure-docker --quiet
          SHORT_HASH=$(echo $CIRCLE_SHA1 | cut -c -7)      
          docker build -t eu.gcr.io/trainingvideos/simpleapp:${SHORT_HASH} .
          docker push eu.gcr.io/trainingvideos/simpleapp:${SHORT_HASH}
  deploy:
    docker:
      - image: google/cloud-sdk  
    steps: 
      - run: 
          name: authenticate with gcloud
          command: |
            echo $GCLOUD_CREDENTIALS > ${HOME}/gcloud-service-key.json
            gcloud auth activate-service-account --key-file=${HOME}/gcloud-service-key.json
            gcloud container clusters get-credentials docker-to-k8s --zone europe-north1-a --project trainingvideos
      - checkout             
      - run: |
          echo ${SIMPLEAPP_CONF} > simpleapp.conf
          echo "First, deleting the old configmap: configmap-simpleapp-conf"
          kubectl delete configmap configmap-simpleapp-conf || true
          echo "Creating the new configmap: configmap-simpleapp-conf - using CircleCI environment variable"
          kubectl create  configmap configmap-simpleapp-conf --from-file=simpleapp.conf
          echo "First, deleting the old secret: simpleapp-credentials"
          kubectl delete secret simpleapp-credentials || true
          echo "Creating kubernetes secret: simpleapp-credentials - using CircleCI Environment variables"
          kubectl create secret generic simpleapp-credentials \
            --from-literal=MYSQL_HOST=${MYSQL_HOST} \
            --from-literal=MYSQL_DATABASE=${MYSQL_DATABASE} \
            --from-literal=MYSQL_USER=${MYSQL_USER} \
            --from-literal=MYSQL_PASSWORD=${MYSQL_PASSWORD}
          SHORT_HASH=$(echo $CIRCLE_SHA1 | cut -c -7)      
          echo "SHORT_HASH is: ${SHORT_HASH}"
          sed  s/SHORT_HASH/$SHORT_HASH/ deployment.yaml.template > deployment.yaml
          kubectl apply -f deployment.yaml 
          kubectl apply -f service-ingress.yaml
workflows:
  version: 2
  build-and-deploy:
    jobs: 
      - build:
          filters:
            branches: 
              only: master
      - deploy:
          requires:
            - build
          filters:
            branches: 
              only: master
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

After successful run you see the objects in Kubernetes:

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
simpleapp   1/1     1            1           60s
testblog    1/1     1            1           27h


[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
mysql-0                      1/1     Running   0          28h
simpleapp-5656d7cd44-g49zf   1/1     Running   0          68s
testblog-54f855f697-5qdmz    1/1     Running   0          26h
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```


| ![images/ci_24.png](images/ci_24.png) |
| ------------------------------------- |


| ![images/ci_25.png](images/ci_25.png) |
| ------------------------------------- |


As an experiment, add one line to `index.html` file indicating a new version of the application - so to speak. You will see new job kicks in:

```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ vi htdocs/index.html 

[kamran@kworkhorse simpleapp.demo.wbitt.com]$ git add htdocs/index.html 

[kamran@kworkhorse simpleapp.demo.wbitt.com]$ git commit -m "added first extra line in index.html"
[master 52cfc76] added first extra line in index.html
 1 file changed, 2 insertions(+)

[kamran@kworkhorse simpleapp.demo.wbitt.com]$ git push
Enumerating objects: 7, done.
. . . 
a09acc1..52cfc76  master -> master
[kamran@kworkhorse simpleapp.demo.wbitt.com]$
```

| ![images/ci_26.png](images/ci_26.png) |
| ------------------------------------- |

| ![images/ci_27.png](images/ci_27.png) |
| ------------------------------------- |

| ![images/ci_28.png](images/ci_28.png) |
| ------------------------------------- |

| ![images/ci_29.png](images/ci_29.png) |
| ------------------------------------- |


Since the image has changed, the new deployment will cause the previous pod to terminate and start a new one. 
```
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ kubectl get pods
NAME                         READY   STATUS        RESTARTS   AGE
mysql-0                      1/1     Running       0          28h
simpleapp-5656d7cd44-g49zf   1/1     Terminating   0          6m22s
simpleapp-8678c76c9d-bm8st   1/1     Running       0          21s
testblog-54f855f697-5qdmz    1/1     Running       0          26h
[kamran@kworkhorse simpleapp.demo.wbitt.com]$ 
```

Notice that the change we introduced in our `index.html` is now visible on the web!

| ![images/ci_29.png](images/ci_29.png) |
| ------------------------------------- |

So, **It works!**

There you have it, your application being deployed continuously using CircleCI.

(End of Part 2.)

