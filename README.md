Set of tools to install and manage [Garage](https://garagehq.deuxfleurs.fr/) on OpenShift Container Platform.

## Garage

To install Garage:

```shell
./install.sh
```

To customize the project name (default: `garage`)

```shell
PROJECT=my-project ./install.sh
```

To customize the bucket name (default: `test`)

```shell
BUCKET=my-bucket ./install.sh
```

To upgrade an existing installation (default: `install`)

```shell
HELM_COMMAND=upgrade ./install.sh
```

## Thanos

To create a Kubernetes secret configuring Thanos to use the local Garage API:

```shell
./thanos.sh
```
