# All Of Create - Aeronautics Podman Server

Rootless Podman setup for the All Of Create - Aeronautics Minecraft modpack, with a playit.gg sidecar tunnel.

## Images

The Quadlet units pull images from GHCR:

```text
ghcr.io/tb516/aoc-aeronautics-minecraft:latest
ghcr.io/playit-cloud/playit-agent:0.17
```

The GitHub Actions workflow builds and publishes the Minecraft image to GHCR on pushes to `main` and manual runs. The playit sidecar uses the official playit agent image.

## Runtime Layout

Persistent files live under the user running the rootless systemd services:

```text
$HOME/aoc-aeronautics/
  server/
  secrets/
```

The Minecraft world is stored in:

```text
$HOME/aoc-aeronautics/server/world
```

## playit Secret

Create the playit environment file:

```bash
mkdir -p "$HOME/aoc-aeronautics/secrets"
cp playit.env.example "$HOME/aoc-aeronautics/secrets/playit.env"
chmod 600 "$HOME/aoc-aeronautics/secrets/playit.env"
```

Edit `$HOME/aoc-aeronautics/secrets/playit.env` and set your playit `SECRET_KEY`.

## Install Quadlet Units

```bash
mkdir -p "$HOME/.config/containers/systemd"
cp quadlet/* "$HOME/.config/containers/systemd/"
systemctl --user daemon-reload
```

## Start The Stack

```bash
systemctl --user start aoc-aeronautics-pod.service
```

Enable on user login:

```bash
systemctl --user enable aoc-aeronautics-pod.service
```

Start at boot without an interactive login:

```bash
loginctl enable-linger "$USER"
```

## Logs

```bash
journalctl --user -u aoc-minecraft.service -f
journalctl --user -u aoc-playit.service -f
```

## Local Connection

The pod publishes Minecraft locally on:

```text
localhost:25565
```

Configure the playit tunnel target as:

```text
127.0.0.1:25565
```

## Stop And Restart

```bash
systemctl --user stop aoc-aeronautics-pod.service
systemctl --user start aoc-aeronautics-pod.service
```

## Backup The World

```bash
tar -czf "$HOME/aoc-aeronautics-world-$(date +%Y%m%d-%H%M%S).tar.gz" \
  -C "$HOME/aoc-aeronautics/server" world
```

## Notes

The Minecraft container runs as root inside a rootless Podman user namespace. That maps to the unprivileged host user and keeps `$HOME/aoc-aeronautics/server` writable without requiring host root ownership.
