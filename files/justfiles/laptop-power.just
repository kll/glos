# Battery and sleep settings from recipes/common-laptop-power.yml.
# The logic lives in /usr/libexec/glos-laptop-power; run any of these without
# an option for a menu.

# Show battery health, charge limit, and suspend/hibernate setup
[group("battery")]
battery-status:
    /usr/libexec/glos-laptop-power status

# Set where charging stops. Options: status | 50-100 | on | off | default (80)
[group("battery")]
battery-charge-limit ACTION="":
    /usr/libexec/glos-laptop-power charge-limit {{ ACTION }}

# Set how long the laptop sleeps on battery before hibernating. Options: status | <time, e.g. 90min, 4h> | default (2h)
[group("battery")]
hibernate-delay ACTION="":
    /usr/libexec/glos-laptop-power hibernate-delay {{ ACTION }}

# Choose whether suspend hibernates later on battery. Options: status | enable | disable
[group("battery")]
suspend-then-hibernate ACTION="":
    /usr/libexec/glos-laptop-power suspend-then-hibernate {{ ACTION }}
