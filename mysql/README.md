### Setup MySQL:

The MySQL setup runs a MySQL:5.7 docker container image. This image is capable of creating an additional database (and username and password) if certain environment variables are passed to it . We can very easily use this feature to create a database and related user for our WordPress website, but, we would be moving in more databases from our current/old DB server to this instance. For that reason, creating this addition database (and related user) is not very useful. It is best to setup this database instance using only the `MYSQL_ROOT_PASSWORD`. Later, when we need to create various databases and their related users, we can connect to this instance as the root user, and get all these tasks done. So this would be just like any other regular/normal database instance.

**Note:** In this repository, there is another file named `mysql-statefulset-for-wordpress.yaml` . Use that if all you want to do is run a database instance for a single wordpress website. 

#### Create secret for MySQL:
There is a file in this repository, named `mysql.env`. Update the value for `MYSQL_ROOT_PASSWORD`. Then, use the `create-mysql-credentials.sh` file to create `MYSQL_ROOT_PASSWORD` as a **secret**  in your kubernetes cluster. For the sake of example, everything will be deployed in the `default` namespace.

Create a strong password to be used as `MYSQL_ROOT_PASSWORD` and set it up in `mysql.env` file:
```
[kamran@kworkhorse mysql]$ cat mysql.env
MYSQL_ROOT_PASSWORD=0NNuWqK6YgSrR0CsS8c3aEHR
```

```
[kamran@kworkhorse mysql]$ ./create-mysql-secret.sh 
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

#### Use mysql from inside the container:
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

#### Connect to MySQL from your local computer using port-forward:

Run the following command in a separate terminal window and leave it running.
```
[kamran@kworkhorse mysql]$ kubectl port-forward svc/mysql 3306:3306 
Forwarding from 127.0.0.1:3306 -> 3306
Forwarding from [::1]:3306 -> 3306

(waits forever)
```

Open a new terminal on your local computer, and connect to this port (3306), using `mysql` command. 

```
[kamran@kworkhorse tmp]$ mysql -h 127.0.0.1 -u root -p
Enter password: 


MySQL [(none)]>
```

MySQL running properly. No more to be done about MySQL.


### Setup adminer [OPTIONAL]

This step is completely un-necessary for most setups. I strongly discourage exposing your database instance to the entire world through a web interface such as `adminer` or `phpmyadmin`, etc.

Still, if some setup requires it, then the steps to set it up are provided below:

(To do)


Now, we move forward to migrating our first application to this Kubernetes cluster. The steps to do that are here: [Migration-Part-2.md](Migration-Part-2.md)

# Additional Notes:
* To generate random passwords, I use: `openssl rand -base64 18`. I have set it up as an alias in my `~/.bashrc` as: `alias generate_random_16='openssl rand -base64 18'`
