# uncomment force_color_prompt=yes line in .bashrc
if [ $(grep "^#force_color_prompt=yes" $HOME/.bashrc | wc -l) != 0 ]; then
	sed -i s/^#force_color_prompt=yes/force_color_prompt=yes/ $HOME/.bashrc
fi

# to use Ctrl-s
stty -ixon

# force TERM environment to xterm-256color when we are in gnome-terminal
if [ $(ps -p $PPID o comm | grep gnome-terminal | wc -l) == 1 ]; then
	# we are in gnome-terminal.
	# gnome-terminal does not set TERM to xterm-256color
	export TERM=xterm-256color
else
	# we are not in gnome-terminal.
	:
fi

# Ensure some directories exist.
if [ ! -d $HOME/.local/bin ]; then
	mkdir -p $HOME/.local/bin
fi
if [ ! -d $HOME/.local/share/man ]; then
	mkdir -p $HOME/.local/share/man
fi
if [ ! -d $HOME/.local/share/info ]; then
	mkdir -p $HOME/.local/share/info
fi

# Set some paths
if [[ ! ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
	PATH=$HOME/.local/bin:$PATH
	export PATH
fi
if [[ ! ":$(manpath):" == *":$HOME/.local/share/man:"* ]]; then
	unset MANPATH
	MANPATH=$HOME/.local/share/man:$(manpath)
	export MANPATH
fi
if [[ ! ":$INFOPATH:" == *":$HOME/.local/share/info:"* ]]; then
	INFOPATH=$HOME/.local/share/info:$INFOPATH
	export INFOPATH
fi

# Functions
# #########
function rmoldkernel () {
	local cur_kernel=$(uname -r|sed 's/-*[a-z]//g'|sed 's/-386//g')
	local kernel_pkg="linux-(image|image-extra|headers|ubuntu-modules|restricted-modules)"
	local meta_pkg="${kernel_pkg}-(generic|i386|virtual|server|common|rt|xen|ec2|amd64)"
	local latest_kernel=$(dpkg -l linux-image-* | grep -E linux-image-[0-9] | awk '/^ii/{ print $2}' | grep -E [0-9] | tail -1 | cut -f3,4 -d"-")
	sudo aptitude purge -y $(dpkg -l | grep -E $kernel_pkg | grep -v -E "${cur_kernel}|${meta_pkg}|${latest_kernel}" | awk '{print $2}')
	sudo rm -rfv $(find /lib/modules/* -maxdepth 0 | grep -v -E "${cur_kernel}|${latest_kernel}" | awk '{print $1}')
	sudo update-grub2
}

function purgeremovedpkgs () {
	sudo aptitude -y purge `dpkg --get-selections | grep deinstall | cut -f1`
}

function updatepackages () {
	retry sudo aptitude update && retry sudo aptitude -d -y full-upgrade && sudo aptitude -y full-upgrade
}

if [ -f /usr/bin/vmware-config-tools.pl ]; then
	function reconfigurevmwaretools () {
		sudo vmware-config-tools.pl --clobber-kernel-modules=vmblock,vmhgfs,vmmemctl,vmxnet,vmci,vsock,vmsync,pvscsi,vmxnet3,vmwsvga --default
	}
fi

function retry () {
	nTrys=0
	maxTrys=20
	delayBtwnTrys=5
	status=256
	until [ $status == 0 ] ; do
		$*
		status=$?
		nTrys=$(($nTrys + 1))
		if [ $nTrys -gt $maxTrys ] ; then
			echo "Number of re-trys exceeded. Exit code: $status"
			exit $status
		fi
		if [ $status != 0 ] ; then
			echo "Failed (exit code $status)... retry $nTrys"
			sleep $delayBtwnTrys
		fi
	done
}

# Aliases
# #######
# Some example alias instructions
# If these are enabled they will be used instead of any instructions
# they may mask. For example, alias rm='rm -i' will mask the rm
# application. To override the alias instruction use a \ before, ie
# \rm will call the real rm not the alias.
# Interactive operation...
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Default to human readable figures
alias df='df -h'
alias du='du -h'
alias ls='ls -hF --color=auto'

# astyle options
alias astyle='astyle --style=break --indent=force-tab=4 --unpad-paren --pad-header --pad-oper --unpad-paren --align-pointer=name --align-reference=name'

# mc options
#type -p -a mc > /dev/null && alias mc='. /usr/share/mc/bin/mc-wrapper.sh -a'
if type -p -a mc > /dev/null; then
	case "$TERM" in
		screen-256color)
			alias mc='TERM=screen . /usr/share/mc/bin/mc-wrapper.sh -a -x'
			;;
		*)
			alias mc='. /usr/share/mc/bin/mc-wrapper.sh -a'
			;;
	esac
fi

#  vim: set ft=sh ts=4 sw=4 tw=0 noet :
