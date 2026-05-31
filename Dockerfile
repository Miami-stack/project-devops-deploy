FROM eclipse-temurin:21-jdk-alpine AS backend-builder

WORKDIR /build


COPY gradlew settings.gradle.kts build.gradle.kts versions.properties ./
COPY gradle gradle/
RUN chmod +x gradlew

COPY src src/

RUN ./gradlew bootJar -x test


# Build frontend
FROM node:20-alpine AS frontend-builder

WORKDIR /frontend

COPY frontend/package*.json ./
RUN npm ci --ignore-scripts

COPY frontend/ ./

RUN npm run build


# Runtime image (minimal)
FROM eclipse-temurin:21-jre-alpine AS runtime

RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -D appuser

WORKDIR /app

COPY --from=backend-builder --chown=appuser:appgroup \
    /build/build/libs/project-devops-deploy-*.jar app.jar

COPY --from=frontend-builder --chown=appuser:appgroup \
    /frontend/dist/ /app/static/

USER appuser

ENV SPRING_PROFILES_ACTIVE=prod \
    SERVER_PORT=8080 \
    MANAGEMENT_SERVER_PORT=9090 \
    JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

EXPOSE 8080 9090

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1


ENTRYPOINT ["sh", "-c", \
    "mkdir -p /app/src/main/resources/static && \
     cp -r /app/static/* /app/src/main/resources/static/ 2>/dev/null || true && \
     exec java $JAVA_OPTS -jar /app/app.jar"]
