# OVN Fun

## Usage (CentOS 8)

* Install podman

```bash
sudo dnf install --refresh podman -y
```

* Load the openvswitch kernel module

```bash
sudo modprobe openvswitch
```

* Run the container as privileged

```bash
sudo podman run -it --rm --privileged quay.io/dcbw/ovn-fun:1
```

Instructions and questions will print out when you start the container
and you can read them by running `/root/README`

## Build

The container is available at `quay.io/dcbw/ovn-fun:1` but
there is a [Dockerfile](Dockerfile) already available, so
in order to build the container:

```bash
podman build -t foobar/ovn-fun:tag .
```

Then push it to your favourite registry.
