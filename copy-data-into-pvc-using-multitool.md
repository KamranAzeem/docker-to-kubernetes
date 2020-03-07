[kamran@kworkhorse kubernetes]$ cat wordpress-pvc.yaml 
# We need a PVC to hold Wordpresss software, and everything that the user uploads.

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-testblog
  labels:
    app: testblog
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

[kamran@kworkhorse kubernetes]$ kubectl get pvc
NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-persistent-storage-mysql-0   Bound    pvc-fba03b2b-5a24-11ea-b989-42010aa600d8   1Gi        RWO            standard       10h

[kamran@kworkhorse kubernetes]$ kubectl create -f wordpress-pvc.yaml 
persistentvolumeclaim/pvc-testblog created

[kamran@kworkhorse kubernetes]$ kubectl get pvc
NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-persistent-storage-mysql-0   Bound    pvc-fba03b2b-5a24-11ea-b989-42010aa600d8   1Gi        RWO            standard       10h
pvc-testblog                       Bound    pvc-66a5075f-5a7e-11ea-b989-42010aa600d8   1Gi        RWO            standard       16s

[kamran@kworkhorse kubernetes]$ vi multitool-deployment.yaml 

[kamran@kworkhorse kubernetes]$ kubectl create -f multitool-deployment.yaml 
deployment.apps/multitool created

[kamran@kworkhorse kubernetes]$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
dbadmin-6d9f486579-ftxgq    1/1     Running   0          15m
multitool-69c96669b-phnq6   1/1     Running   0          20s
mysql-0                     1/1     Running   0          10h
tomcat-75795ddf7-htjj7      1/1     Running   0          39m
[kamran@kworkhorse kubernetes]$ 


[kamran@kworkhorse kubernetes]$ kubectl exec -it multitool-69c96669b-phnq6 bash
bash-5.0# df -hT
Filesystem           Type            Size      Used Available Use% Mounted on
overlay              overlay        94.3G      5.4G     88.9G   6% /
tmpfs                tmpfs          64.0M         0     64.0M   0% /dev
tmpfs                tmpfs           1.8G         0      1.8G   0% /sys/fs/cgroup
/dev/sda1            ext4           94.3G      5.4G     88.9G   6% /dev/termination-log
/dev/sdc             ext4          975.9M      2.5M    957.4M   0% /mnt/data              <----------- This one!
/dev/sda1            ext4           94.3G      5.4G     88.9G   6% /etc/resolv.conf
/dev/sda1            ext4           94.3G      5.4G     88.9G   6% /etc/hostname
/dev/sda1            ext4           94.3G      5.4G     88.9G   6% /etc/hosts
shm                  tmpfs          64.0M         0     64.0M   0% /dev/shm
tmpfs                tmpfs           1.8G     12.0K      1.8G   0% /run/secrets/kubernetes.io/serviceaccount
tmpfs                tmpfs           1.8G         0      1.8G   0% /proc/acpi
tmpfs                tmpfs          64.0M         0     64.0M   0% /proc/kcore
tmpfs                tmpfs          64.0M         0     64.0M   0% /proc/keys
tmpfs                tmpfs          64.0M         0     64.0M   0% /proc/timer_list
tmpfs                tmpfs           1.8G         0      1.8G   0% /proc/scsi
tmpfs                tmpfs           1.8G         0      1.8G   0% /sys/firmware
bash-5.0# 

[kamran@kworkhorse docker-to-kubernetes-data]$ ls
testblog.demo.wbitt.com.tar.gz
[kamran@kworkhorse docker-to-kubernetes-data]$ kubectl cp testblog.demo.wbitt.com.tar.gz multitool-69c96669b-phnq6:/mnt/data/


[kamran@kworkhorse kubernetes]$ kubectl exec -it multitool-69c96669b-phnq6 bash
bash-5.0# cd /mnt/data/
bash-5.0# ls -l
total 12360
drwx------    2 root     root         16384 Feb 28 23:03 lost+found
-rw-r--r--    1 1000     1000      12637119 Feb 28 12:54 testblog.demo.wbitt.com.tar.gz
bash-5.0# 


[kamran@kworkhorse kubernetes]$ kubectl exec -it multitool-69c96669b-phnq6 bash
bash-5.0# cd /mnt/data/
bash-5.0# ls -l
total 12360
drwx------    2 root     root         16384 Feb 28 23:03 lost+found
-rw-r--r--    1 1000     1000      12637119 Feb 28 12:54 testblog.demo.wbitt.com.tar.gz
bash-5.0# tar xzf testblog.demo.wbitt.com.tar.gz 

bash-5.0# ls -l
total 12572
-rw-r--r--    1 1001     1001           420 Nov 30  2017 index.php
-rw-r--r--    1 1001     1001         19935 Jan  1  2019 license.txt
drwx------    2 root     root         16384 Feb 28 23:03 lost+found
-rw-r--r--    1 1001     1001          7368 Sep  2 21:44 readme.html
-rw-r--r--    1 1000     1000      12637119 Feb 28 12:54 testblog.demo.wbitt.com.tar.gz
-rw-r--r--    1 1001     1001          6939 Sep  3 00:41 wp-activate.php
drwxr-xr-x    9 1001     1001          4096 Feb 28 23:07 wp-admin
-rw-r--r--    1 1001     1001           369 Nov 30  2017 wp-blog-header.php
-rw-r--r--    1 1001     1001          2283 Jan 21  2019 wp-comments-post.php
-rw-r--r--    1 1001     1001          2808 Feb 28 01:25 wp-config-sample.php
-rw-r--r--    1 1001     1001          3248 Feb 28 01:25 wp-config.php
drwxr-xr-x    5 1001     1001          4096 Feb 28 23:09 wp-content
-rw-r--r--    1 1001     1001          3955 Oct 10 22:52 wp-cron.php
drwxr-xr-x   20 1001     1001         12288 Feb 28 23:09 wp-includes
-rw-r--r--    1 1001     1001          2504 Sep  3 00:41 wp-links-opml.php
-rw-r--r--    1 1001     1001          3326 Sep  3 00:41 wp-load.php
-rw-r--r--    1 1001     1001         47597 Dec  9 13:30 wp-login.php
-rw-r--r--    1 1001     1001          8483 Sep  3 00:41 wp-mail.php
-rw-r--r--    1 1001     1001         19120 Oct 15 15:37 wp-settings.php
-rw-r--r--    1 1001     1001         31112 Sep  3 00:41 wp-signup.php
-rw-r--r--    1 1001     1001          4764 Nov 30  2017 wp-trackback.php
-rw-r--r--    1 1001     1001          3150 Jul  1  2019 xmlrpc.php
bash-5.0# rm testblog.demo.wbitt.com.tar.gz 
bash-5.0# 


