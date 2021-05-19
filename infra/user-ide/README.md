# User IDE

IDE for techlab users containing all needed tools. It is based on [codercom/code-server](https://hub.docker.com/r/codercom/code-server), a [VS Code](https://github.com/Microsoft/vscode) accessible through the browser.


## Build

```bash
sudo buildah bud -t user-ide infra/user-ide/
```


## Run

```bash
sudo podman run --rm -d -p 8888:8080 -e PASSWORD=1111 --name=user-ide localhost/user-ide
```

Get the pwd (when not given with env variable):

```bash
sudo podman exec user-ide /bin/bash -c 'cat ~/.config/code-server/config.yaml'
```

Login to your container using the pwd: <http://localhost:8888/>


## Stop

```bash
podman stop user-ide
```
