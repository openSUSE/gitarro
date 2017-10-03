FROM opensuse:42.3

MAINTAINER Julio Gonzalez Gil <jgonzalez@suse.com>

ENV ROBOCOP_VER latest

RUN zypper refresh && \
    zypper -n update && \
    zypper -n install curl gcc git make ruby2.4-devel ruby2.4-rubygem-bundler && \
    zypper -q clean -a

WORKDIR /opt

RUN if [ "${ROBOCOP_VER}" == "latest" ]; then\
      ROBOCOP_VER=$(curl -s https://api.github.com/repos/bbatsov/rubocop/releases/latest|grep tag_name|cut -d':' -f2|cut -d'"' -f2);\
    fi;\
    git clone --branch ${ROBOCOP_VER} --depth 1 https://github.com/bbatsov/rubocop.git &&\
    cd rubocop &&\
    bundler.ruby2.4 install

RUN zypper -n remove --clean-deps curl gcc make ruby2.4-devel &&\
    zypper -q clean -a

RUN mkdir /root/.ssh/ && chmod 700 /root/.ssh

ADD files/known_hosts /root/.ssh/

ADD files/*.sh /opt/

CMD ["/bin/bash", "-e", "/opt/rubocop.sh"]
