# Device agent guide

This repository owns the apollo board DTS, peripheral wiring, component selections,
firmware inputs, partition layout, packaging, and the iOS 16.5 OS profile until it is
upstream in UniXNU.

## Read first

| Task | Required reading |
| --- | --- |
| Every change | This README, `porting.toml`, [Porting](https://unixnu.com/porting/), [device repository](https://unixnu.com/porting/device-repository), [component catalog](https://unixnu.com/reference/components) |
| Hardware | [Device tree](https://unixnu.com/porting/device-tree), UniXNU-sm8250-common README, AGENTS and `dts/sm8250.dtsi` |
| Kernel | [Source and patches](https://unixnu.com/xnu/source-and-patches), `os-profiles/ios-16.5-20F66/`, `patches/xnu/series` |
| Images | [Prelink](https://unixnu.com/concepts/prelink), [payload](https://unixnu.com/concepts/payload), [UEFI](https://unixnu.com/porting/uefi-firmware), uefi-apollo README |
| Verification | [Building](https://unixnu.com/building), [bring-up](https://unixnu.com/porting/bring-up), [log capture](https://unixnu.com/porting/log-capture) |

## Rules

- Hardware values come from this phone: the uefi-apollo memory map, the phone's device tree,
  or a HakiOS driver that drives it. Name the source in a comment.
- SoC-wide resources and operations go to UniXNU-sm8250-common; reusable drivers go to
  component repositories. The HakiOS drivers in `patches/xnu/0001` move out one at a time
  (porting.toml lists each destination).
- The kernel is xnu-8796.121.2 (iOS 16.5). Patches written for xnu-10063 do not apply; state
  the XNU version every patch was checked on.
- No iOS files and no firmware in git. Firmware goes in `.cache/firmware` and
  `proprietary-files.txt` records its source and hash.
- Every code change updates the owning `porting.toml` area's findings or evidence. Host and
  device results are separate evidence entries with the full commit.
- Keep the license of each directory (NOTICE): APSL for `patches/xnu`, MIT for HakiOS
  scripts and `package/`, BSD-2-Clause-Patent for new files.

## Commands

```sh
scripts/install-os-profile.sh
cd ../UniXNU
./unixnu defconfig apollo_defconfig -D ../UniXNU-apollo
./unixnu status --json -D ../UniXNU-apollo
python3 scripts/porting-record.py check --device ../UniXNU-apollo
```

Report commands, revisions, output paths, results and unresolved inputs. Report boot,
storage, display, input, GPU, network, audio and power results separately.
