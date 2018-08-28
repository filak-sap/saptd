FROM opensuse:latest

LABEL purpose="Operating System for SAP Test Drive "
LABEL author="Jakub Filak <jakub.filak@sap.com>"

ENV container docker

COPY utils/nwabap.service /etc/systemd/system/nwabap.service
COPY utils/test_drive_install /usr/local/bin

RUN zypper install -y expect net-tools iproute tcsh tar which uuid && \
    systemctl enable uuidd nwabap &&
    zypper clean --all

VOLUME /usr/sap
VOLUME /sapmnt
VOLUME /sybase

ENTRYPOINT ["/usr/lib/systemd/systemd", "--system"]
