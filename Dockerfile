# Multi-stage Dockerfile untuk Lavalink v4 - Railway Optimized
# Designed untuk Railway's Dockerfile builder
# Ensures 100% compatibility dengan Railway deployment platform
# Updated: install native libs required by libudpqueue and download youtube-source plugin

FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="riboncabe500-ctrl"
LABEL description="Lavalink v4 Audio Streaming Server - Railway Edition"

# Set working directory
WORKDIR /lavalink

# Install runtime dependencies (including native libs libgcc/libstdc++)
RUN apk add --no-cache \
    curl \
    ca-certificates \
    tzdata \
    wget \
    libgcc \
    libstdc++ \
    && rm -rf /var/cache/apk/*

# Download Lavalink v4.0.8 dari official GitHub release
RUN echo "⏳ Downloading Lavalink v4.0.8..." && \
    wget -q "https://github.com/lavalink-devs/Lavalink/releases/download/4.0.8/Lavalink.jar" \
    -O /tmp/Lavalink.jar && \
    mv /tmp/Lavalink.jar ./Lavalink.jar && \
    ls -lh ./Lavalink.jar && \
    echo "✅ Download complete!"

# Create necessary directories dengan proper permissions
RUN mkdir -p ./data ./logs ./plugins && \
    chmod 755 ./data ./logs ./plugins && \
    echo "✅ Directories created"

# Download official youtube-source plugin into plugins/ so YouTube searches work
# Use curl -fL to follow redirects and fail on HTTP errors; remove any zero-byte file
RUN echo "⏳ Attempting to download youtube-source plugin..." && \
    PLUGIN_URL="https://github.com/lavalink-devs/youtube-source/releases/latest/download/youtube-source-plugin.jar" && \
    curl -fSL "$PLUGIN_URL" -o /tmp/youtube-source-plugin.jar || true && \
    if [ -s /tmp/youtube-source-plugin.jar ]; then \
      mv /tmp/youtube-source-plugin.jar ./plugins/ && echo "✅ youtube-source plugin downloaded"; \
    else \
      echo "⚠️ youtube-source plugin not available (skipping). If you need YouTube search, add plugin jar to /lavalink/plugins or ensure network access."; \
      rm -f /tmp/youtube-source-plugin.jar; \
    fi && \
    ls -la ./plugins || true

# Copy application configuration dari repository
COPY application.yml ./application.yml

# Set environment defaults - CRITICAL FOR RAILWAY
# Railway automatically uses PORT env var for port mapping
ENV PORT=8080
ENV SERVER_PORT=8080
ENV LAVALINK_SERVER_PASSWORD=youshallnotpass

# Java optimizations untuk low-latency audio streaming
# FIXED: Removed unsupported G1 options yang tidak tersedia di Eclipse Temurin Alpine JRE 17
# G1GC dengan MaxGCPauseMillis sudah optimal untuk audio streaming
ENV _JAVA_OPTIONS="-Xmx512M -Xms256M -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled -XX:+UnlockDiagnosticVMOptions -XX:G1SummarizeRSetStatsPeriod=1"

# Expose port 8080 (Railway standard port)
EXPOSE 8080

# Health check untuk Railway
# Railway akan check setiap 30 detik apakah service masih healthy
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f -s -H "Authorization: ${LAVALINK_SERVER_PASSWORD}" \
    http://localhost:8080/info || exit 1

# Entrypoint: start Lavalink dengan JVM
ENTRYPOINT ["java", "-jar", "Lavalink.jar"]

# OCI Image labels untuk container metadata
LABEL org.opencontainers.image.title="Lavalink v4"
LABEL org.opencontainers.image.version="4.0.8"
LABEL org.opencontainers.image.source="https://github.com/lavalink-devs/Lavalink"
LABEL org.opencontainers.image.authors="riboncabe500-ctrl"