Note: In the wordpress image, apache process runs as UID:GID 33:33. So fix permissions on all files:    

bash-5.0# chown 33:33 /mnt/data -R
bash-5.0# 

bash-5.0# ls -ln
total 228
-rw-r--r--    1 33       33             420 Nov 30  2017 index.php
-rw-r--r--    1 33       33           19935 Jan  1  2019 license.txt
drwx------    2 33       33           16384 Feb 28 23:03 lost+found
-rw-r--r--    1 33       33            7368 Sep  2 21:44 readme.html
-rw-r--r--    1 33       33            6939 Sep  3 00:41 wp-activate.php
drwxr-xr-x    9 33       33            4096 Feb 28 23:07 wp-admin
-rw-r--r--    1 33       33             369 Nov 30  2017 wp-blog-header.php
-rw-r--r--    1 33       33            2283 Jan 21  2019 wp-comments-post.php
-rw-r--r--    1 33       33            2808 Feb 28 01:25 wp-config-sample.php
-rw-r--r--    1 33       33            3248 Feb 28 01:25 wp-config.php
drwxr-xr-x    5 33       33            4096 Feb 28 23:09 wp-content
-rw-r--r--    1 33       33            3955 Oct 10 22:52 wp-cron.php
drwxr-xr-x   20 33       33           12288 Feb 28 23:09 wp-includes
-rw-r--r--    1 33       33            2504 Sep  3 00:41 wp-links-opml.php
-rw-r--r--    1 33       33            3326 Sep  3 00:41 wp-load.php
-rw-r--r--    1 33       33           47597 Dec  9 13:30 wp-login.php
-rw-r--r--    1 33       33            8483 Sep  3 00:41 wp-mail.php
-rw-r--r--    1 33       33           19120 Oct 15 15:37 wp-settings.php
-rw-r--r--    1 33       33           31112 Sep  3 00:41 wp-signup.php
-rw-r--r--    1 33       33            4764 Nov 30  2017 wp-trackback.php
-rw-r--r--    1 33       33            3150 Jul  1  2019 xmlrpc.php
bash-5.0# 


bash-5.0# exit
exit
[kamran@kworkhorse kubernetes]$ kubectl delete -f multitool-deployment.yaml 
deployment.apps "multitool" deleted
[kamran@kworkhorse kubernetes]$ 


[kamran@kworkhorse kubernetes]$ kubectl get pvc
NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-persistent-storage-mysql-0   Bound    pvc-fba03b2b-5a24-11ea-b989-42010aa600d8   1Gi        RWO            standard       10h
pvc-testblog                       Bound    pvc-66a5075f-5a7e-11ea-b989-42010aa600d8   1Gi        RWO            standard       10m
[kamran@kworkhorse kubernetes]$ 


Create secrets to be used by wordpress-deployment:

[kamran@kworkhorse kubernetes]$ vi wordpress.env 

[kamran@kworkhorse kubernetes]$ ./create-wordpress-credentials.sh 
First delete the old secret: wordpress-credentials
Error from server (NotFound): secrets "wordpress-credentials" not found
Found wordpress.env file, creating kubernetes secret: wordpress-credentials
secret/wordpress-credentials created
[kamran@kworkhorse kubernetes]$ 


[kamran@kworkhorse kubernetes]$ kubectl apply -f wordpress-deployment.yaml 
deployment.apps/testblog unchanged
service/testblog created
ingress.extensions/testblog created
[kamran@kworkhorse kubernetes]$ 


Wordpress did not show the picture in the browser. The blog's text was there! 


[kamran@kworkhorse kubernetes]$ kubectl exec -it testblog-65ff74bd95-zt2qh bash
root@testblog-65ff74bd95-zt2qh:/var/www/html# ls wp-content/uploads/2020/02/767px-Cat_November_2010-1a* -l
-rw-r--r-- 1 www-data www-data   6239 Feb 28 01:35 wp-content/uploads/2020/02/767px-Cat_November_2010-1a-150x150.jpg
-rw-r--r-- 1 www-data www-data  15943 Feb 28 01:35 wp-content/uploads/2020/02/767px-Cat_November_2010-1a-225x300.jpg
-rw-r--r-- 1 www-data www-data 211437 Feb 28 01:35 wp-content/uploads/2020/02/767px-Cat_November_2010-1a.jpg
root@testblog-65ff74bd95-zt2qh:/var/www/html# 


Maybe the site I migrated was HTTPS and on my kubernetes cluster it is not yet HTTPS? May be some urls are still being redrected to https? I tried wp-admin and I could not log in.


Above assumption is correct. The posts table and the main site table has urls with HTTPS instead of HTTP, even the attachement URL was HTTPS. Changed that manually to HTTP and cat showed up! Alhumdulillah


shutdown the cluster! now.









    