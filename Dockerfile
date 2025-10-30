FROM jetty:11-jdk17
COPY target/petclinic.war /var/lib/jetty/webapps/ROOT.war
EXPOSE 8080
