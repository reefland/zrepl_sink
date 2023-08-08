# Unable to Destroy Zrepl Datasets / Snapshots

`Zrepl` as configured within these examples will place [zfs hold tags](https://openzfs.github.io/openzfs-docs/man/master/8/zfs-hold.8.html) on snapshots preventing them from being [destroyed](https://openzfs.github.io/openzfs-docs/man/master/8/zfs-destroy.8.html). Attempting to destroy the snapshots will result in misleading error messages such as `dataset is busy` and `dataset already exists` (see below).

[Back to README.md](../README.md)

---

```shell
$ sudo zfs destroy -r zroot/sink/dldsk01

cannot destroy snapshot zroot/sink/dldsk01/zroot/ROOT/default/var/lib/snapd@zrepl_20230807_011951_000: dataset is busy
cannot destroy snapshot zroot/sink/dldsk01/zroot/ROOT/default/var/lib@zrepl_20230807_011951_000: dataset is busy
cannot destroy snapshot zroot/sink/dldsk01/zroot/ROOT/default/var@zrepl_20230807_011951_000: dataset is busy
cannot destroy 'zroot/sink/dldsk01/zroot/ROOT/default': dataset already exists
cannot destroy 'zroot/sink/dldsk01/zroot/ROOT': dataset already exists
cannot destroy 'zroot/sink/dldsk01/zroot': dataset already exists
cannot destroy 'zroot/sink/dldsk01': dataset already exists
```

## ZFS Hold Tags

In order to delete these snapshots you will have to determine the name of the `hold tag` using [zfs holds](https://openzfs.github.io/openzfs-docs/man/master/8/zfs-hold.8.html) on the snapshot. Start by inspecting the snapshot in the error message. We'll pick the error snapshot closest to the root:

  ```text
  cannot destroy snapshot zroot/sink/dldsk01/zroot/ROOT/default/var@zrepl_20230807_011951_000: dataset is busy
  ```

A check for holds:

  ```shell
  $ zfs holds -r zroot/sink/dldsk01/zroot/ROOT/default/var@zrepl_20230807_011951_000

  NAME                                                                           TAG                                      TIMESTAMP
  zroot/sink/dldsk01/zroot/ROOT/default/var@zrepl_20230807_011951_000            zrepl_last_received_J_zrepl_sink_server  Sun Aug  6 21:57 2023
  zroot/sink/dldsk01/zroot/ROOT/default/var/lib@zrepl_20230807_011951_000        zrepl_last_received_J_zrepl_sink_server  Sun Aug  6 21:57 2023
  zroot/sink/dldsk01/zroot/ROOT/default/var/lib/snapd@zrepl_20230807_011951_000  zrepl_last_received_J_zrepl_sink_server  Sun Aug  6 21:57 2023
  ```

* The ZFS tag `zrepl_last_received_J_zrepl_sink_server` is applied to each snapshot.

Once you know the ZFS tag name, use [zfs release](https://openzfs.github.io/openzfs-docs/man/master/8/zfs-release.8.html) to remove the tag:

  ```shell
  sudo zfs release -r zrepl_last_received_J_zrepl_sink_server zroot/sink/dldsk01/zroot/ROOT/default/var@zrepl_20230807_011951_000
  ```

You should not be able to destroy the dataset and snapshots:

```shell
$ sudo zfs destroy -r zroot/sink/dldsk01

$ zfs list -r zroot/sink

NAME         USED  AVAIL     REFER  MOUNTPOINT
zroot/sink   320K   513G      320K  none
```

[Back to README.md](../README.md)
