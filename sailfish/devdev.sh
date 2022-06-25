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
# Last modified: Sat 25 Jun 2022 15:59:06 +0300 too

# Note: started with Makefile, but got "make: not found" (minimal deps FTW)

# SPDX-License-Identifier: 0BSD


case ${BASH_VERSION-} in *.*) set -o posix; shopt -s xpg_echo; esac
case ${ZSH_VERSION-} in *.*) emulate ksh; esac

set -euf  # hint: sh -x thisfile [args] to trace execution

saved_IFS=$IFS; readonly saved_IFS

die () { printf '%s\n' '' "$@" ''; exit 1; } >&2
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

 grep de"vd"ev $0 ;: to see '('undocumented')' commands
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

devdev_cmd_test () # sailfish-qml test
{
	x_exec sailfish-qml test
}

# -- rest are for icon development -- usually on desktop/laptop computer -- #

devdev_cmd_v ()    # view any image file (scaled) using feh(1)
{
	color=black
	#color=white
	wh=${3:-688}
	#wh=1032
	wxh=$wh''x''$wh
	x_exec feh --title='%w %f' -B $color --force-aliasing -s -Z -g $wxh $2
}

devdev_cmd_p ()    # make icon344.bmp, then view it using feh(1)
{
	set -- `stat -c %Y mkicon.pl icon344.bmp` 0
	test "$1" -lt "$2" || ./mkicon.pl icon344.bmp
	de'vd'ev_cmd_v v icon344.bmp
	# not reached #
	fp=${2-icon}; fp=${fp%.*}
	set -- `exec stat -c %Y $fp.pov $fp.png` 0
	wh=172 # 86
	test "$1" -lt "$2" || {
		#test -f icon.png && cp icon.png icon0.png
		x povray -D0 +Q11 +A +UA -H$wh -W$wh $fp.pov
	}
	de'vd'ev_cmd_v v $fp.png
}

devdev_cmd_pp ()   # postprocess it to 86x86
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

devdev_cmd_sshp ()     # create persistent ssh connection...
{
	test $# -ge 4 || {
		case $0 in ./*) n=$0 ;; *) n=${0##*/} ;; esac
		rest='[[user]@]{host} [command [args]]'
		die "Usage: ${0##*/} $1 {name} {time}(s|m|h|d|w) $rest" \
		'' ": Hint; $n $1 .15 4h nemo@192.168.2.15 date; date" \
		'' ': Then; ssh .15 date; date'
	}
	echo "Checking/creating persistent connection lasting $2"
	z=`ssh -O check "$2" 2>&1` &&
	{ printf '%s\n%s\n' "$z" "(ssh $2 -O exit to exit)"; exit 0; } ||
	case $z in 'No ControlPath specified'*)
		echo $z
		exit 1
	esac
	z=${z%)*}; z=${z#*\(}
	test -e "$z" && rm "$z"
	so=-oControlPath=$z\ -M\ -oControlPersist=$3
	case $4 in @*) userathost=${4#?}
		;; *@*) userathost=$4
		;; *) userathost=nemo@$4
	esac
	shift 4
	echo ssh $so $userathost "$@" >&2
	TERM=xterm \
	exec ssh $so $userathost "$@"
	exit not reached
}

devdev_cmd_rpmbuild () # using poodman and sailfishos-platform-sdk-aarch64
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


de'vd'ev_cmd_$1 "$@"


# Local variables:
# mode: shell-script
# sh-basic-offset: 8
# tab-width: 8
# End:
# vi: set sw=8 ts=8
