Create a Colima setup that is reacheable from the network (requires sudo)

```console
$ colima start --cpu 4 --memory 4 --disk 10 --network-address
```

Obtain the Colima IP address:

```console
$ colima list
PROFILE    STATUS     ARCH       CPUS    MEMORY    DISK     RUNTIME    ADDRESS
default    Running    aarch64    4       4GiB      10GiB    docker     192.168.106.2
```

Create two nodes and connect them using `user-v2` network:

```console
$ limactl start --cpus 2 --memory 2 --name node1 --network=lima:user-v2 template://alpine

$ limactl start --cpus 2 --memory 2 --name node2 --network=lima:user-v2 template://alpine
```

Check if you can connect from the node to Colima:

```
$ ssh -F ~/.lima/node1/ssh.config lima-node1

$ ping -c4 192.168.106.2
```
