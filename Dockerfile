# GBIF dockerfile
FROM jekyll/jekyll:4.1.0

# GBIF dockerfile
RUN gem sources --add https://repository.gbif.org/repository/rubygems.org/ && \
    gem sources --remove https://rubygems.org/ && \
    /usr/local/bin/bundle config set mirror.https://rubygems.org https://repository.gbif.org/repository/rubygems.org && \
    su-exec jekyll /usr/local/bin/bundle config set mirror.https://rubygems.org https://repository.gbif.org/repository/rubygems.org

# GBIF dockerfile
ENV JEKYLL_UID=0 \
    JEKYLL_GID=0 \
    JEKYLL_ROOTLESS=1 \
    TZ=UTC

# GBIF dockerfile
RUN apk --no-cache add curl && \
    curl -Ss --output-dir /srv/jekyll/ --remote-name --fail https://raw.githubusercontent.com/gbif/hp-template/master/Gemfile && \
    curl -Ss --output-dir /srv/jekyll/ --remote-name --fail https://raw.githubusercontent.com/gbif/hp-template/master/Gemfile.lock && \
    /usr/local/bin/bundle config set frozen true && \
    /usr/local/bin/bundle install

# Suggested for huggingface spaces deployment
# Copy your Jekyll site into the container
WORKDIR /site
COPY . .

# Disable problematic entrypoint scripts
RUN rm -rf /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh \
           /docker-entrypoint.d/20-envsubst-on-templates.sh

# Create the site directory and set permissions
RUN mkdir -p /site && chown -R jekyll:jekyll /site

# Switch to the jekyll user (avoid root issues)
USER jekyll

# Copy files and build
WORKDIR /site
COPY --chown=jekyll:jekyll . .

# Install dependencies (if using Bundler)
# RUN bundle install

RUN jekyll build

# Use a lightweight web server to serve the static files
FROM alpine:3.18
RUN apk add --no-cache nginx
COPY --from=builder /site/_site /var/www/html

# Minimal static config
RUN echo "daemon off;" >> /etc/nginx/nginx.conf && \
    echo "events { worker_connections 1024; }" >> /etc/nginx/nginx.conf && \
    echo "http { server { listen 80; root /var/www/html; } }" >> /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx"]

# FROM nginx:alpine

# # Create all required Nginx directories with correct permissions
# RUN mkdir -p /var/cache/nginx/client_temp \
#     && mkdir -p /var/cache/nginx/proxy_temp \
#     && mkdir -p /var/cache/nginx/fastcgi_temp \
#     && mkdir -p /var/cache/nginx/uwsgi_temp \
#     && mkdir -p /var/cache/nginx/scgi_temp \
#     && chown -R nginx:nginx /var/cache/nginx \
#     && chmod -R 755 /var/cache/nginx
    
# # Replace default config rather than deleting it
# COPY nginx-custom.conf /etc/nginx/nginx.conf
# RUN chown nginx:nginx /etc/nginx/nginx.conf  # Set proper ownership

# # Copy Jekyll output
# COPY --from=0 /site/_site /usr/share/nginx/html
# # Use 8080 as per nginx-conf
# EXPOSE 8080
# # Run as root (required for port 80)
# USER root
# CMD ["nginx", "-g", "daemon off;"]

