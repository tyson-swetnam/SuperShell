FROM ubuntu:bionic-20210222

RUN apt-get update \
    && apt-get install -y jq nano curl\
    && apt-get upgrade -y\ 
    && apt-get clean 

# Make New Supershell User
RUN useradd -ms /bin/bash supershell
USER supershell
WORKDIR /home/supershell

COPY SuperShell SuperShell
WORKDIR /home/supershell/SuperShell
RUN ./docker_install.sh

WORKDIR /home/supershell

CMD [ "bash", "/home/supershell/.offline.sh"]
#CMD ["bash"]