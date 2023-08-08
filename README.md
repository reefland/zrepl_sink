# zrepl sink

Sink server daemon container for zrepl push jobs. This is intended for environments which have a kernel that support ZFS but are unable to deploy [zrepl](https://zrepl.github.io/index.html) [sink](https://zrepl.github.io/v0.2.1/configuration/jobs.html#job-type-sink) job type such as TrueNAS Scale.

**This is experimental preview for testing**.  You should already have working knowledge of `zrepl`, its configuration and why you would want a sink server.

---

## Test Environment

1. Create a dataset to hold sink job datasets from remote hosts

    * Adjust the ZFS pool name and dataset name for your needs, `zroot/sink` is used here:

    ```shell
    zfs create zroot/sink -o mountpoint=none -o canmount=noauto
    ```

2. Create `config` directory for `zrepl.yaml` and certificates

    ```shell
    mkdir ./config
    ```

3. [Create TLS Certificates](./docs/ca_using_easyrsa.md) for `zrepl sink` daemon container
    * [zrepl transport](https://zrepl.github.io/configuration/transports.html#transport) documents different method to support inbound connections and client identification, this example assumes TLS certificates
    * `ca.crt` - certificate authority certificate
    * `sink-srv.crt` - Sink server daemon certificate
    * `sink-srv.key` - Sink server daemon private key

    ```shell
    $ ls -l 

    .rw------- rich rich 1.2 KB Thu Aug  3 14:39:09 2023 ca.crt
    .rw-r--r-- rich rich 4.6 KB Thu Aug  3 14:39:21 2023 sink-srv.crt
    .rw------- rich rich 1.7 KB Thu Aug  3 14:39:31 2023 sink-srv.key
    ```

4. Customize `zrepl.yml` configuration file (see example [sink config file](./examples/zrepl_sink.yml))
    * The `jobs` section defined the `sink` job for the daemon:

    ```yaml
    jobs:
      - type: sink
        name: zrepl_sink_server
    ```

    * The `root_fs` defined the ZFS pool and dataset the daemon will use (dataset created in Step `1`)

      * ZFS filesystems are received to `$root_fs/$client_identity/$source_path`

    ```yaml
        root_fs: "zroot/sink"
    ```

    * Define how connections will be served, this will listen for `tls` connections on port `8448`:

    ```yaml
        serve:
          type: tls
          listen: ":8448"
          listen_freebind: true
    ```

    * Define the full pathname for certificates used inside the Sink Server daemon container (paths are inside the container):

    ```yaml
          ca: /config/ca.crt
          cert: /config/sink-srv.crt
          key: /config/sink-srv.key
    ```

    * Define names of clients allowed to connect to the Sink Server daemon (adjust the names to match the `CN` values in the certificates you generated):

    ```yaml
          client_cns:
            - "dldsk01"
            - "k3s01"
            - "k3s02"
            - "k3s03"
            - "k3s04"
            - "k3s05"
            - "k3s06"
    ```

    * Review [property overrides](https://zrepl.github.io/stable/configuration/sendrecvoptions.html#job-recv-options-inherit-and-override), below prevents the Sink Server daemon host from trying to mount replicated datasets:

    ```yaml
        recv:
          properties:
            override: {
              "canmount": "noauto"
            }
    ```

    * Review properties assigned to placeholder datasets.  `zrepl` will maintain the hierarchy of your filesystem datasets even if you do not replicate all of them. Datasets not replicated will have a placeholder created for them:

    ```yaml
          placeholder:
            encryption: inherit
    ```

---

## Environment Variables

The following environment variables can be set within the container:

| Variable  | Description | Default Value |
|---        |---          |---            |
| `CONFIG`  | Full pathname inside container to `zrepl.yml` | `/config/zrepl.yml` |

---

## Running Test Container

```shell
docker run -d --privileged -p 8448:8448  \
  -v ./config:/config \
  -v /etc/timezone:/etc/timezone:ro \
  --name zrepl_sink quay.io/reefland/zrepl_sink:latest
```

* Container runs as `root` and requires `--privileged` to access the underlying hosts `/dev/zfs` device to issue `zfs` commands
* The internal port number `8448` is defined in the `zrepl.yml` file, external port `8448` will be used for inbound connection from clients (adjust as needed)

### Container Logs

```shell
$ docker logs zrepl_sink

* Default Config File Set: /config/zrepl.yml
* Config location verified.
* root_fs value for sink pool: zroot/sink

NAME         USED  AVAIL     REFER  MOUNTPOINT
zroot/sink   247M   515G      320K  none

Attempting zrepl config check...
Attempting to start zrepl daemon...
2023-08-06T15:25:38Z [INFO]: zrepl version=v0.6.0 go=go1.19.2 GOOS=linux GOARCH=amd64 Compiler=gc
2023-08-06T15:25:38Z [INFO]: starting daemon
2023-08-06T15:25:38Z [INFO][_control][job][Uv38$Uv38]: starting job
2023-08-06T15:25:38Z [INFO][zrepl_sink_server][job][Uv38$Uv38]: starting job
```

---

#### Enable Prometheus Monitoring

See `zrepl` project documentation on [monitoring](https://zrepl.github.io/configuration/monitoring.html) for details.

In the `global:` section of the `zrepl.yml` file add:

```yaml
  monitoring:
    - type: prometheus
      listen: ":9811"
      listen_freebind: true
```

* Add the port forwarding to the `docker run` command: `-p 9811:9811`
* Add the container IP address to the Prometheus Scape jobs

---

* See [Configure Clients](./docs/client_manual_push.md) for Push Replication example to Sink Server daemon.
