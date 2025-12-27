# Use the official pre-built Foundry image
FROM ghcr.io/foundry-rs/foundry:latest

# Switch to root to avoid permission denied errors
USER root

WORKDIR /app

# Copy project files
COPY . .

# Build the contracts
RUN forge build

# Ensure entrypoint is executable
RUN chmod +x ./docker/entrypoint.sh

# Expose Anvil's default port
EXPOSE 8545

ENTRYPOINT ["./docker/entrypoint.sh"]