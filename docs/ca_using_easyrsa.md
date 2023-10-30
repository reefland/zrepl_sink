# Certificate Authority using EasyRSA

See [zrepl](https://zrepl.github.io/configuration/transports.html#certificate-authority-using-easyrsa) project for details on certificate creation using EasyRCA or Mutual TLS. Below are steps I used for testing with EasyRSA.

[Back to README.md](./README.md)

The steps below created certificates for 6 nodes, a desktop and the sink server itself.

1. Define host names of certificates to create

    ```shell
    HOSTS=(sink-srv k3s01 k3s02 k3s03 k3s04 k3s05 k3s06 dldsk01)
    ```

2. Download EasyRSA

    ```shell
    EASYRSA_VER="3.1.5"
    curl -L https://github.com/OpenVPN/easy-rsa/releases/download/v${EASYRSA_VER}/EasyRSA-${EASYRSA_VER}.tgz > EasyRSA-${EASYRSA_VER}.tgz
    ```

3. Extract EasyRSA

    ```shell
    rm -rf EasyRSA-${EASYRSA_VER}
    tar -xf EasyRSA-${EASYRSA_VER}.tgz
    ```

4. Initialize EasyRSA Certificate Authority

    ```shell
    cd EasyRSA-${EASYRSA_VER}

    ./easyrsa
    ./easyrsa init-pki
    ./easyrsa build-ca nopass
    ```

5. Create host certificates, you must type `yes` for each hostname presented

    ```shell
    for host in "${HOSTS[@]}"; do
        ./easyrsa build-serverClient-full $host nopass
        echo cert for host $host available at pki/issued/$host.crt
        echo key for host $host available at pki/private/$host.key
    done
    ```

Done! It really is easy.

* The Certificate Authority certificate is `./pki/ca.crt`
* Each hosts certificate is in `./pki/issued/`
* Each hosts private key is in `./pki/private/`

The `ca.crt` and *host certificate* and *host private key* will need to be copied to each respective host with a `zrepl` client to connect to Sink server daemon.

* Each certificate has a `CN` (Common Name) attribute defined of the hostname to identify the client
* A list of `CN` allowed to connect will be defined on the Zrepl Sink Server `zrepl.yml` file
* A ZFS dataset will be created by `zrepl` matching the `CN` to keep each hosts replicated ZFS snapshots isolated

[Back to README.md](./README.md)
