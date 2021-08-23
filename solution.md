# Solution

Do the usual `gcloud auth list` and `project import` thingy as mentioned in the instructions

Remember `$DEVSHELL_PROJECT_ID` will have the value of your own GCP project ID!

### Download Package

The code package is stored in the GCS bucket by the name of your own project-id. Download it and untar the code package as follows

```
student_03_6f9735e5dba3@cloudshell:~ (qwiklabs-gcp-03-ebe8b28f6328)$ echo $DEVSHELL_PROJECT_ID
qwiklabs-gcp-03-ebe8b28f6328

student_03_6f9735e5dba3@cloudshell:~ (qwiklabs-gcp-03-ebe8b28f6328)$ mkdir echo-web
student_03_6f9735e5dba3@cloudshell:~ (qwiklabs-gcp-03-ebe8b28f6328)$ cd echo-web
student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ gsutil cp gs://$DEVSHELL_PROJECT_ID/echo-web-v2.tar.gz .
Copying gs://qwiklabs-gcp-03-ebe8b28f6328/echo-web-v2.tar.gz...
/ [1 files][  2.0 KiB/  2.0 KiB]
Operation completed over 1 objects/2.0 KiB.

student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ tar -zxvf echo-web-v2.tar.gz
./
./manifests/
./manifests/echoweb-ingress-static-ip.yaml
./manifests/echoweb-deployment.yaml
./manifests/echoweb-service-static-ip.yaml
./README.md
./Dockerfile
./main.go
student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ rm -rf echo-web-v2.tar.gz
student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ ls -rlt
total 16
-rw-r--r-- 1 student_03_6f9735e5dba3 student_03_6f9735e5dba3  156 Jun 21  2018 Dockerfile
-rw-r--r-- 1 student_03_6f9735e5dba3 student_03_6f9735e5dba3  717 Jun 21  2018 README.md
-rw-r--r-- 1 student_03_6f9735e5dba3 student_03_6f9735e5dba3 1693 Jun 25  2018 main.go
drwxr-xr-x 2 student_03_6f9735e5dba3 student_03_6f9735e5dba3 4096 Jun 26  2018 manifests
```

### Build the docker image

While within the `echo-web` folder, run the build command. Once build, tag it and push it to GCR.IO 

```
student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ docker build -t echo-app:v2 .
Sending build context to Docker daemon  9.728kB
Step 1/7 : FROM golang:1.8-alpine
1.8-alpine: Pulling from library/golang
550fe1bea624: Pull complete
cbc8da23026a: Pull complete
9b35aaa06d7a: Pull complete
46ca6ce0ffd1: Pull complete
7a270aebe80a: Pull complete
8695117c367e: Pull complete
Digest: sha256:693568f2ab0dae1e19f44b41628d2aea148fac65974cfd18f83cb9863ab1a177
Status: Downloaded newer image for golang:1.8-alpine
 ---> 4cb86d3661bf
Step 2/7 : ADD . /go/src/echo-app
 ---> fdee633272a0
Step 3/7 : RUN go install echo-app
 ---> Running in 518e336d1faa
Removing intermediate container 518e336d1faa
 ---> 90557f2a2a1c
Step 4/7 : FROM alpine:latest
latest: Pulling from library/alpine
29291e31a76a: Pull complete
Digest: sha256:eb3e4e175ba6d212ba1d6e04fc0782916c08e1c9d7b45892e9796141b1d379ae
Status: Downloaded newer image for alpine:latest
 ---> 021b3423115f
Step 5/7 : COPY --from=0 /go/bin/echo-app .
 ---> 24be17a6c18a
Step 6/7 : ENV PORT 8000
 ---> Running in 3217dabde609
Removing intermediate container 3217dabde609
 ---> ee476d6852a0
Step 7/7 : CMD ["./echo-app"]
 ---> Running in 6ea609e8be67
Removing intermediate container 6ea609e8be67
 ---> e863870daa8a
Successfully built e863870daa8a
Successfully tagged echo-app:v2

student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ docker tag echo-app:v2 gcr.io/$DEVSHELL_PROJECT_ID/echo-app:v2

student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ docker push gcr.io/$DEVSHELL_PROJECT_ID/echo-app:v2
The push refers to repository [gcr.io/qwiklabs-gcp-03-ebe8b28f6328/echo-app]
bbf2a1af617a: Pushed
bc276c40b172: Layer already exists
v2: digest: sha256:50401b0822f4a91da9c5ac550b685aa6e6512d9b58ef631a60a2ed9bd61e8d97 size: 739
```

## Deploy

Now deploy the build into GKE cluster and scale it to 2 replicas

```
student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ gcloud container clusters get-credentials echo-cluster --zone=us-central1-a
Fetching cluster endpoint and auth data.
kubeconfig entry generated for echo-cluster.
student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ kubectl create deployment echo-web --image=gcr.io/qwiklabs-resources/echo-app:v2
deployment.apps/echo-web created
student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ kubectl expose deployment echo-web --type=LoadBalancer --port 80 --target-port 8000
service/echo-web exposed
student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ kubectl scale deployment echo-web --replicas=2
deployment.apps/echo-web scaled

student_03_6f9735e5dba3@cloudshell:~/echo-web (qwiklabs-gcp-03-ebe8b28f6328)$ kubectl get service
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
echo-web     LoadBalancer   10.3.254.131   104.197.10.135   80:32124/TCP   3m32s
kubernetes   ClusterIP      10.3.240.1     <none>           443/TCP        27m
```

On the browser enter the external-ip value and see if it's coming as V2.0.0

Or you can do `curl 104.197.10.135` that should also give you the output on the GCS cloud shell prompt!

You should get something like this

```
Echo Test
Version: 2.0.0
Hostname: echo-web-7f978f856d-rjb2j
Host ip-address(es): 10.0.1.8
```

Enjoy :)

### Thank you
