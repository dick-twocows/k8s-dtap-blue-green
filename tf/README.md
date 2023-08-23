# Kubernetes DTAP Blue Green using Terraform

## Overview

Kubernetes can be configured using Terraform and the process for DTAP environments and Blue Green deployments is relatively simple.

## Rancher Desktop

These steps were tested against Rancher Desktop running Kubernetes 1.26.7.

```bash
❯ rdctl version
rdctl client version: 1.1.0, targeting server version: v1
```

```bash
❯ rdctl list-settings | jq '.kubernetes.version'
"1.26.7"
```

## kubectl

Ensure that the kubectl config is pointing at the Kubernetes cluster.

```bash
❯ kubectl version --output=json
{
  "clientVersion": {
    "major": "1",
    "minor": "27",
    "gitVersion": "v1.27.4",
    "gitCommit": "fa3d7990104d7c1f16943a67f11b154b71f6a132",
    "gitTreeState": "clean",
    "buildDate": "2023-07-19T12:20:54Z",
    "goVersion": "go1.20.6",
    "compiler": "gc",
    "platform": "darwin/amd64"
  },
  "kustomizeVersion": "v5.0.1",
  "serverVersion": {
    "major": "1",
    "minor": "26",
    "gitVersion": "v1.26.7+k3s1",
    "gitCommit": "e47cfc09a48d154076339bacd5bc1be715a32592",
    "gitTreeState": "clean",
    "buildDate": "2023-07-27T23:32:18Z",
    "goVersion": "go1.20.6",
    "compiler": "gc",
    "platform": "linux/amd64"
  }
}
```

```bash
❯ kubectl config current-context
rancher-desktop
```

## Create a test DTAP environment with Blue Green deployments

Change directory.
```bash
❯ cd tf
❯ pwd
/Users/rimurray/twocows/k8s-dtap-blue-green/tf
```

