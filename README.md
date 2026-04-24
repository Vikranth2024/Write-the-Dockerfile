# ShipAPI — Solution Reference

## Challenge: Write the Dockerfile (Deployment Challenge 7.11)

This repository contains the reference solution for the ShipAPI Dockerization challenge. The goal was to take a standard Node.js Express + Prisma application and create a production-optimized container images using industry best practices.

## Files Added

### Dockerfile
Production Dockerfile using `node:20-alpine`, layer caching pattern, Prisma generate step, and production-only `npm ci`.

**Key decisions:**
- **node:20-alpine**: Minimal base image (~50MB vs ~900MB for debian) to reduce attack surface and build times.
- **npm ci --only=production**: Installs exact lock file versions and excludes dev-dependencies (like nodemon, typescript).
- **COPY package*.json first**: Enables layer caching for the `npm ci` step.
- **COPY prisma before generate**: The Prisma schema must exist in the container before the client can be generated.
- **COPY . . last**: Source code changes don't invalidate the expensive dependency cache layer.
- **--env-file at runtime**: Keep secrets out of the image by injecting environmental variables at container startup.

### .dockerignore
Excludes `node_modules` (installed fresh by `npm ci`), `.env` (injected at runtime), `.git` (redundant history), and various development artifacts.

### DOCKER_LOG.md
A complete engineer's log documenting build commands, run commands, layer caching proof, and health check verification.

## Build and Run Instructions

To build the image:
```bash
docker build -t shipapi-backend .
```

To run the container with an environment file:
```bash
docker run --env-file .env -p 3000:3000 -d shipapi-backend
```

To verify the deployment:
```bash
curl http://localhost:3000/health
```
