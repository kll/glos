# common-laptop-power

Battery care for laptops: an 80% charge limit, suspend-then-hibernate, and
hibernating at low battery before a deep discharge. Files are in
`files/laptop-power/`.

## What the image ships

| Piece | File | Effect |
| --- | --- | --- |
| Charge limit on | `usr/lib/tmpfiles.d/glos-battery-charge-limit.conf` | Seeds UPower's `charging-threshold-status` with `1` if it is missing |
| Charge window | `usr/lib/udev/rules.d/61-glos-battery-charge-limit.rules` | `CHARGE_LIMIT=75,80`, used when the firmware has no thresholds set |
| Low battery | `etc/UPower/UPower.conf.d/70-glos-battery-care.conf` | Warns at 20% and 10%, hibernates at 7% |
| Suspend mode | `usr/lib/systemd/system/systemd-suspend.service.d/` | Every suspend runs as suspend-then-hibernate |
| Hibernate delay | `usr/lib/systemd/sleep.conf.d/` | On battery, hibernates after 2h; on AC, stays suspended |
| Hibernate target | `glos-hibernate-swap.service`, `var-swap-swapfile.swap` | Creates a RAM-sized swap file in the `/var/swap` btrfs subvolume on first boot |

The firmware stores the charge thresholds, so they also hold while the laptop
is off.

Resume needs no `resume=` karg. systemd-sleep writes the swap file's location
to the `HibernateLocation` EFI variable, and the initrd's
`systemd-hibernate-resume-generator` reads it. Hibernation also needs a kernel
without lockdown. Fedora kernels turn lockdown on under Secure Boot; Bazzite's
kernel currently does not (`cat /sys/kernel/security/lockdown` shows
`[none]`). If a later kernel does turn it on, hibernation is refused and
systemd keeps the laptop suspended instead.

## Checks

```sh
# Charge limit (expect 75 / 80, and "charge-threshold-enabled: yes")
cat /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold
upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -i threshold

# Hibernation swap file (expect /var/swap/swapfile next to zram)
swapon --show

# Test hibernation once, then check the log after resume
systemctl hibernate
journalctl -b -1 -u systemd-suspend.service -u systemd-hibernate.service
```

To check that s2idle reaches the deepest state, read
`/sys/devices/system/cpu/cpuidle/low_power_idle_system_residency_us`, suspend
for a few minutes, and read it again: the number should have grown. If it
stays 0, suspend never reaches the lowest-power state and the battery drains a
few % per hour while asleep.

## Temporary full charge

```sh
busctl call org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_BAT0 \
  org.freedesktop.UPower.Device EnableChargeThreshold b false
# ...later, b true turns it back on. UPower remembers the setting.
```

## Removing the swap file

`sudo systemctl mask var-swap-swapfile.swap`, reboot, then
`sudo btrfs subvolume delete /var/swap`. Without it, suspend-then-hibernate
falls back to staying suspended.
