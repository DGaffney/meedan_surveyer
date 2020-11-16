FROM ruby:2.5
RUN apt update && apt install -y ruby-dev
RUN gem install bundler
RUN gem update --system
RUN apt-get update && apt-get install -y dumb-init

# CUSTOMIZED --------------------------------------------------
COPY . .
RUN rm -f Gemfile.lock
RUN bundle install

EXPOSE 5678
ENTRYPOINT ["/usr/bin/dumb-init", "--", "./run.sh"]