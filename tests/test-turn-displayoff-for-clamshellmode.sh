#!/usr/bin/env bash
set -euo pipefail

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../scripts" && pwd)
script="$script_dir/clamshell-display-power"

mkdir -p "$root/drm/card0-eDP-1/device" "$root/drivers/nouveau" "$root/bin" "$root/run"
ln -s "$root/drivers/nouveau" "$root/drm/card0-eDP-1/device/driver"
printf 'connected\n' > "$root/drm/card0-eDP-1/status"
printf '42\n' > "$root/drm/card0-eDP-1/connector_id"
printf 'state:      closed\n' > "$root/lid-state"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\\n" "$*" >> "$MODETEST_LOG"' > "$root/bin/modetest"
chmod +x "$root/bin/modetest"

common_env=(
  "DRM_ROOT=$root/drm"
  "LID_STATE_FILE=$root/lid-state"
  "MODETEST_BIN=$root/bin/modetest"
  "MODETEST_LOG=$root/modetest.log"
  "STATE_DIR=$root/run"
)

# A closed lid must explicitly request DPMS Off for the connected internal panel.
env "${common_env[@]}" "$script" apply
grep -Fx -- '-M nouveau -w 42:DPMS:Off' "$root/modetest.log"

# Opening the lid must restore DPMS On.
printf 'state:      open\n' > "$root/lid-state"
rm -f "$root/run/last-state"
env "${common_env[@]}" "$script" apply
grep -Fx -- '-M nouveau -w 42:DPMS:On' "$root/modetest.log"

# Status must be read-only and work even when modetest is absent.
rm -f "$root/bin/modetest"
env "${common_env[@]}" "$script" status | grep -F 'Dependency: modetest is missing'
