FROM registry.access.redhat.com/ubi8/go-toolset:1.16.12 AS build
COPY main.go /opt/app-root/src
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM registry.access.redhat.com/ubi8/ubi:8.6
RUN useradd -ms /bin/bash golang
RUN chgrp -R 0 /home/golang && \
    chmod -R g+rwX /home/golang
USER golang
COPY --from=build /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
CMD /home/golang/go-hello-world-app
