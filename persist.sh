#!/bin/bash
#Author: Jakub Filak <jakub.filak@sap.com>

sudo docker build -t sap_td_system -f Dockerfile.sap \
         -v /bin:/bin:ro \
         -v /usr/bin:/usr/bin:ro \
         -v /lib64:/lib64:ro \
         -v /usr/lib64:/usr/lib64:ro \
         -v /lib:/lib:ro \
         -v /usr/lib:/usr/lib:ro \
         -v sap_td_usrsap:/opt/sap/usr/sap:ro \
         -v sap_td_sapmnt:/opt/sap/sapmnt:ro \
         -v sap_td_sybase:/opt/sap/sybase:ro \
         .
