# syntax=docker/dockerfile:1

# Production image for ShipAPI
# Node 20 on Alpine Linux — minimal footprint (~50MB base)
FROM node:20-alpine

# Set working directory for all subsequent instructions
WORKDIR /app

# --- Layer Caching Pattern ---
# Copy ONLY the dependency manifests first.
# This layer is cached as long as package.json and package-lock.json
# do not change — even if source code changes.
COPY package*.json ./

# Install production dependencies only.
# npm ci is stricter than npm install — uses lock file exactly.
# --only=production excludes devDependencies (nodemon, typescript, etc.)
RUN npm ci --only=production

# Copy Prisma schema before generating the client.
# prisma generate reads schema.prisma — it must exist in the container.
COPY prisma ./prisma/

# Generate Prisma Client from the schema.
# This creates the type-safe database client used by the app.
# Must run after COPY prisma and before app starts.
RUN npx prisma generate

# Copy remaining source code.
# This comes AFTER npm ci — source file changes do not invalidate
# the npm ci layer above, enabling fast cached rebuilds.
COPY . .

# Document the port (informational — does not publish or bind)
EXPOSE 3000

# Start the application.
# Use exec form (array) not shell form (string) for proper signal handling.
# This ensures SIGTERM is handled correctly by Node.js for graceful shutdown.
CMD ["node", "src/server.js"]
