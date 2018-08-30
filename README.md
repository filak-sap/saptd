# TestDrive with "persistence"

This projects tries to provide an infrastructure for building docker image from
SAP TestDrive appliance.

The input is un-rared Appliance content in the directory Appliance.

The outcome are 2 Docker images:
- operating system (everything without /usr/sap, /sapmnt, /sybase)
- SAP system (/usr/sap, /sapmnt, /sybase)

## Steps

First you need to build the base OS image:

```bash
sudo docker build -t sap_td_os -f Dockerfile.os .
```

Then you create volumes:

```bash
sudo docker volume create sap_td_usrsap
sudo docker volume create sap_td_sapmnt
sudo docker volume create sap_td_sybase
```

Then you start a container where you can install TD:

```bash
sudo docker run -d -m 4g \
    -v Appliance:/opt/sap/td/appliance:ro \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v sap_td_usrsap:/usr/sap \
    -v sap_td_sapmnt:/sapmnt \
    -v sap_td_sybase:/sybase \
    --privileged \
    --hostname vhcalnplci \
    --name sap_td_os_installer \
    sap_td_os
```

When started you can proceed with the installation:

```bash
sudo docker exec -it ${image}_installer /usr/local/bin/test_drive_install \
         --password "P@\$\$w0rd" \
         --accept-SAP-developer-license
```

And after successful installation you commit the changes:

```bash
sudo docker commit sap_td_os_installer sap_td_os
```

Finally, you create a pure data image from the volumes:

```bash
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
```

Now you have 2 docker images:
- sap_td_os
- sap_td_system

You need to distribute both. This layout has the benefit that whenever you need
to update OS you rebuild only the image sap_td_os.

Deployment is a bit tricky because you must not start a container from the
image sap_td_system but you have to create its filesystem.

```bash
sudo docker create --name sap_td_system_data sap_td_system
```

And then you can use its volumes to start the OS container:

```
sudo docker run -d --
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -volumes-from sap_td_system_data \
    --privileged \
    --hostname vhcalnplci \
    --name myabap \
    sap_td_os
```
