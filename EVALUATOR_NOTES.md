# ShipAPI — Evaluator Reference Notes

## Rubric Item 1: Dockerfile Structure and Build

| **What a full-marks submission looks like** | **Line/Output example** |
| :------------------------------------------ | :---------------------- |
| Correct implementation of layer caching (copying package.json BEFORE npm ci). | `COPY package*.json ./` followed by `RUN npm ci` |
| Using a minimal base image (alpine). | `FROM node:20-alpine` |
| Correct Prisma client generation. | `RUN npx prisma generate` after `COPY prisma ./prisma/` |

- **Common Partial-Credit Mistake**: Placing `COPY . .` at the top of the file. This technically builds, but invalidates the `npm ci` cache on every minor source change.
- **Expert Check**: Look for the use of the `exec` form for the CMD instruction (`CMD ["node", "src/server.js"]` vs. `CMD "node src/server.js"`). The latter starts Node as a child process of a shell, which improperly handles OS signals like SIGTERM for graceful shutdowns.

## Rubric Item 2: Container Health Check

| **What a full-marks submission looks like** | **Line/Output example** |
| :------------------------------------------ | :---------------------- |
| Verification that the GET /health endpoint returns a 200 payload. | `{"status":"ok", ...}` with HTTP 200 |

- **Common Partial-Credit Mistake**: Only recording that the container is "Up" without verifying that the application is actually functional.
- **Expert Check**: Check if the student mapped the port correctly during `docker run`. If the application exposes 3000 but they attempted to access 8080 without a host-port map, they haven't truly verified the health check.

## Rubric Item 3: .dockerignore Effectiveness

| **What a full-marks submission looks like** | **Example Exclusion** |
| :------------------------------------------ | :------------------- |
| Explicitly excluding `.env` and `node_modules`. | `.env` and `node_modules` in `.dockerignore` |
| Excluding revision control metadata. | `.git` in `.dockerignore` |

- **Common Partial-Credit Mistake**: Missing the `.env` file in the ignore list. This is a severe security vulnerability as it bakes secrets directly into the image layers.
- **Expert Check**: Look for `.gitignore` itself being ignored. If `.git` isn't ignored, the build context size will be unnecessarily large, leading to slower initial build times.

## Rubric Item 4: DOCKER_LOG.md Documentation

| **What a full-marks submission looks like** | **Terminal Evidence** |
| :------------------------------------------ | :-------------------- |
| Evidence of a CACHED layer hit on a second build. | `=> CACHED [4/7] RUN npm ci ... 0.0s` |

- **Common Partial-Credit Mistake**: Documenting only the successful second build without highlighting *why* the cache hit happened.
- **Expert Check**: Does the log show timing comparisons? A student who notices the difference between 30 seconds and 1 second truly understands the value of the layer caching pattern.
