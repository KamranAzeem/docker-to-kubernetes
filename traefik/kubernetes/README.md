### Create a configmap for `traefik.toml`:

```
$ kubectl  --namespace=kube-system  create configmap configmap-traefik-toml --from-file=traefik.toml
configmap/configmap-traefik-toml created
```

### Create a secret for Traefik's dashboard users:
First, create the password file, using the `htpasswd` utility on your local computer. If you don't have that on your local computer, the
re are many online (web-based) tools, which will create this file for you.

```
$ htpasswd -c -b dashboard-users.htpasswd admin secretpassword
Adding password for user admin
```

* The file name is: `dashboard-users.htpasswd`
* User: `admin`
* Password: `secretpassword`


**Notes:** 
* Default hashing algorithm used by htpasswd for password encryption is MD5.
* Traefik 1.7 does not support SHA-512 and SHA-256 hashes for passwords (the -5 and -2 switch on htpasswd command). If you create a password using these hashes, you will not be able to login to the dashboard. Only MD5 hash works.
* Please use a different and stronger password for your setup.


Create the secret from the password file:
```
$ kubectl  --namespace=kube-system  create secret generic secret-traefik-dashboard-users --from-file=dashboard-users.htpasswd 
secret/secret-traefik-dashboard-users created
```


### Create Traefik RBAC configuration:
First we create the RBAC configuration required by Traefik.

```
$ kubectl apply -f 01-traefik-rbac.yaml
clusterrole.rbac.authorization.k8s.io/traefik-ingress-controller created
clusterrolebinding.rbac.authorization.k8s.io/traefik-ingress-controller created
```


### Create Traefik deployment:

Use the `02-traefik-deployment.yaml` file which we updated in the section above.

```
$ kubectl apply -f 02-traefik-deployment.yaml
serviceaccount/traefik-ingress-controller created
deployment.extensions/traefik-ingress-controller created
persistentvolumeclaim/pvc-traefik-acme-json created
```

### Create Traefik service as LoadBalancer:
```
$ kubectl apply -f 03-traefik-service.yaml 
service/traefik-ingress-service created
```

Wait for the Traefik LoadBalancer acquires an IP from cloud provider. Then, update your DNS, and only after that, go ahead and create Ingress object for Traefik Web UI.

```
$ kubectl --namespace=kube-system get svc
NAME                      TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                                     AGE
default-http-backend      NodePort       10.32.6.133   <none>          80:32355/TCP                                143m
heapster                  ClusterIP      10.32.6.60    <none>          80/TCP                                      143m
kube-dns                  ClusterIP      10.32.0.10    <none>          53/UDP,53/TCP                               143m
metrics-server            ClusterIP      10.32.11.8    <none>          443/TCP                                     143m
traefik-ingress-service   LoadBalancer   10.32.0.120   35.228.129.61   80:31727/TCP,443:31138/TCP,8080:30841/TCP   44s
```
### Create Traefik Web UI:
```
$ kubectl apply -f 04-traefik-webui-service-ingress.yaml 
service/traefik-web-ui created
ingress.extensions/traefik-web-ui created
```


