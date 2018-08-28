#!/usr/bin/bash
# Author: Jakub Filak <jakub.filak@sap.com>

set -o nounset
set -o errexit
set -o pipefail

declare -r image="sap_td_os"

function print_help () {
    echo "Usage: ./build.sh [-f] [-h|--help] APPLIANCE_DIR"
    echo "    -f    Force build of the docker image"
    echo "    -h    Prints help"
}

if [[ $# < 1 ]]; then
    print_help
    exit 1
fi

if [[ ${1:-} == "-h" ]] || [[ ${1:-} == "--help" ]]; then
    print_help
    exit 0
fi

if [[ ${1:-} == "-f" ]]; then
    echo "Force image rebuild: removing the image ${image}"
    sudo docker rmi ${image}

    if sudo docker inspect ${image} &>/dev/null; then
        echo "Force image rebuild: the images still exist" 1>&2
        exit 1
    else
        echo "Force image rebuild: removed the image ${image}"
    fi
    shift
fi

if [[ $# < 1 ]]; then
    print_help
    exit 1
fi
declare -r appliance_dir=$1

if ! sudo docker inspect ${image} &>/dev/null; then
    sudo docker build -t ${image} -f Dockerfile.os . || exit
fi

# docker create --name sap_td_install docker.wdf.sap.corp:51190/dlm/sap_netweaver_install
# docker inspect --format="{{range .Mounts}}{{.Source}}{{end}}" sap_td_install

declare -ar docker_volumes=(sap_td_usrsap sap_td_sapmnt sap_td_sybase)
for volume in ${docker_volumes[@]}; do
    if ! sudo docker volume inspect $volume &>/dev/null; then
        sudo docker volume create $volume || exit 1
    fi
done

if ! sudo docker inspect ${image}_installer &>/dev/null; then
    sudo docker run -d -m 4g \
        -v $appliance_dir:/opt/sap/td/appliance:ro \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -v sap_td_usrsap:/usr/sap \
        -v sap_td_sapmnt:/sapmnt \
        -v sap_td_sybase:/sybase \
        --privileged \
        --hostname vhcalnplci \
        --name ${image}_installer \
        $image

    # give systemd some time to start
    sleep 2
fi

sudo docker exec -it ${image}_installer systemctl stop nwabap

sudo docker exec -it ${image}_installer /usr/local/bin/test_drive_install \
         --password "P@\$\$w0rd" \
         --accept-SAP-developer-license

sudo docker exec -it ${image}_installer su - npladm -c "stopsap ALL"

sudo docker commit ${image}_installer ${image}

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
