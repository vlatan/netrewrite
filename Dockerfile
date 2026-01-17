FROM python:3.13-slim AS builder

WORKDIR /src

ARG SITE_URL
ARG SITE_NAME
ARG SITE_TAGLINE
ARG GTAG_ID
ARG CONTACT_EMAIL

ENV SITE_URL=$SITE_URL \
    SITE_NAME=$SITE_NAME \
    SITE_TAGLINE=$SITE_TAGLINE \
    CONTACT_EMAIL=$CONTACT_EMAIL \
    GTAG_ID=$GTAG_ID

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