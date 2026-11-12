# UniXNU-apollo

UniXNU device repository for the Xiaomi Mi 10T / Mi 10T Pro / Redmi K30S Ultra (`apollo`,
Qualcomm SM8250), targeting iOS 16.5 (20F66).

Status: **format 2 configuration and hardware description in place; no UniXNU build and no
UniXNU device boot yet.** The port comes from [HakiOS](https://github.com/oosexgang/hackios-xnu-kernel),
where iOS 16.5 reaches the home screen on this phone with touch, GPU-accelerated UI, speakers,
both microphones, vibration, Wi-Fi, battery and brightness. The porting record
([porting.toml](porting.toml)) is the authoritative statement of what is measured, what is
planned and what is blocked.

| Repository | Role |
| --- | --- |
| [UniXNU](https://github.com/UniXNU/UniXNU) | Build tools, components, ARM64 profile |
| [UniXNU-sm8250-common](https://github.com/Pistachio-Project/UniXNU-sm8250-common) | Shared SM8250 DTSI, config and patches |
| [uefi-apollo](https://github.com/Pistachio-Project/uefi-apollo) | Mu-Silicium firmware with apolloPkg, UniXNU and DarwinBoot |
| this repository | Board DTS, components, firmware list, iOS 16.5 profile, HakiOS driver patches |

## Layout

| Path | Contents |
| --- | --- |
| `board.toml` | Board, SoC, OS profile, components, firmware, payload |
| `feeds.toml` | Pinned SoC source and XNU 8796.121.2 |
| `configs/apollo_defconfig` | Kernel configuration |
| `dts/apollo.dts` | Memory, reserved regions, CPUs, board wiring notes |
| `os-profiles/ios-16.5-20F66/` | iOS 16.5 OS profile, until it is in UniXNU's `profiles/os/` |
| `patches/xnu/` | HakiOS's apollo drivers and hooks, carried but not yet in the series |
| `package/` | HakiOS's ath11k glue and boot jobs |
| `scripts/` | Firmware pull, partition carving, mic calibration, touch firmware, packaging |
| `proprietary-files.txt` | The phone's firmware: path, source, SHA-256, consumer |

## Build

Siblings in one directory: `UniXNU`, `UniXNU-apollo`, `UniXNU-sm8250-common`, `uefi-apollo`.
Host tools: [requirements](https://unixnu.com/guide/requirements), including `dtc`.

```sh
scripts/pull-firmware.sh             # phone in LineageOS, USB debugging + rooted debugging
scripts/install-os-profile.sh        # links os-profiles/ into ../UniXNU/profiles/os/
cd ../UniXNU
./unixnu defconfig apollo_defconfig -D ../UniXNU-apollo
./unixnu fetch -D ../UniXNU-apollo
./unixnu status --json -D ../UniXNU-apollo
python3 scripts/porting-record.py check --device ../UniXNU-apollo
```

The kernel step does not succeed yet: UniXNU's ARM64 patch series targets xnu-10063, and its
xnu-8796 versions are pending (porting.toml, `packaging`). Then follow
[Building](https://unixnu.com/building): kernel, package, firmware, payload, boot image, or
`scripts/package.sh --os ios-16.5-20F66 --uefi ../uefi-apollo`.

## Read

[Port a device](https://unixnu.com/porting/), [migration](https://unixnu.com/porting/migration),
[device repository](https://unixnu.com/porting/device-repository),
[device tree](https://unixnu.com/porting/device-tree), [records](https://unixnu.com/porting/records).

Licenses by directory: see [NOTICE](NOTICE).
