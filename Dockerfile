FROM python:3.13-slim AS builder

WORKDIR /src

ARG SITE_URL
ARG SITE_NAME
ARG SITE_TAGLINE
ARG GTAG_ID
ARG CONTACT_EMAIL

# Install your generator
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the content (.md files)
COPY content/ ./content/

# Create env vars
ENV SITE_URL=$SITE_URL
ENV SITE_NAME=$SITE_NAME
ENV SITE_TAGLINE=$SITE_TAGLINE
ENV GTAG_ID=$GTAG_ID
ENV CONTACT_EMAIL=$CONTACT_EMAIL

# Generate the website
RUN picogen --generate

# Production image
FROM nginx:alpine
COPY --from=builder /src/build /usr/share/nginx/html

# Custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf