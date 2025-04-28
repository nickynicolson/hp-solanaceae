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

# Create the site directory and set permissions
RUN mkdir -p /site && chown -R jekyll:jekyll /site

# Switch to the jekyll user (avoid root issues)
USER jekyll

# Copy files and build
WORKDIR /site
COPY --chown=jekyll:jekyll . .

# Install dependencies (if using Bundler)
RUN bundle install

RUN jekyll build

# Use a lightweight web server to serve the static files
FROM nginx:alpine
COPY --from=0 /site/_site /usr/share/nginx/html

# Expose port 80 (required for Hugging Face Spaces)
EXPOSE 80
