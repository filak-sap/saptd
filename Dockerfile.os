FROM opensuse:latest

LABEL purpose="Operating System for SAP Test Drive"
LABEL author="Jakub Filak <jakub.filak@sap.com>"

LABEL sid="npl"
LABEL hostname="vhalnplci"

LABEL sap_gui_java="conn=/H/${CONTAINER_IP}/S/3200"

ENV container docker

COPY utils/nwabap.service /etc/systemd/system/nwabap.service
COPY utils/test_drive_install /usr/local/bin

RUN zypper install -y expect net-tools iproute2 tcsh tar which uuidd && \
    zypper clean --all &&\
    systemctl enable uuidd nwabap

VOLUME /usr/sap
VOLUME /sapmnt
VOLUME /sybase

ENTRYPOINT ["/usr/lib/systemd/systemd", "--system"]
