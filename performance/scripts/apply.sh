#!/bin/bash
# Apply runtime without full install (for testing)
set -e
echo "Applying sysctl..."
sudo sysctl -p "$HOME/.config/performance/sysctl.d/99-performance.conf" 2>&1 | head -10
echo "Setting governors performance..."
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance | sudo tee "$f" >/dev/null 2>&1 || true; done
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo "PipeWire quantum -> 1024..."
pw-metadata -n settings 0 clock.quantum 1024 2>&1 | head -5 || true
pw-metadata -n settings 0 clock.min-quantum 256 2>&1 | head -5 || true
echo "Done"
