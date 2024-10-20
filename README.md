# Simple Node Express Hello World App CI/CD

**Steps to Solve the Challenge** 

Deploy a self-hosted Kubernetes cluster on the vm: 

1-  Using Kubeadm. 

2-  Install container runtime (containerd) (Kubernetes official docs) 

3-  Install kubeadm, kubelet & kubectl (Kubernetes official docs) 

4-  Create the cluster using kubeadm using sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --

cri-socket=/run/containerd/containerd.sock --apiserver-advertise-address=172.16.4.125 

5-  Configure kubectl 

6-  Untaint node (to be able to schedule pods as we are working on a single node cluster) 

7-  Install a CNI plugin (flannel). 

Create a Dockerfile for the application. 

Build the Dockerfile 

Docker login to add my credentials on the server. Push the image to my Docker Hub. 

Will be using the default namespace but will change it in the final deployment to use the my-node-app namespace. 

Create a secret of type docker registry to store and use my credentials. 

Create a deployment for the app, used the pushed image with the created secret. Create a ClusterIP service to expose the deployment (port 3000). 

Installed nginx and created a server for port forwarding from 3000 to[ http://10.111.43.48:3000 ](http://10.111.43.48:3000/)to be able to access the app on[ 8.213.41.138:3000 ](http://8.213.41.138:3000/)

Under /etc/nginx/sites-enabled/my-app added 

server { 

`    `listen 3000; 

`    `server\_name my-app; 

`    `location / { 

`        `proxy\_set\_header   X-Forwarded-For $remote\_addr;         proxy\_set\_header   Host $http\_host; 

`        `proxy\_pass         "http://10.111.43.48:3000"; 

`    `} 

} 

Then executed “service nginx restart” 

Deploy new version and split traffic between the two versions: 

- Install Linkerd as a Kubernetes Service Mesh: 
1. curl -sL https://run.linkerd.io/install | sh 
1. export PATH=$PATH:$HOME/.linkerd2/bin 
1. linkerd install | kubectl apply -f – 
1. inject linkerd sidecar with the deployment using “kubectl get deploy my-node-app -o yaml | linkerd inject - | kubectl apply -f -“ 
1. setup the dashboard: 
1. linkerd viz install | kubectl apply -f – 
1. linkerd viz dashboard 
- Created new branch for v2 (feature/deployment-v2) 
- Updated the views to show Heyyo From V2  
- Build and pushed a new image version to docker hub (new tag). 
- Updated the manifest files to deploy new version (different than the old one, you can find it under the branch named feature/deployment-v2) – later will be changed to a helm chart to deploy both versions from a template. 
- inject linkerd sidecar with the new deployment using kubectl get deploy my-node-app-v2 -o yaml | linkerd inject - | kubectl apply -f – (testing on the default namespace) 
- Added linkerd.io/inject annotation for linkerd's automatic proxy injection for the default namespace “kubectl annotate ns my-node-app linkerd.io/inject=enabled” (to automatically add the proxy sidecar with all deployments made later to that namespace). 
- Created HTTPRoute (http-route.yaml) to split the traffic round robin (50/50) between the 2 apps. 
- To test splitting the load between the two apps 2 options: 
1. Generate load by deploying a pod (client.yaml) to curl the parent service (in a while true loop) and monitor the traffic. Here I modified the HTTPRoute with 90/10 weights to make sure it is working. (Deleted the pod after testing\*\*) 

![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 001](https://github.com/user-attachments/assets/6e506422-9976-4f9e-8fcc-88ade184e548)


2. Created a nginx deployment to route the incoming traffic to the parent service. That what I did so now when we access the app on http://8.213.41.138:3000/, requests will be split (50/50) between both apps. Also created a service for the nginx deployment (client-svc.yaml) which is used in the nginx to route the incoming traffic from port 3000 to port 80 on ClusterIP 10.108.3.158.  

   ![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 002](https://github.com/user-attachments/assets/3cf07f3a-2043-41bf-8b22-56e7ff03df3a)


- To be able to access the dashboard, updated the web deployment in the linkerd-viz namespace to set -enforced-host to .\* to allow access from the public IP as there is no host name available.  
![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 003](https://github.com/user-attachments/assets/e0cbfee8-742d-470e-a881-4bdba1ef8c34)


- Added nginx server to access the dashboard on port 5000 [(http://8.213.41.138:5000/)](http://8.213.41.138:5000/) under /etc/nginx/sites-enabled/linkerd-dashboard 
![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 004](https://github.com/user-attachments/assets/dcc205f5-35eb-4011-8706-10655693ab2b)

To simulate traffic load on the dashboard, deploy the client pod and view it under the my-node-app namespace 

![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 005](https://github.com/user-attachments/assets/0c3f31c9-f0b6-4101-8218-8da751259d62)


![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 006](https://github.com/user-attachments/assets/9582f86c-42d4-457d-8344-a581a0145720)


After making a couple of requests to port 3000, the dashboard should be like the following 

![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 007](https://github.com/user-attachments/assets/85bab428-d325-4b5a-afac-c6ca28aa7a84)


![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 008](https://github.com/user-attachments/assets/716b22ee-37b1-47b1-8e59-32a7a010afd7)


For Enhancements: 

Installed helm. 

Created a helm chart for the node app deployments for better management. 

Deployed the two versions to the my-node-app namespace instead of using the default namespace. 

Deployed the applications using helm by creating 2 values files each represent a version using: 

- Cd /app/node-express-hello-world/helm/my-app 
- helm install my-node-app-v1 . --values values-v1.yaml 
- helm install my-node-app-v2 . --values values-v2.yaml 

Deleted the Kubernetes objects related to the node app under the /app/node-express-hello- world/deployment folder. (to check the objects they exist under the feature/deployment branch). 

Updated the ClusterIP of the client deployment for nginx to route to the new deployment under the my- node-app namespace. 

Cleanup the default namespace after testing. 

Listing all objects under the my-node-app namespace should result: 

![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 009](https://github.com/user-attachments/assets/edeb43c8-89c7-4b01-bf51-4debc07e116a)


App available at[ 8.213.41.138:3000 ](http://8.213.41.138:3000/)

Refreshing multiple times should result in different displayed text as follows: 

![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 010](https://github.com/user-attachments/assets/011064b3-4554-405e-a455-5f0ce53de7aa) ![Aspose Words fa3a2229-3ffd-445c-8367-d37b188519b3 011](https://github.com/user-attachments/assets/580aac8d-e6f3-4264-98fc-3f34d0deacd3)


Dashboard available at[ Linkerd ](http://8.213.41.138:5000/namespaces/my-node-app)

