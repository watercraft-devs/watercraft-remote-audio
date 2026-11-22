#!/bin/bash
VERSION=0.1.1
CONFIGDIR="$HOME/.config/watercraft-remote-audio"
mkdir -p "$CONFIGDIR"
PIDFILE="$CONFIGDIR"/PIDFILE
REMOTEPATH="$CONFIGDIR/remote"

check_remote() {
	if [  ! -f "$REMOTEPATH" ]; then 
		printf "No remote destination set!\nSet it with:\nwatercraft-remote-audio --configure\nand then retry.\n"
		exit 1 
	fi
}

if [ -f "$REMOTEPATH" ]; then 
	remote=$(cat "$REMOTEPATH")
fi


kill_autostart() {
	pkill -f remote-audio-routing; pkill parec
	printf "NOTE: This kills the entire setup no matter how its used currently because it kills parec\n"
	# thats why this has to rm "$PIDFILE"
	if [[ -f "$PIDFILE" ]]; then
		rm "$PIDFILE"
	fi
}


write_remote_audio_routing() {
	check_remote
cat > ~/bin/remote-audio-routing <<-EOF
#!/bin/sh
# script called by autostart
# Stream desktop audio to the laptop. Retries every 5 s while the laptop is unreachable.
while :; do
    parec -d "$(pactl get-default-sink).monitor" --format=s32le --rate=48000 --channels=2 --latency-msec=20 \\
      | ssh -T -o BatchMode=yes -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 \\
            $remote '~/bin/audio-sink'
    sleep 5
done
EOF
}



make_autostart() {
	if [[ ! -f ~/bin/remote-audio-routing ]]; then
		write_remote_audio_routing	
		printf "Wrote ~/bin/remote-audio-routing\n"
	else
		printf "remote-audio-routing file already in place...\n"
	fi
	if [[ -f ~/.config/autostart/remote-audio-routing.desktop ]]; then
		printf "autostart .desktop was already configured...\n"
		return 0
	fi

	cat > ~/.config/autostart/remote-audio-routing.desktop <<-EOF
	[Desktop Entry]
	Type=Application
	Name=Remote audio stream
	Exec=$HOME/bin/remote-audio-routing
	X-GNOME-Autostart-enabled=true
	EOF

	printf "autostart configured!\n"
}


rm_autostart() { 
	rm ~/.config/autostart/remote-audio-routing.desktop
	printf "NOTE: this only stops the next autostart, to kill the current stream run %s autostart --kill\n" "$0"
}


set_sample_rate() {
	mkdir -p ~/.config/pulse
	# also sets the sample format and resample method
	cat >> ~/.config/pulse/daemon.conf <<'EOF' 
	default-sample-format = s32le 
	default-sample-rate = 48000
	alternate-sample-rate = 48000
	resample-method = soxr-vhq
EOF
	# TODO
	# if changing mid stream this has to be considered:
	# Each end fixes the rate when it starts, so changing it means a restart in this order:

#Stop the stream: pkill -f laptop-audio; pkill -x parec
#Change the rate in all three places so nothing gets resampled:
#desktop ~/.config/pulse/daemon.conf: default-sample-rate and alternate-sample-rate
#desktop stream command: parec --rate=
#laptop ~/bin/audio-sink: aplay -r and pacat --rate=
#Restart PulseAudio on the desktop: pulseaudio -k. It restarts on its own and picks up the new daemon.conf.
#Check it took effect: pactl list short sinks should show the new rate.
#Start the stream again.
}


ssh_script_remote() {
	check_remote
	ssh "$remote" 'mkdir -p ~/bin && cat > ~/bin/audio-sink && chmod +x ~/bin/audio-sink' <<'EOF'
#!/bin/sh
# Play raw 48 kHz s32le stereo from stdin.
# Logged in: go through PulseAudio. Not logged in: straight to ALSA.
if pactl info >/dev/null 2>&1; then
    exec pacat --playback --raw --format=s32le --rate=48000 --channels=2 --latency-msec=300
else
    exec aplay -q -t raw -f S32_LE -r 48000 -c 2 --buffer-time=300000 -D plughw:CARD=Gen,DEV=0
fi
EOF
}


