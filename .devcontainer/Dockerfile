FROM mcr.microsoft.com/vscode/devcontainers/ruby:3.2

RUN apt-get update && \
    apt-get install -y nodejs \
    build-essential \
    libsqlite3-dev \
    libpq-dev \
    default-libmysqlclient-dev && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
    
RUN sudo gem update --system 
RUN gem install appraisal
RUN sudo chown -R vscode:vscode /usr/local/rvm/gems /usr/local/rvm/gems/default /usr/local/lib/ruby /usr/local/bundle