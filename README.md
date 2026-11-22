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

## Setup 

```sh
# 1. Set your remote destination. 
watercraft-remote-audio --configure
# 2. Send the audio receiver script there.
watercraft-remote-audio --remote
# 2. If you want autostart, enable that now too:
watercraft-remote-audio autostart
# 3. Start the stream manually:
watercraft-remote-audio --start
# 4. Stop the stream manually:
watercraft-remote-audio --stop
```

## Usage: 


Usage: ${0##*/} [OPTIONS] <source> [dest...]

Simple high fidelity remote audio over ssh

Options:
  --start               Start a remote audio stream
  --stop                Stop an ongoing remote audio stream
  --refresh             Refresh the stream 
  --remote              Send the audio stream listener script to the remote destination
  --remote --stop       Kills the audio stream listener on the remote destination
  autostart             Makes it so the audio stream starts automatically at boot
  autostart --rm        Remove the autostart files so it won't start automatically anymore
  autostart --kill      Kills the entire setup( manual too). 
                        Only way to stop an autostart right now. A go-to killswitch for the setup.
  --set-sample-rate     Set sample rate to 48000. (needs more testing)
  --version             Show the version number.
  --help                Show the usage screen (this screen).


---
### `-h`
---

Help: just displays basic usage options at the moment.

---
### `--configure` 
---
Set your remote destination.

It can be a user@ipaddr or a ssh-alias.

---
### `--remote` 
---

This command sets up the `audio-sink` script on your remote destination.

This is necessary before any operation whether manual or autostart.

In this version you need to fill in your remote destination manually: 


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
`--refresh`
---

Refreshes the ssh session by stopping the remote stream and then restarting it from the local system.

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



