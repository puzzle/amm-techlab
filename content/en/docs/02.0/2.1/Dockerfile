FROM registry.access.redhat.com/ubi8/ubi
WORKDIR /work/

#Install wget
RUN yum install wget -y

#Fetch the latest binary release from the GutHub release page
RUN wget https://github.com/puzzle/amm-techlab/releases/download/1.0.0/application

RUN chmod -R 775 /work
EXPOSE 8080

#Run the application
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]