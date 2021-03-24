# https://github.com/dcbw/ovn-fun
FROM fedora:33

MAINTAINER Dan Williams <dcbw@redhat.com>

RUN dnf -y upgrade && \
	dnf -y install openvswitch-test iputils tcpdump ovn ovn-central ovn-host procps-ng && \
	dnf clean all -y
RUN rm -f /root/*

COPY startup.sh /
COPY server.py /root/
COPY README /root/

WORKDIR /root
ENTRYPOINT /startup.sh

