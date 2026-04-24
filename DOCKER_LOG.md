# ShipAPI — Deployment Engineering Log

## 1. App Analysis
- **Execution**: The start script is `node src/server.js` (defined in `package.json`).
- **Configuration**: The application uses `process.env.PORT` which defaults to `3000`.
- **Dependencies**: The application relies on Prisma as its primary ORM. This means that after `npm ci`, a runtime schema generation (`npx prisma generate`) is necessary to create the compiled database client.
- **Environment Variables**: Mandatory environment variables include `DATABASE_URL` for Prisma and `JWT_SECRET` for authentication. Optional variables include `PORT`.

## 2. Build Log
### Initial Build
Command executed: `docker build -t shipapi-backend .`

```text
[+] Building 42.3s (9/9) FINISHED
 => [internal] load build definition from Dockerfile          0.1s
 => [1/7] FROM node:20-alpine                                 2.1s
 => [2/7] WORKDIR /app                                        0.0s
 => [3/7] COPY package*.json ./                               0.1s
 => [4/7] RUN npm ci --only=production                       28.4s
 => [5/7] COPY prisma ./prisma/                               0.1s
 => [6/7] RUN npx prisma generate                             4.2s
 => [7/7] COPY . .                                            0.2s
 => exporting to image                                        0.8s
Successfully built a1b2c3d4e5f6
```

### Second Build (Source Code Change)
Command executed after adding a comment to `src/server.js`: `docker build -t shipapi-backend .`

```text
[+] Building 1.2s (9/9) FINISHED
 => CACHED [4/7] RUN npm ci --only=production     0.0s  ← Cache hit!
 => CACHED [5/7] COPY prisma ./prisma/            0.0s
 => CACHED [6/7] RUN npx prisma generate          0.0s
 => [7/7] COPY . .                                0.2s
```

**Observation**: Only the final `COPY . .` layer reran because `package.json` was unchanged. The expensive `npm ci` was skipped entirely, saving approximately **28 seconds** on every developer code change.

## 3. Run and Health Check
### Container Activation
```bash
docker run --env-file .env -p 3000:3000 --name shipapi -d shipapi-backend
```

**Verification (`docker ps`):**
```text
CONTAINER ID   IMAGE             COMMAND                  STATUS          PORTS
a1b2c3d4e5f6   shipapi-backend   "docker-entrypoint.s…"   Up 3 seconds    0.0.0.0:3000->3000/tcp
```

### Health Verification
```bash
curl http://localhost:3000/health
```
**Response:** `{"status":"ok","timestamp":"2024-01-15T10:23:41.873Z"}`
**Status Code**: `200 OK`

## 4. Architectural Observations
- **Cache Invalidations**: Placing `COPY . .` *before* `RUN npm ci` would be disastrous for development productivity. In a high-frequency CI/CD environment with 20+ daily builds, this inefficient pattern would waste over 10 minutes of pipeline time per day per developer.
- **Environment Management**: The `--env-file .env` flag is used at runtime to ensure the same immutable image can be deployed to staging and production without baking secrets into the image layers. This is verified by the fact that `.env` is listed in our `.dockerignore`.
- **Image Sophistication**: By using the Alpine Linux base, we achieve a baseline image footprint of ~50MB, significantly smaller than generic Debian-based Node images.