start_manual_routing() {
	check_remote
	if  ssh "$remote" 'test -x ~/bin/audio-sink'; then
		printf ""
	else
		printf "Run:\n%s --remote\nfirst before starting!\n" "$0"
		return 0
	fi
	printf "Starting...\n"
	if [ -f "$PIDFILE" ]; then
		if kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then # check if "$PIDFILE" is really active
			printf "Already started!\n"
		else
			rm "$PIDFILE" #not active, rm "$PIDFILE"
		fi
	fi
	sh -c \
		'printf "%s\n" "$$" > "$1"; \
		exec parec -d "$(pactl get-default-sink).monitor" \
		--format=s32le --rate=48000 --channels=2 --latency-msec=20' \
		sh "$PIDFILE" 2>> "$HOME/.cache/audio-send.log" | \
		ssh "$remote" '~/bin/audio-sink' >>"$HOME/.cache/audio-send.log" 2>&1 &
}


stop_manual_routing() {
	if [ ! -f "$PIDFILE" ]; then
		printf "Has not been started yet!\n"
		return 0
	fi
	printf "Stopping.\n"
	kill "$(cat $PIDFILE)" && rm -f "$PIDFILE"
	printf "If it reports no such process, you may be trying to kill an auto start.\n"
	printf "Kill the autostart like this:\nwatercraft-remote-audio autostart --kill\n"
}

stop_remote(){
	check_remote
	# ssh into remote and stop aplay or pacat
	if aplay_pid=$(ssh "$remote" 'pgrep -n -x aplay'); then
		ssh "$remote" "pkill $aplay_pid"
		ssh "$remote" 'pkill aplay'
	fi
	if pacat_pid=$(ssh "$remote" 'pgrep -n -x pacat'); then
		ssh "$remote" "pkill $pacat_pid"
		ssh "$remote" 'pkill pacat'
	fi
}

refresh_stream() {
	check_remote
	stop_remote
	start_manual_routing
}

configure() {
	read -p "Enter the remote destination (user@ipaddr or ssh-alias): " destination
	echo "$destination" > "$CONFIGDIR/remote"
}


version() {
	printf "watercraft-remote-audio version: $VERSION\n"
}

usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS] <source> [dest...]

Simple high fidelity remote audio over ssh

Options:
  --start		Start a remote audio stream
  --stop		Stop an ongoing remote audio stream
  --refresh		Refresh the stream 
  --remote		Send the audio stream listener script to the remote destination
  --remote --stop	Kills the audio stream listener on the remote destination
  autostart		Makes it so the audio stream starts automatically at boot
  autostart --rm	Remove the autostart files so it won't start automatically anymore
  autostart --kill	Kills the entire setup( manual too). 
			Only way to stop an autostart right now. A go-to killswitch for the setup.
  --set-sample-rate	Set sample rate to 48000. (needs more testing)
  --version		Show the version number.
  --help		Show the usage screen (this screen).

Quickstart:
  ${0##*/} --configure 
  ${0##*/} --remote
  ${0##*/} --start 
EOF
}

# TODO --configure set the remote dest in a file in ~/.config/watercraft-remote-audio/remote

case "$1" in
	--configure)
		configure
		exit 0;;
	--refresh)
		refresh_stream
		exit 0;;
	--start)
		start_manual_routing
		exit 0 ;;
	--stop)
		case "$2" in
			--remote)
				stop_remote
				exit 0 ;;
			*)
				stop_manual_routing
				exit 0 ;;
		esac
	        stop_manual_routing
		exit 0 ;;
	--remote)
		ssh_script_remote
		exit 0 ;;		
	autostart)
		case "$2" in
			--rm)
				rm_autostart
				exit 0 ;;
			--kill)
				kill_autostart
				exit 0 ;;
			*)
				make_autostart
				exit 0 ;;
		esac 
		make_autostart
		exit 0 ;;
	--set-sample-rate)
		set_sample_rate
		exit 0 ;;
	-v|--version|version)
		version
		exit 0 ;;
	-h|--help|help)
		usage
                exit 1 ;;
	*)
		usage
		exit 1 ;;
esac

