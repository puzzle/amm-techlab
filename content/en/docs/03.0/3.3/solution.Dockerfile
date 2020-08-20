FROM golang:1.14-alpine
WORKDIR /opt/app-root/src
COPY main.go .
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM registry.access.redhat.com/ubi8/ubi:8.2
RUN useradd -ms /bin/bash golang
RUN chgrp -R 0 /home/golang && \
    chmod -R g+rwX /home/golang
USER golang
COPY --from=0 /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
ENTRYPOINT ["/home/golang/go-hello-world-app"]
