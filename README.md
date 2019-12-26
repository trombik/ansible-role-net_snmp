# `trombik.net_snmp`

`ansible` role for `net-snmp`.

# Requirements

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `net_snmp_package` | Package name of `net-snmp` | `{{ __net_snmp_package }}` |
| `net_snmp_service` | Service name of `net-snmp` | `{{ __net_snmp_service }}` |
| `net_snmp_extra_packages` | A list of extra packages to install | `{{ __net_snmp_extra_packages }}` |
| `net_snmp_config_dir` | Path to the configuration directory | `{{ __net_snmp_config_dir }}` |
| `net_snmp_config_file` | Path to `snmpd.conf` | `{{ net_snmp_config_dir }}/snmpd.conf` |
| `net_snmp_config` | Content of `snmpd.conf` | `""` |
| `net_snmp_snmp_config_file` | Path to `snmp.conf` | `{{ net_snmp_config_dir }}/snmp.conf` |
| `net_snmp_snmp_config` | Content of `snmp.conf` | `""` |
| `net_snmp_flags` | See below | `""` |

## `net_snmp_flags`

This variable is used for overriding defaults for startup scripts. In Debian
variants, the value is the content of `/etc/default/net_snmp`. In RedHat
variants, it is the content of `/etc/sysconfig/net_snmp`. In FreeBSD, it
is the content of `/etc/rc.conf.d/net_snmp`. In OpenBSD, the value is
passed to `rcctl set netsnmpd`.

## Debian

| Variable | Default |
|----------|---------|
| `__net_snmp_service` | `snmpd` |
| `__net_snmp_package` | `snmpd` |
| `__net_snmp_extra_packages` | `["snmp", "snmp-mibs-downloader"]` |
| `__net_snmp_config_dir` | `/etc/snmp` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__net_snmp_service` | `snmpd` |
| `__net_snmp_package` | `net-mgmt/net-snmp` |
| `__net_snmp_extra_packages` | `[]` |
| `__net_snmp_config_dir` | `/usr/local/etc/snmp` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__net_snmp_service` | `netsnmpd` |
| `__net_snmp_package` | `net-snmp` |
| `__net_snmp_extra_packages` | `[]` |
| `__net_snmp_config_dir` | `/etc/snmp` |

## RedHat

| Variable | Default |
|----------|---------|
| `__net_snmp_service` | `snmpd` |
| `__net_snmp_package` | `net-snmp` |
| `__net_snmp_extra_packages` | `["net-snmp-utils"]` |
| `__net_snmp_config_dir` | `/etc/snmp` |

# Dependencies

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - ansible-role-net_snmp
  pre_tasks:
    - name: Dump all hostvars
      debug:
        var: hostvars[inventory_hostname]
  post_tasks:
    - name: List all services (systemd)
      # workaround ansible-lint: [303] service used in place of service module
      shell: "echo; systemctl list-units --type service"
      changed_when: false
      when:
        # in docker, init is not systemd
        - ansible_virtualization_type != 'docker'
        - ansible_os_family == 'RedHat' or ansible_os_family == 'Debian'
    - name: list all services (FreeBSD service)
      # workaround ansible-lint: [303] service used in place of service module
      shell: "echo; service -l"
      changed_when: false
      when:
        - ansible_os_family == 'FreeBSD'
  vars:
    os_net_snmp_flags:
      FreeBSD: |
        snmpd_flags="-a"
        snmpd_conffile="{{ net_snmp_config_file }}"
      OpenBSD: "-u _netsnmp -r -a"
      Debian: |
        SNMPDOPTS='-Lsd -Lf /dev/null -u Debian-snmp -g Debian-snmp -I -smux,mteTrigger,mteTriggerConf -p /run/snmpd.pid'
        SNMPDRUN=yes
      RedHat: |
        OPTIONS="-LS0-6d"

    net_snmp_flags: "{{ os_net_snmp_flags[ansible_os_family] }}"
    net_snmp_config: |
      syscontact root
      syslocation "somewhere"
      rocommunity public
      mibs :
    net_snmp_snmp_config: ""
```

# License

```
Copyright (c) 2016 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>
