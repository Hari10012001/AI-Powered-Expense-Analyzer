FROM tomcat:9.0-jdk21-temurin

WORKDIR /usr/local/tomcat

RUN rm -rf webapps/*

COPY src/main/webapp/ webapps/ROOT/
COPY src/main/java/ /tmp/src/main/java/
COPY docker/docker-entrypoint.sh /opt/expense-analyzer/docker-entrypoint.sh

RUN mkdir -p webapps/ROOT/WEB-INF/classes \
    && chmod +x /opt/expense-analyzer/docker-entrypoint.sh \
    && javac -cp "lib/servlet-api.jar:webapps/ROOT/WEB-INF/lib/*" \
       -d webapps/ROOT/WEB-INF/classes \
       $(find /tmp/src/main/java -name "*.java") \
    && rm -rf /tmp/src

EXPOSE 8080

ENTRYPOINT ["/opt/expense-analyzer/docker-entrypoint.sh"]
