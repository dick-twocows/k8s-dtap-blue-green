# NGINX

## Note

TheThe config files were copied from *nginx:latest* using the following shell commands.
The *conf.d/default.conf* file was not copied because we define a server block in *blue-green.conf.template*.

```bash
id="$(docker run -d nginx:latest)"

docker cp "${id}:/etc/nginx/nginx.conf" ./nginx.conf

docker cp "${id}:/etc/nginx/mime.types" ./mime.types

docker cp "${id}:/etc/nginx/conf.d/default.conf" ./default.conf

docker stop "${id}"

docker rm "${id}"
```

## Templates

Active blue green is injected into the NGINX container as an environment variable *BLUE_GREEN_ACTIVE*.

The *blue-green.conf.template* file is mounted into */etc/nginx/templates* which (from NGINX 1.19) is used in the https://github.com/nginxinc/docker-nginx/blob/master/mainline/debian/20-envsubst-on-templates.sh to substitute environment variables (wrapper around *envsubst*) and the result is copied into */etc/nginx/conf.d*.

## Gotcha

The default *nginx.conf* has the line *include /etc/nginx/conf.d/*.conf;* so make sure you name your templates *<name>.conf.template* because the templates script removes the *.template* extension.

## Debug

```bash
❯ k logs test-85b45bb977-zx5b9 -n test
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: /etc/nginx/conf.d/default.conf is not a file or does not exist
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
20-envsubst-on-templates.sh: Running envsubst on /etc/nginx/templates/..data/blue-green.template to /etc/nginx/conf.d/..data/blue-green
20-envsubst-on-templates.sh: Running envsubst on /etc/nginx/templates/blue-green.template to /etc/nginx/conf.d/blue-green
20-envsubst-on-templates.sh: Running envsubst on /etc/nginx/templates/..2023_08_18_15_24_03.1213993371/blue-green.template to /etc/nginx/conf.d/..2023_08_18_15_24_03.1213993371/blue-green
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2023/08/18 15:24:12 [notice] 1#1: using the "epoll" event method
2023/08/18 15:24:12 [notice] 1#1: nginx/1.25.2
2023/08/18 15:24:12 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2023/08/18 15:24:12 [notice] 1#1: OS: Linux 6.1.32-0-virt
2023/08/18 15:24:12 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2023/08/18 15:24:12 [notice] 1#1: start worker processes
2023/08/18 15:24:12 [notice] 1#1: start worker process 32
2023/08/18 15:24:12 [notice] 1#1: start worker process 33
```

## Testing

HTTP query the test endpoint 

- Get the node port value for the test service, using *kubectl* and passing the result through *jq*.
- Get the hostname for the test service, using *curl* and passing the result through *jq*.
- Sleep for 1 second.
- Repeat...

```bash
❯ while true; do curl -s "http://localhost:$(kubectl get service test -n test -o json | jq '.spec.ports[0].nodePort')/test/" | jq '.host.hostname'; sleep 1; done 
...
"green.green.svc.cluster.local"
"green.green.svc.cluster.local"
"green.green.svc.cluster.local"
"blue.blue.svc.cluster.local"
"blue.blue.svc.cluster.local"
"blue.blue.svc.cluster.local"
^C
```
