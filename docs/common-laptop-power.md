# common-laptop-power

Battery care for laptops: an 80% charge limit, suspend-then-hibernate, and
hibernating at low battery before a deep discharge. Files are in
`files/laptop-power/`, and the ujust recipes are in
`files/justfiles/laptop-power.just`.

## ujust commands

Run any of these without an option to get a menu.

| Command | Options |
| --- | --- |
| `ujust battery-status` | Battery health, charge limit, suspend mode, swap file, lockdown, deep-sleep counter |
| `ujust battery-charge-limit` | `status`, `50`–`100` (where charging stops), `off` (charge to 100%), `on`, `default` (80) |
| `ujust hibernate-delay` | `status`, a time span like `90min` or `4h`, `default` (2h) |
| `ujust suspend-then-hibernate` | `status`, `enable`, `disable` (plain suspend, never hibernates) |

A charge limit of N starts charging again below N-5%. `off` and `on` keep the
current window, so `off` before a trip and `on` afterwards gets you back to
the same limit. The settings are written to `/etc` and survive image updates:

- Charge window: `/etc/udev/rules.d/62-glos-battery-charge-limit-local.rules`
- Hibernate delay: `/etc/systemd/sleep.conf.d/60-glos-local-hibernate-delay.conf`
- Plain suspend: `/etc/systemd/system/systemd-suspend.service.d/60-glos-local-plain-suspend.conf`

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
kernel currently does not (`ujust battery-status` shows it). If a later kernel
does turn it on, hibernation is refused and systemd keeps the laptop suspended
instead.

## Checks

```sh
ujust battery-status

# Test hibernation once, then check the log after resume
systemctl hibernate
journalctl -b -1 -u systemd-suspend.service -u systemd-hibernate.service
```

`battery-status` also shows the deep-sleep counter
(`low_power_idle_system_residency_us`). Suspend for a few minutes and run it
again: the number should have grown. If it stays 0, suspend never reaches the
lowest-power state and the battery drains a few % per hour while asleep.

## Removing the swap file

`sudo systemctl mask var-swap-swapfile.swap`, reboot, then
`sudo btrfs subvolume delete /var/swap`. Without it, suspend-then-hibernate
falls back to staying suspended.
