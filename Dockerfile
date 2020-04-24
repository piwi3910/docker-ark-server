FROM ubuntu:18.04

MAINTAINER Pascal Watteel

# Requirements
RUN dpkg --add-architecture i386 && \
    apt update && apt upgrade -y  && \
    echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    apt install -y lib32gcc1 curl steamcmd cron bzip2 perl-modules lsof libc6-i386 sudo

RUN ln -s /usr/games/steamcmd /usr/local/bin

#Make steam user and init steamcmd
RUN adduser --gecos "" --disabled-password steam
WORKDIR /home/steam
USER steam
RUN steamcmd +quit

USER root
# Open file limit
RUN echo "fs.file-max=100000" >> /etc/sysctl.conf
RUN sysctl -p /etc/sysctl.conf

RUN echo "*               soft    nofile          1000000" >> /etc/security/limits.conf
RUN echo "*               hard    nofile          1000000" >> /etc/security/limits.conf

RUN echo "session required pam_limits.so" >> /etc/pam.d/common-session

RUN curl -sL "https://raw.githubusercontent.com/FezVrasta/ark-server-tools/v1.6.51/netinstall.sh" | bash -s steam && \
    ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

COPY arkmanager/arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager/instance.cfg /etc/arkmanager/instances/main.cfg
COPY run.sh /home/steam/run.sh
COPY log.sh /home/steam/log.sh

RUN mkdir /ark && \
    chown -R steam:steam /home/steam/ /ark

RUN echo "%sudo   ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers && \
    usermod -a -G sudo steam && \
    touch /home/steam/.sudo_as_admin_successful

WORKDIR /home/steam
USER steam

ENV am_ark_SessionName="Ark Server" \
    am_serverMap="TheIsland" \
    am_ark_ServerAdminPassword="k3yb04rdc4t" \
    am_ark_MaxPlayers=70 \
    am_ark_QueryPort=27015 \
    am_ark_Port=7778 \
    am_ark_RCONPort=32330 \
    am_arkwarnminutes=15

EXPOSE 27015
EXPOSE 27015/udp
EXPOSE 7778
EXPOSE 7778/udp
EXPOSE 32330
VOLUME /ark

CMD [ "./run.sh" ]