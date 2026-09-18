# Talos patches

Place reusable Talos machine-configuration patches here. Generated machine
configurations and per-node hostname patches are written to `../generated/` and
must not be committed because they include cluster secrets.

Example patch usage:

```powershell
talosctl apply-config --nodes 192.168.56.10 `
  --file .\talos\generated\controlplane.yaml `
  --config-patch '@.\talos\patches\example.yaml'
```

