#!/bin/bash
# Pull the Mi 10T's (apollo) own firmware out of its Android into .cache/firmware/<kind>/ of this device
# repository (ignored by git: it is the vendor's). proprietary-files.txt lists every file, its source and hash.
# The phone is on adb, in Android. What the phone does not have is said, not fatal.
set -e
cd "$(dirname "$0")/.."
pull() { # DIR SOURCE...  (missing files are told, not fatal)
	local dir=$1; shift
	mkdir -p "$dir"
	for f in "$@"; do adb pull "$f" "$dir/" >/dev/null 2>&1 || echo "pull-firmware.sh: $f: not on the phone"; done
	echo "pull-firmware.sh: $dir: $(ls -1 "$dir" | wc -l | tr -d ' ') files"
}
first() { # DIR NAME PLACE...: NAME from the first PLACE that has it
	local dir=$1 name=$2; shift 2
	mkdir -p "$dir"
	for p in "$@"; do adb pull "$p/$name" "$dir/" >/dev/null 2>&1 && return 0; done
	echo "pull-firmware.sh: $name: in none of $*"
}
on_phone() { adb shell ls "$@" 2>/dev/null | tr -d '\r'; }
adb get-state >/dev/null
# Most of it is readable only as root (SELinux): LineageOS's "Rooted debugging" (Developer options) lets adbd run as root
if [ "$(adb shell id -u 2>/dev/null | tr -d '\r')" != 0 ]; then
	adb root >/dev/null 2>&1 && sleep 3 && adb wait-for-device
	[ "$(adb shell id -u 2>/dev/null | tr -d '\r')" = 0 ] ||
		echo "pull-firmware.sh: adb is not root: turn on Settings > System > Developer options > Rooted debugging (LineageOS); most files will be missing"
fi
# the GPU's: the Adreno 650's microcode and its zap shader (hakios.apollo_adreno.c)
pull .cache/firmware/gpu $(on_phone /vendor/firmware/a650_gmu.bin /vendor/firmware/a650_sqe.fw /vendor/firmware/a650_zap.*)
# the audio DSP's image (hakios.apollo_adsp.c) and the CS35L41 amplifiers' protection firmware (hakios.apollo_cs35l41.c)
pull .cache/firmware/audio $(on_phone /vendor/firmware_mnt/image/adsp.*) /vendor/firmware/cs35l41-dsp1-spk-prot-revb2.wmfw \
	/vendor/firmware/cs35l41-dsp1-spk-prot-revb2.bin /vendor/firmware/cs35l41-dsp1-spk-prot-RCV-revb2.bin
# the main microphone's path 1 (hakios.apollo_mic.c): Xiaomi's ACDB (world-readable, no root needed), and out of it
# the device path's topology and calibration (scripts/acdb-mic.py: mic_topology_v2/v1/legacy.bin,
# mic_audproc.bin)
pull .cache/firmware/audio/acdb /vendor/etc/acdbdata/Tutu/Tutu_Handset_cal.acdb /vendor/etc/acdbdata/Tutu/Tutu_Global_cal.acdb
if [ -f .cache/firmware/audio/acdb/Tutu_Handset_cal.acdb ] && [ -f .cache/firmware/audio/acdb/Tutu_Global_cal.acdb ]; then
	python3 scripts/acdb-mic.py .cache/firmware/audio/acdb/Tutu_Handset_cal.acdb \
		.cache/firmware/audio/acdb/Tutu_Global_cal.acdb .cache/firmware/audio ||
		echo "pull-firmware.sh: acdb-mic.py failed: the microphone keeps to path 0"
