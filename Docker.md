# Docker Conatiners

Download and run a new Container 

```bash
docker container run --name proxy -d -p 80:80 nginx
```

The above starts a new container nginx which listens to port 80 rediecting from the host 80. `-d` asks the docker to run it in the background.

To enter into `bash` of the container, we need to start with the `-it` argument which runs it in in interactive mode, this will also change the default command that was supposed to run when the container started. In this case we are changing the nginx container to run a bash prompt instead of starting the nginx itself.

```txt
HellsKitchen :: ~ » docker container run -it --name proxy2 -p 80:80 nginx bash

root@bd2ec6a56ee3:/# ls -lrt
total 64
drwxr-xr-x   2 root root 4096 May 13 20:25 home
drwxr-xr-x   2 root root 4096 May 13 20:25 boot
drwxr-xr-x   1 root root 4096 Aug 12 00:00 var
drwxr-xr-x   1 root root 4096 Aug 12 00:00 usr
drwxr-xr-x   2 root root 4096 Aug 12 00:00 srv
drwxr-xr-x   2 root root 4096 Aug 12 00:00 sbin
drwxr-xr-x   3 root root 4096 Aug 12 00:00 run
drwx------   2 root root 4096 Aug 12 00:00 root
drwxr-xr-x   2 root root 4096 Aug 12 00:00 opt
drwxr-xr-x   2 root root 4096 Aug 12 00:00 mnt
drwxr-xr-x   2 root root 4096 Aug 12 00:00 media
drwxr-xr-x   2 root root 4096 Aug 12 00:00 lib64
drwxr-xr-x   2 root root 4096 Aug 12 00:00 bin
drwxr-xr-x   1 root root 4096 Aug 15 21:22 lib
drwxrwxrwt   1 root root 4096 Aug 15 21:22 tmp
dr-xr-xr-x  13 root root    0 Sep 10 16:10 sys
drwxr-xr-x   1 root root 4096 Sep 10 16:29 etc
dr-xr-xr-x 278 root root    0 Sep 10 16:29 proc
drwxr-xr-x   5 root root  360 Sep 10 16:29 dev

root@bd2ec6a56ee3:/# echo $HOSTNAME
bd2ec6a56ee3
```

Since `proxy` is already running, we can't name it as `proxy` so we name it as `proxy2` which will use the already downloaded image for nginx and create a new container and run bash on it. This is not really useful as we generally want to enter an existing container which is running.

We can also see the hostname is now showing the container id instead of local host's name. 

Let's check the list of available containers, running or not running.

```bash
HellsKitchen :: ~ » docker container ls -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                      PORTS               NAMES
f2575c9fc4db        nginx               "nginx -g 'daemon of…"   48 seconds ago      Exited (0) 42 seconds ago                       proxy
bd2ec6a56ee3        nginx               "bash"                   4 minutes ago       Exited (0) 2 minutes ago                        proxy2

HellsKitchen :: ~ » docker container start proxy 
proxy

HellsKitchen :: ~ » docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                NAMES
f2575c9fc4db        nginx               "nginx -g 'daemon of…"   59 seconds ago      Up 5 seconds        0.0.0.0:80->80/tcp   proxy
```

We used the `docker container ls -a` to list all the containers, then started one of the containers, we don't need to tell the container to run in background when using `start` as that is the default behaviour. However when running a new container, it is generally a good idea to use `-d` to detach the container and run it in background.

Let's download a new image and run it in interactive mode `-it`, we are gonna download CentOS latest image

```txt
HellsKitchen :: ~ » docker container run -it --name myserver centos
Unable to find image 'centos:latest' locally
latest: Pulling from library/centos
d8d02d457314: Pull complete 
Digest: sha256:307835c385f656ec2e2fec602cf093224173c51119bbebd602c53c3653a3d6eb
Status: Downloaded newer image for centos:latest

[root@9741d2fab6ee /]# ls -rlt
total 56
drwxr-xr-x   2 root root  4096 Apr 11  2018 srv
drwxr-xr-x   2 root root  4096 Apr 11  2018 opt
drwxr-xr-x   2 root root  4096 Apr 11  2018 mnt
drwxr-xr-x   2 root root  4096 Apr 11  2018 media
drwxr-xr-x   2 root root  4096 Apr 11  2018 home
drwxr-xr-x  13 root root  4096 Aug  1 01:09 usr
lrwxrwxrwx   1 root root     8 Aug  1 01:09 sbin -> usr/sbin
lrwxrwxrwx   1 root root     9 Aug  1 01:09 lib64 -> usr/lib64
lrwxrwxrwx   1 root root     7 Aug  1 01:09 lib -> usr/lib
lrwxrwxrwx   1 root root     7 Aug  1 01:09 bin -> usr/bin
drwxr-xr-x  18 root root  4096 Aug  1 01:09 var
drwxrwxrwt   7 root root  4096 Aug  1 01:10 tmp
drwxr-xr-x  11 root root  4096 Aug  1 01:10 run
dr-xr-x---   2 root root  4096 Aug  1 01:10 root
-rw-r--r--   1 root root 12090 Aug  1 01:10 anaconda-post.log
dr-xr-xr-x  13 root root     0 Sep 10 16:10 sys
drwxr-xr-x   1 root root  4096 Sep 10 16:57 etc
dr-xr-xr-x 282 root root     0 Sep 10 16:57 proc
drwxr-xr-x   5 root root   360 Sep 10 16:57 dev

[root@9741d2fab6ee /]# echo $HOSTNAME
9741d2fab6ee
[root@9741d2fab6ee /]# 
```

We can see `docker container run -it --name myserver centos` command downloaded and started the CentOS contianer in interactive mode and we were taken to the bash root prompt directly.

As soon as we exit from the bash, container will also stop.

```txt
[root@9741d2fab6ee /]# exit
exit
HellsKitchen :: ~ » 
```

We can now start the container in interactive mode again and go to it's bash prompt. This time, instead of `-it` we need to pass `-ai`

```txt
HellsKitchen :: ~ » docker container start -ai myserver
[root@9741d2fab6ee /]# 

[root@9741d2fab6ee /]# echo $HOSTNAME
9741d2fab6ee
```

What if we want to connect to to an existing container that is already running MariaDB or a web server like nginx?

Let's check for running containers.

```txt
HellsKitchen :: ~ » docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                NAMES
f2575c9fc4db        nginx               "nginx -g 'daemon of…"   29 minutes ago      Up 29 minutes       0.0.0.0:80->80/tcp   proxy
```

nginx is currently running. We can now connect to this contianer's bash by executing an additional command `bash` in interactive mode using `-it`

```
HellsKitchen :: ~ » docker container exec -it proxy bash
root@f2575c9fc4db:/# 
root@f2575c9fc4db:/# echo $HOSTNAME 
f2575c9fc4db

root@f2575c9fc4db:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  10624  5472 pts/0    Ss+  16:34   0:00 nginx: master process nginx -g daemon off;
nginx        6  0.0  0.0  11096  2452 pts/0    S+   16:34   0:00 nginx: worker process
root         7  0.0  0.0   3868  3260 pts/1    Ss   17:04   0:00 bash
root       373  0.0  0.0   7640  2720 pts/1    R+   17:08   0:00 ps aux
```

Whatever we do in this bash session, will impact the running container. We can see the `ps aux` shows us NginX is currenctly running.

```txt
HellsKitchen :: ~ » docker container run -it --rm --name myserver centos
```

The `--rm` will download and start the contaner temporily and do the cleanup automatically once we exit.

```txt
docker network ls
docker network inspect bridge
docker network create new_net
```
