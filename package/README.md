# package

Becomes `kits/apollo` in the assembled UniXNU tree.

| Path | Contents |
| --- | --- |
| `ath11k-lx/` | The Mi 10T's side of HakiOS's Linux ath11k build for the QCA6390: the PCIe bus glue, the symbol prefix and two QMI patches. Built by `scripts/mk-ath11k.sh`. |
| `userland/` | HakiOS's apollo boot jobs (`rc.jobs`), the firmware layout of its small image (`firmware.sh`) and its environment (`env.sh`). They describe what the iOS side needs at boot; UniXNU's payload does not run them yet. |

From HakiOS, MIT License (`LICENSE.MIT`).
