FROM openjdk:8
ADD target/demo-workshop-2.1.2.jar demo-workshop-2.1.2.jar
ENTRYPOINT ["java", "-jar", "demo-workshop-2.1.2.jar"]
