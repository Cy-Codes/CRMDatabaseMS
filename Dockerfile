# Stage 1: Build DACPAC from SQL project
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
WORKDIR /src
COPY . .
RUN dotnet build CRMDatabase/CRMDatabase.sqlproj -c Release -o /app/dacpac

# Stage 2: SQL Server runtime with automated DACPAC deployment
FROM mcr.microsoft.com/mssql/server:2022-latest
USER root

# Install prerequisites for SqlPackage
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unzip \
        libunwind8 \
        libicu-dev && \
    rm -rf /var/lib/apt/lists/*

# Install SqlPackage CLI based on architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        SQLPACKAGE_URL="https://aka.ms/sqlpackage-linux-arm64"; \
    else \
        SQLPACKAGE_URL="https://aka.ms/sqlpackage-linux"; \
    fi && \
    curl -sSL -o /tmp/sqlpackage.zip "$SQLPACKAGE_URL" && \
    mkdir -p /opt/sqlpackage && \
    unzip -qq /tmp/sqlpackage.zip -d /opt/sqlpackage && \
    chmod +x /opt/sqlpackage/sqlpackage && \
    rm /tmp/sqlpackage.zip

WORKDIR /app
COPY --from=builder /app/dacpac/CRMDatabase.dacpac /app/CRMDatabase.dacpac
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && \
    chown -R mssql:root /app /opt/sqlpackage

USER mssql

EXPOSE 1433

ENTRYPOINT ["/app/entrypoint.sh"]