Initialize Terraform, which will configure the provider plugins and create the *.terraform.lock.hcl* file.
```bash
❯ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding kreuzwerker/docker versions matching "3.0.2"...
- Finding latest version of hashicorp/kubernetes...
- Installing kreuzwerker/docker v3.0.2...
- Installed kreuzwerker/docker v3.0.2 (self-signed, key ID BD080C4571C6104C)
- Installing hashicorp/kubernetes v2.23.0...
- Installed hashicorp/kubernetes v2.23.0 (signed by HashiCorp)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Create the Terraform files for a test DTAP environment.
The shell script will create three files.
- test-blue.tf and test-green.tf contain the Blue Green deployments. These are HTTP echo servers which echo back any request received as JSON.
- test.tf contains the test frontend. This is a NGINX server which routes requests to */test* to the correct deployment. In addition requests to */blue* and */green* are supported.

```bash
❯ ./dtap/create-environment.sh 
Enter DTAP environment, e.g. dev|test|stage|prod: test
Creating test-blue-green.tfvars...
./dtap/create-environment.sh: line 8: ./dtap/blue-green.tfvars.envsubst: No such file or directory
Creating test-blue.tf...
Creating test-green.tf...
Creating test.tf, blue is active...
ok
```

Run a Terraform plan on the files created in the previous step.
```bash
❯ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # kubernetes_config_map.test will be created
  + resource "kubernetes_config_map" "test" {
      + data = {
          + "blue-green.template" = <<-EOT
                server {
                    listen       80;
                    listen  [::]:80;
                    server_name  localhost;
                
                    #access_log  /var/log/nginx/host.access.log  main;
                
                    location / {
                        root   /usr/share/nginx/html;
                        index  index.html index.htm;
                    }
                
                	location /${DTAP_ENVIRONMENT} {
                		proxy_pass http://${BLUE_GREEN_ACTIVE}.${DTAP_ENVIRONMENT}-${BLUE_GREEN_ACTIVE}.svc.cluster.local;
                	}
                
                	location /blue {
                		proxy_pass http://blue.${DTAP_ENVIRONMENT}-blue.svc.cluster.local;
                	}
                
                	location /green {
                		proxy_pass http://green.${DTAP_ENVIRONMENT}-green.svc.cluster.local;
                	}
                
                    # redirect server error pages to the static page /50x.html
                    #
                    error_page   500 502 503 504  /50x.html;
                    location = /50x.html {
                        root   /usr/share/nginx/html;
                    }
                }
            EOT
...
Plan: 10 to add, 0 to change, 0 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

```

Before you run the Terraform apply open another terminal and list the k8s namespaces.

```bash
❯ kubectl get namespace
NAME              STATUS   AGE
kube-system       Active   5d5h
default           Active   5d5h
kube-public       Active   5d5h
kube-node-lease   Active   5d5h
```

Run a Terraform apply.

```bash
❯ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
...
Plan: 10 to add, 0 to change, 0 to destroy.
kubernetes_namespace.test-blue: Creating...
kubernetes_namespace.test-green: Creating...
kubernetes_service.test: Creating...
kubernetes_namespace.test: Creating...
kubernetes_service.test-green: Creating...
kubernetes_config_map.test: Creating...
kubernetes_service.test-blue: Creating...
kubernetes_deployment.test-green: Creating...
kubernetes_deployment.test-blue: Creating...
kubernetes_deployment.test: Creating...
kubernetes_namespace.test-blue: Creation complete after 0s [id=test-blue]
kubernetes_namespace.test: Creation complete after 0s [id=test]
kubernetes_namespace.test-green: Creation complete after 0s [id=test-green]
kubernetes_config_map.test: Creation complete after 0s [id=test/nginx-config]
kubernetes_service.test-blue: Creation complete after 0s [id=test-blue/blue]
kubernetes_service.test-green: Creation complete after 0s [id=test-green/green]
kubernetes_service.test: Creation complete after 0s [id=test/test]
kubernetes_deployment.test-blue: Still creating... [10s elapsed]
kubernetes_deployment.test-green: Still creating... [10s elapsed]
kubernetes_deployment.test: Still creating... [10s elapsed]
kubernetes_deployment.test-blue: Creation complete after 15s [id=test-blue/blue]
kubernetes_deployment.test: Creation complete after 15s [id=test/test]
kubernetes_deployment.test-green: Creation complete after 15s [id=test-green/green]
```

List the k8s namespaces again.
```bash
❯ kubectl get namespace
NAME              STATUS   AGE
kube-system       Active   5d5h
default           Active   5d5h
kube-public       Active   5d5h
kube-node-lease   Active   5d5h
test-blue         Active   29s
test              Active   29s
test-green        Active   29s
```

List all resources in the test namespace.
```bash
❯ kubectl get all -n test
NAME                       READY   STATUS    RESTARTS   AGE
pod/test-55bf58f6d-jcl8p   1/1     Running   0          4m1s

NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/test   NodePort   10.43.221.182   <none>        80:30122/TCP   4m1s

NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/test   1/1     1            1           4m1s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/test-55bf58f6d   1         1         1       4m1s
```

Query the frontend to see which where the request is routed.
We use *kubectl get service test -n test -o json* to get the node port of the service which allows us to specify the port for the curl command.
The echo server which is running on blue and green returns JSON so we can use *jq '.host.hostname'* to extract the hostname which will indicate where the requested is routed.
```bash
❯ curl "http://localhost:$(kubectl get service test -n test -o json | jq '.spec.ports[0].nodePort')/test" | jq '.host.hostname'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1092  100  1092    0     0  50738      0 --:--:-- --:--:-- --:--:-- 68250
"blue.test-blue.svc.cluster.local"
```

We can also query the Blue and Green deployments directly.
```bash
❯ curl "http://localhost:$(kubectl get service test -n test -o json | jq '.spec.ports[0].nodePort')/blue" | jq '.host.hostname'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1092  100  1092    0     0   108k      0 --:--:-- --:--:-- --:--:--  213k
"blue.test-blue.svc.cluster.local"

❯ curl "http://localhost:$(kubectl get service test -n test -o json | jq '.spec.ports[0].nodePort')/green" | jq '.host.hostname'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1106  100  1106    0     0  55636      0 --:--:-- --:--:-- --:--:-- 79000
"green.test-green.svc.cluster.local"
```

## Destroy the test environment

```bash
❯ terraform destroy
kubernetes_namespace.test: Refreshing state... [id=test]
kubernetes_service.test-blue: Refreshing state... [id=test-blue/blue]
kubernetes_namespace.test-blue: Refreshing state... [id=test-blue]
kubernetes_service.test-green: Refreshing state... [id=test-green/green]
kubernetes_namespace.test-green: Refreshing state... [id=test-green]
kubernetes_config_map.test: Refreshing state... [id=test/nginx-config]
kubernetes_service.test: Refreshing state... [id=test/test]
kubernetes_deployment.test-green: Refreshing state... [id=test-green/green]
kubernetes_deployment.test-blue: Refreshing state... [id=test-blue/blue]
kubernetes_deployment.test: Refreshing state... [id=test/test]
...

Plan: 0 to add, 0 to change, 10 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

kubernetes_namespace.test-green: Destroying... [id=test-green]
kubernetes_namespace.test: Destroying... [id=test]
kubernetes_namespace.test-blue: Destroying... [id=test-blue]
kubernetes_config_map.test: Destroying... [id=test/nginx-config]
kubernetes_service.test-blue: Destroying... [id=test-blue/blue]
kubernetes_service.test: Destroying... [id=test/test]
kubernetes_service.test-green: Destroying... [id=test-green/green]
kubernetes_deployment.test-green: Destroying... [id=test-green/green]
kubernetes_deployment.test-blue: Destroying... [id=test-blue/blue]
kubernetes_deployment.test: Destroying... [id=test/test]
kubernetes_config_map.test: Destruction complete after 0s
kubernetes_deployment.test-green: Destruction complete after 1s
kubernetes_deployment.test-blue: Destruction complete after 1s
kubernetes_deployment.test: Destruction complete after 1s
kubernetes_service.test-green: Destruction complete after 1s
kubernetes_service.test-blue: Destruction complete after 1s
kubernetes_service.test: Destruction complete after 1s
kubernetes_namespace.test-blue: Destruction complete after 7s
kubernetes_namespace.test: Destruction complete after 7s
kubernetes_namespace.test-green: Destruction complete after 7s

Destroy complete! Resources: 10 destroyed.
```

Check that the resources have been deleted.
```bash
❯ kubectl get namespace
NAME              STATUS   AGE
kube-system       Active   5d6h
default           Active   5d6h
kube-public       Active   5d6h
kube-node-lease   Active   5d6h
```
