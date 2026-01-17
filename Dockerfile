FROM python:3.13-slim AS builder

WORKDIR /src

# Install your generator
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy content and generate the website
COPY content/ ./content/
RUN picogen --generate

# Production image
FROM nginx:alpine
COPY --from=builder /src/build /usr/share/nginx/html

# Optional: custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf