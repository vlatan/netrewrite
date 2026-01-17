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

# Create .env file from build args - generator wants an .env file
RUN echo "SITE_URL=${SITE_URL}" > .env && \
    echo "SITE_NAME=${SITE_NAME}" >> .env && \
    echo "SITE_TAGLINE=${SITE_TAGLINE}" >> .env && \
    echo "GTAG_ID=${GTAG_ID}" >> .env && \
    echo "CONTACT_EMAIL=${CONTACT_EMAIL}" >> .env

# Gnerate the website
RUN picogen --generate

# Production image
FROM nginx:alpine
COPY --from=builder /src/build /usr/share/nginx/html

# Custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf