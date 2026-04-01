FROM tomcat:9.0-jdk21-temurin

WORKDIR /usr/local/tomcat

RUN apt-get update \
    && apt-get install -y --no-install-recommends tesseract-ocr tesseract-ocr-eng \
    && rm -rf /var/lib/apt/lists/*

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

ENV EXPENSE_TESSERACT_CMD=/usr/bin/tesseract

EXPOSE 8080

ENTRYPOINT ["/opt/expense-analyzer/docker-entrypoint.sh"]
