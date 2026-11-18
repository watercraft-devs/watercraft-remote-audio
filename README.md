# Watercraft Remote Audio

## Simple High Fidelity Remote Audio 

Independant of any init system, it uses `pactl`, `parec`, and `pulseaudio`.

Connects via SSH, easily toggle-able, with an autostart setup out of the box.

## Requirements

Tested on `Devuan Excalibur` and `Watercraft Ketch`

Should work on any Debian or Devuan derived system.

If you are using any other kind of Linux system and experience issues please file a bug report.

## Software Setup

```sh
# 1. Clone from GitHub
git clone https://github.com/watercraft-devs/watercraft-remote-audio
# 2. Go to the clone directory
cd watercraft-remote-audio
# 3 In this version you need to manually change your destination address:
# 3.1  Open ./watercraft-remote-audio.sh in your editor of choice
vim ./watercraft-remote-audio.sh
# 3.2  Edit the line that says `remote=ketch010` 
# change `ketch010` to your destination's user@ipaddr or a pre-configured ssh alias for the destination
# this will be simplified in future versions
```
## Install

```sh
# 1. You can use it from the clone directory like this:
./watercraft-remote-audio.sh -h
# 2. Or you can copy it to your /usr/local/bin/ for convenience
sudo cp ./watercraft-remote-audio.sh /usr/local/bin/watercraft-remote-audio
# 3. If you copied it in the previous step you can use it like this:
watercraft-remote-audio -h
```

## Audio Setup

```sh
# 1. Assuming you followed the `Software Setup` section, 
# setup your remote connection:
watercraft-remote-audio --remote
# 2. If you want autostart, enable that now too:
watercraft-remote-audio autostart
# 3. Start the stream manually:
watercraft-remote-audio --start
# 4. Stop the stream manually:
watercraft-remote-audio --stop
```

## Usage: 


All commands:

watercraft-remote-audio 

- `--start`
- `--stop[--remote]`
- `--remote`
- `autostart[--rm||--kill]`
- `--set-sample-rate`
- `-h`

---
### `-h`
---

Help: just displays basic usage options at the moment.

---
### `--remote` 
---
(run this first)

This command sets up the `audio-sink` script on your remote destination.

This is necessary before any operation whether manual or autostart.

In this version you need to fill in your remote destination manually: 


**IMPORTANT:**

If you did not already, change `remote=ketch010` to `remote=yourRemoteUser@yourRemoteIPAddr`.

You can use a pre-configured ssh alias or `user@ipaddr`. 

If you use it directly from the repo `cd` there and just change it there.

If you already added it to `/usr/local/bin/` either change it directly or change it in  the repo directory and copy it to `/usr/local/bin/` again after the changes.

Future versions will make this simpler.

---
`--start`
---

Manually starts a remote audio stream.

---
`--stop`
---

Manually stops a remote audio stream.

NOTE: if the setup started with autostart, `--stop` won't work properly.

To stop an autostart, you need to run `autostart --kill`

---
`--stop --remote`
---

Manually stop the audio stream on the **remote** side.

This helps with any latency issues that can be experienced after prolonged usage.

Just run `./watercraft-remote-audio --stop --remote && ./watercraft-remote-audio --start`

This creates a fresh ssh session which fixes the latency.


---
`autostart`
---
This will make an autostart for the system that you are on so that every time you boot in remote audio is on automatically.

---
`autostart --rm`
---
This will remove the autostart files completely ensuring remote audio does not start every boot.

---
`autostart --kill`
---
This will kill a remote audio stream that was initiated via autostart.

NOTE: it will also kill manual setups and may cause a bug if used to kill manual setups.

The bug may prevent the software from starting properly.

To hot-fix the bug, all you need to do is run `rm ~/.config/watercraft-remote-audio/PIDFILE` and try again.

The proper way to end a manual remote audio stream is `--stop`.

---
`--set-sample-rate`
---
This function is not fully tested although notes are included on how it needs to be handled if you want to try it.

NOTE: this wont work during a stream. `--stop` a manual stream or `autostart --kill` and autostarted stream before running this command in order for it to work smoothly.

This will set the default and alternative sample rate to 48000 (max quality for a Scarlet Focusrite audio interface) and then set the highest quality resample method `soxr-vhq` in order to maximize the fidelity of the streamed audio.

As mentioned above it needs improvement, it will be updated in the future otherwise contributions are welcomed.
## License

**GPL 3.0**



