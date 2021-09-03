#!/bin/sh
#
# $ devdev.sh $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2021 Tomi Ollila
#	    All rights reserved
#
# Created: Mon 02 Aug 2021 18:04:22 EEST too
# Last modified: Thu 02 Sep 2021 16:35:45 +0300 too

# Note: started with Makefile, but got "make: not found" (minimal deps FTW)

# SPDX-License-Identifier: 0BSD


case ${BASH_VERSION-} in *.*) set -o posix; shopt -s xpg_echo; esac
case ${ZSH_VERSION-} in *.*) emulate ksh; esac

set -euf  # hint: sh -x thisfile [args] to trace execution

saved_IFS=$IFS; readonly saved_IFS

die () { printf '%s\n' "$@"; exit 1; } >&2
x () { printf '+ %s\n' "$*" >&2; "$@"; }
x_exec () { printf '+ %s\n' "$*" >&2; exec "$@"; }


if test $# = 0
then echo "
Develop on Device
-----------------

Commands:

   links  -- /usr/share/test -> \$PWD    (uses devel-su)
              and pwpingen-* -> qml/
   ulink  -- remove /usr/share/test     (uses devel-su)

After 'links' done, one can execute

  sailfish-qml test

to run current code under development
"
 if test "${SSH_CONNECTION-}"
 then
	set -- $SSH_CONNECTION
	test $# = 4 || exit 0
	test "$4" != 22 && p=" -p $4" || p=
	d=${PWD#$HOME/}
	echo To access current directory, execute e.g. the following on remote:
	echo
	echo ' ' sshfs$p $USER@$3:$d mnt/...
	echo
 fi
 exit
fi

devdev_cmd_links ()
{
	lpwd=`exec readlink /usr/share/test` || :
	test "$lpwd" = "$PWD" || {
		echo Creating /usr/share/test using devel-su ...
		devel-su sh -xc "rm /usr/share/test
			test -e /usr/share/test && exit 1
			ln -s '$PWD' /usr/share/test"
	}
	test -d qml || {
		x rm -rf qml
		x mkdir qml
	}
	x ln -fs ../pwpingen.py qml/pwpingen.py
	x ln -fs ../pwpingen.qml qml/test.qml
	: > qml/this-dir-not-in-repo
	echo to test, use
	echo '  ' sailfish-qml test
}

devdev_cmd_ulink ()
{
	echo
	if test -e qml
	then
		ls -lF qml/ | sed -e '/^total/d' -e 's/.* ..:.. /qml\//'
		printf '\n: left qml/ around; rm -rf qml/ ;: not done\n\n'
	fi
	test -L /usr/share/test && x devel-su rm -v /usr/share/test || :
}

devdev_cmd_r () # undocumented command -- for those who look the source
{
	x_exec sailfish-qml test
}

# -- rest are for icon development -- usually on desktop/laptop computer -- #

devdev_cmd_v () # ditto (viev)
{
	color=black
	#color=white
	wh=${3:-688}
	#wh=1032
	wxh=$wh''x''$wh
	x_exec feh --title='%w %f' -B $color --force-aliasing -s -Z -g $wxh $2
}

devdev_cmd_p () # ditto
{
	set -- `exec stat -c %Y mkicon.pl icon344.bmp` 0
	test "$1" -lt "$2" || ./mkicon.pl icon344.bmp
	devdev_cmd_v v icon344.bmp
	# not reached #
	fp=${2-icon}; fp=${fp%.*}
	set -- `exec stat -c %Y $fp.pov $fp.png` 0
	wh=172 # 86
	test "$1" -lt "$2" || {
		#test -f icon.png && cp icon.png icon0.png
		x povray -D0 +Q11 +A +UA -H$wh -W$wh $fp.pov
	}
	devdev_cmd_v v $fp.png
}

devdev_cmd_pp () # ditto (postprocess)
{
	fp=${2-icon344}; fp=${fp%.*}
	test -f $fp.png && s=png || s=bmp
	op=${fp%344}86
	set -- `exec stat -c %Y $fp.$s $op.png` 0
	test "$1" -lt "$2" || {
		x convert $fp.$s -scale 86x86 $op-wip.png
		x optipng --strip all -o9 $op-wip.png
		x mv $op-wip.png $op.png
	}
	opts='-B black'
	x_exec feh ${opts-} $op.png
}

set_ssh_ctl_socket ()
{
	test "${XDG_RUNTIME_DIR-}" ||
	die "'\$XDG_RUNTIME_DIR' not defined (edit code to work without(?))"
	ssh_ctl_path=$XDG_RUNTIME_DIR/nemo-devdev.sock
	ssh_ctl_args="-oControlMaster=no -oControlPath=$ssh_ctl_path"
	readonly ssh_ctl_path ssh_ctl_args
}

devdev_cmd_ssh () # note: after connected with -M, anything works as host
{
	set_ssh_ctl_socket
	test -S "$ssh_ctl_path" && M= || M=-M
	host=$2; shift 2
	TERM=xterm \
	x_exec ssh $ssh_ctl_args $M nemo@$host "$@"
}

devdev_cmd_scp () # sample: devdev.sh scp {file} r: (any host, e.g. r: works)
{
	set_ssh_ctl_socket
	shift
	x_exec scp $ssh_ctl_args "$@"
}

devdev_cmd_rpmbuild () # the podman way
{
	test -f pwpingen.spec
	test -d noarch || mkdir noarch
	script -ec 'set -x
	podman run --pull=never --rm -it --privileged -v $PWD:$PWD -w $PWD \
		sailfishos-platform-sdk-aarch64:latest sudo \
		rpmbuild --build-in-place -D "%_rpmdir $PWD" -bb pwpingen.spec
	' noarch/typescript-rpmbuild
	set +f
	ls -l noarch/*
}


devdev_cmd_$1 "$@"


# Local variables:
# mode: shell-script
# sh-basic-offset: 8
# tab-width: 8
# End:
# vi: set sw=8 ts=8
