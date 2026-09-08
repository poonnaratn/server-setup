# Fedora server setup

This repository contains a few deliberately small helpers for administering a
Fedora 44 server. They do not install or expose services; they make two common
administration tasks repeatable:

1. connect to the server using either Tailscale or a public SSH address;
2. mount a USB stick safely enough to copy a credential onto the server.

## 1. Configure SSH targets

Copy the example configuration, fill in the values for your server, and keep
the real file private (it is ignored by Git):

```sh
cp config/server.env.example config/server.env
chmod 600 config/server.env
```

For the Tailscale host, use the server's MagicDNS name (for example,
`fedora.tailnet-name.ts.net`) or its `100.x.y.z` Tailscale address. For the
internet host, use your public DNS name or public IP address. Tailscale must
already be installed, signed in, and connected on both computers.

Connect from this computer with:

```sh
./scripts/connect-server tailscale
./scripts/connect-server internet
```

The scripts use your normal `~/.ssh` configuration. Set `SERVER_SSH_KEY` in
`config/server.env` only if you need a particular private key.

## 2. Mount a USB stick on the Fedora server

Attach the USB stick to the Fedora server, then list the available block
devices from this computer:

```sh
./scripts/server-usb tailscale list
```

Choose the *partition* belonging to the USB stick, such as `/dev/sdb1` (not
the whole disk `/dev/sdb`), and mount it:

```sh
./scripts/server-usb tailscale mount /dev/sdb1
```

The default location is `/mnt/usb-sdb1`. The command refuses non-removable
devices and devices that are already mounted. It mounts with `nosuid,nodev,noexec`
to reduce risk from an untrusted removable drive.

Copy a credential while giving the resulting file restrictive permissions:

```sh
./scripts/server-usb tailscale copy /mnt/usb-sdb1/my-key.pem '~/.ssh/my-key.pem'
```

Do not commit credentials to this repository. When done, unmount before
unplugging the drive:

```sh
./scripts/server-usb tailscale unmount /mnt/usb-sdb1
```

Replace `tailscale` with `internet` in any of these commands when needed. The
`server-usb` wrapper sends only the required helper script over SSH; there is
no need to clone this repository onto the Fedora server. It allocates a
terminal so `sudo` can ask for the server account's password when mounting or
unmounting.

## Before connecting from the internet

Prefer Tailscale where possible. If you enable public SSH, use key-based
authentication, disable password and root login, and limit port forwarding in
the server's firewall/router. The scripts connect to an existing SSH service;
they intentionally do not change Fedora's SSH or firewall configuration.

## 3. Use Fedora's built-in web manager (Cockpit)

Run this **on the Fedora laptop** after cloning the repository:

```sh
./scripts/setup-cockpit --allow-network
```

It enables Fedora's Cockpit service, permits its HTTPS port through Fedora's
firewall, and prints the addresses to open in a browser. From a device on the
same LAN, use `https://<laptop-LAN-IP>:9090`; from a Tailscale device, use
`https://<laptop-Tailscale-IP>:9090`.

The first browser visit may show a certificate warning because Cockpit uses a
local certificate. Log in with the Fedora account on the laptop. Allowing the
`cockpit` firewall service makes it reachable from networks that can already
reach the laptop; it does **not** create a router port-forward or make it
publicly available by itself. Do not forward port 9090 through the router.
