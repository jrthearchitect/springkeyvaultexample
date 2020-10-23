FROM openjdk:8-jdk-alpine
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} springapp.jar
ENTRYPOINT ["java","-jar","/springapp.jar"]