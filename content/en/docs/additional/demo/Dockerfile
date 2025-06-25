FROM registry.access.redhat.com/ubi8/go-toolset:1.23.9-2.1750813114 AS build
COPY main.go /opt/app-root/src
ENV CGO_ENABLED=0\
    GOOS=linux\
    GOARCH=amd64\
    GO111MODULE=off
RUN go build -a -o go-hello-world-app .

FROM registry.access.redhat.com/ubi8/ubi:8.10-1304.1749680715
RUN useradd -ms /bin/bash golang
RUN chgrp -R 0 /home/golang && \
    chmod -R g+rwX /home/golang
USER golang
COPY --from=build /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
CMD /home/golang/go-hello-world-app
