# zrepl Sink Server for TrueNAS

[Project Example on Sink Server](https://zrepl.github.io/quickstart/continuous_server_backup.html)

## Warning Message

* The zrepl_sink server container requires Privileged Mode enabled in order to access `/dev/zfs` and `/proc/self/mounts` which are required by `zrepl`.
  * These paths can not be specified by host path as the TrueNAS configuration wizard does not allow a path outside of the ZFS pool.
  * _Potentially Zrepl can be run with an unprivileged user in combination with ZFS delegation._

---

## Known Issues

* If after rebooting TrueNAS is unable to start Docker or Kubernetes applications with a message the Datasets are locked.
  * `locked` in this context does not appear to be related to encrypted datasets with keys unavailable - which is the usual "locked data" in TrueNAS.
  * The datasets are mounted and browsable however the zrepl dataset being unrelated to other applications still prevents then from starting.
  * `zrepl` project documentation has warnings about enabling [ZFS property replication](https://zrepl.github.io/configuration/sendrecvoptions.html#a-note-on-property-replication).

Tested the following ZFS receive property overrides (did not help):

```text
  recv:
    properties:
      override: {
        "canmount": "off",
        "mountpoint": "none",
        "readonly": "on",
        "openzfs.systemd:ignore": "on"
      }
```

To recover and be able to start Docker / Kubernetes application on TrueNAS the zrepl sink dataset must be destroyed (which requires holds on datasets to be [removed manually](destroy_zrepl_datasets.md)).

---

The `zrepl_sink_data` dataset should have the following properties manually applied via the TrueNAS CLI:

```shell
zfs set canmount=off main/zrepl_sink_data
zfs set mountpoint=none main/zrepl_sink_data
zfs set readonly=on main/zrepl_sink_data
```

The following `recv` properties are currently being tested on `sink` job side:

```text
  recv:
    properties:
      # Force mountpoint to be inherited from Sink container (set to none)
      inherit:
        - "mountpoint"
      override: {
        # These two need to be disabled to support ZVOL replication
        # "canmount": "off",
        # "mountpoint": "none"
        "readonly": "on",
        "openzfs.systemd:ignore": "on"
        }
```

In conjunction with clients being set to:

```text
  send:
    encrypted: true
    send_properties: false
```

* Setting `send_properties: false` has allowed zrepl sink jobs to work correctly with the Zrepl Sink Server deployed to TrueNAS.
* Obviously enable encryption only if your ZFS configuration is setup to use it.