fi
# the vibration motor's waveforms (hakios.apollo_haptic.c; Android's ueventd loads it from /vendor/firmware)
pull .cache/firmware/haptic /vendor/firmware/aw8697_haptic.bin
# the touch chip's (hakios.apollo_touch.c): Android's kernel has it built in, so it is usually not a file on the phone
first .cache/firmware/touch novatek_nt36675_j3s_fw01.bin /vendor/firmware /vendor/etc/firmware
if [ ! -f .cache/firmware/touch/novatek_nt36675_j3s_fw01.bin ]; then
	# ... so it is taken out of the kernel in the boot partition (scripts/touch-fw-from-boot.py; root)
	tmp=$(mktemp -d)
	if adb shell 'dd if=/dev/block/by-name/boot of=/data/local/tmp/hakios-boot.img bs=1M 2>/dev/null' &&
	    adb pull /data/local/tmp/hakios-boot.img "$tmp/boot.img" >/dev/null 2>&1; then
		python3 scripts/touch-fw-from-boot.py "$tmp/boot.img" .cache/firmware/touch/novatek_nt36675_j3s_fw01.bin ||
			echo "pull-firmware.sh: the touch firmware was not found in the boot image"
	else
		echo "pull-firmware.sh: the boot partition could not be read (root is needed): no touch firmware"
	fi
	adb shell rm -f /data/local/tmp/hakios-boot.img >/dev/null 2>&1
	rm -rf "$tmp"
fi
# the Wi-Fi's: the phone's board file and regulatory database (the place to be checked on another build of Android)
first .cache/firmware/wifi bd_j3s.elf /vendor/firmware_mnt/image/qca6390 /vendor/firmware/qca6390 /vendor/firmware /vendor/firmware/wlan/qca_cld
first .cache/firmware/wifi regdb.bin /vendor/firmware_mnt/image/qca6390 /vendor/firmware/qca6390 /vendor/firmware /vendor/firmware/wlan/qca_cld
# ... and the chip's own firmware, the phone's: amss20.bin (WLAN.HST.1.0.1.r1-01134, the one the port was brought up with;
# linux-firmware's amss.bin is another build, for PCs) as amss.bin, and m3.bin
if [ ! -f .cache/firmware/wifi/amss.bin ]; then
	adb pull /vendor/firmware_mnt/image/qca6390/amss20.bin .cache/firmware/wifi/amss.bin >/dev/null 2>&1 ||
		echo "pull-firmware.sh: amss20.bin: not on the phone"
fi
first .cache/firmware/wifi m3.bin /vendor/firmware_mnt/image/qca6390
# ... and board-2.bin, which Android does not have: from linux-firmware (ath11k/QCA6390/hw2.0)
LF=https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/ath11k/QCA6390/hw2.0
[ -f .cache/firmware/wifi/board-2.bin ] || curl -sfL -o .cache/firmware/wifi/board-2.bin "$LF/board-2.bin" ||
	echo "pull-firmware.sh: board-2.bin: not fetched from linux-firmware"
echo "pull-firmware.sh: .cache/firmware/wifi: $(ls -1 .cache/firmware/wifi | wc -l | tr -d ' ') files"
# Bluetooth: the QCA6390's patch and NVM files live in the bluetooth partition, a FAT image (host needs mtools)
bt=$(adb shell 'readlink -f /dev/block/by-name/bluetooth' 2>/dev/null | tr -d '\r')
if [ -n "$bt" ] && command -v mcopy >/dev/null; then
	mkdir -p .cache/firmware/bluetooth
	img=$(mktemp)
	adb exec-out "dd if=$bt bs=1048576 2>/dev/null" > "$img" &&
		mcopy -n -o -i "$img" ::/image/htbtfw20.tlv ::/image/htnv20.bin .cache/firmware/bluetooth/ ||
		echo "pull-firmware.sh: bluetooth: htbtfw20.tlv/htnv20.bin not read"
	rm -f "$img"
else
	echo "pull-firmware.sh: bluetooth: no bluetooth partition or no mtools (mcopy)"
fi
echo "pull-firmware.sh: done; the Wi-Fi also wants .cache/firmware/wifi/network (the network's name and passphrase, two lines)"
