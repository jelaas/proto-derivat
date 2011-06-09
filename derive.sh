#!/bin/bash
#
# File: derive.sh
# Implements: proto-derivat control
#
# Copyright: Jens Låås, UU 2010, 2011
# Copyright license: According to GPL, see file COPYING in this directory.
#

VERSION=VERSION
DATE=DATE

function usage {
    echo "derive $VERSION ($DATE)"
    echo
    echo "Invocations:"
    echo " derive"
    echo " derive list|ls"
    echo " derive fetch"
    echo " derive diff"
    echo " derive apply"
    echo " derive <derivat> list|ls"
    echo " derive <derivat> fetch"
    echo " derive <derivat> diff|check"
    echo " derive <derivat> apply"
    echo " derive <derivat> init <proto-repository> [apply]"
}

function gitpath {
    local P
    P="$(pwd)"

    while true; do
	[ -d "$P/.git" ] && echo $P && return 0
	P="$(dirname $P)"
	[ "$P" = "/" ] && return 1
    done
}

function fetch_files {
    local F REPO
    REPO=$1
    
    while read F; do
	if [ ! -f "$F" ]; then
	    mkdir -p "$(dirname $F)"
	    cp "$REPO/$F" "$F"
	fi
    done
}

function diff_files {
    local F REPO FT
    REPO=$1
    
    while read F; do
	if [ -f "$F" ]; then
	    FT="$(file -b -i "$F")"
	    if [ "${FT:0:11}" = application -a "${FT:0:19}" != application/x-shell ]; then
		if [ "$(head -c 1024000 "$F"|md5sum)" != "$(head -c 1024000 "$REPO/$F"|md5sum)" ]; then
		    echo "Binary file $F differs."
		fi
	    else
		diff -u "$F" "$REPO/$F"
	    fi
	else
	    echo "$F not yet fetched from repo."
	fi
    done
}

function apply_files {
    local F REPO
    REPO=$1
    
    while read F; do
	mkdir -p "$(dirname $F)"
	cp "$REPO/$F" "$F"
    done
}

function derive_list {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    
    cat $REPO/$DERIVAT
}

function derive_fetch {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    
    cat $REPO/$DERIVAT|fetch_files "$REPO"
}

function derive_apply {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    
    cat $REPO/$DERIVAT|apply_files "$REPO"
}

function derive_diff {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    
    cat $REPO/$DERIVAT|diff_files "$REPO"
}

function derive_apply {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    
    cat $REPO/$DERIVAT|apply_files "$REPO"
}

if [ "${1:0:1}" = '-' ]; then
    usage
    exit 0
fi

#
# derive
#
if [ -z "$1" ]; then
    GITPATH="$(gitpath)"
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH

    if [ ! -d .derivats ]; then
	echo "Cannot read '.derivats'." >&2
	exit 2
    fi

    for DERIVAT in .derivats/*; do
	basename $DERIVAT
    done
    exit 0
fi

#
# derive list
#
if [ "$1" = list -o "$1" = ls ]; then
    if [ -z "$2" ]; then
	GITPATH="$(gitpath)"
	if [ -z "$GITPATH" ]; then
	    echo "derive can only be done in a git repository!" >&2
	    exit 1
	fi
	
	cd $GITPATH
	
	if [ ! -d .derivats ]; then
	    echo "Cannot read '.derivats'." >&2
	    exit 2
	fi
	
	for DERIVAT in .derivats/*; do
	    derive_list $(basename $DERIVAT)
	done
	
	exit
    fi
fi

#
# derive fetch
#
if [ "$1" = fetch -a -z "$2" ]; then
    GITPATH="$(gitpath)"
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH

    if [ ! -d .derivats ]; then
	echo "Cannot read '.derivats'." >&2
	exit 2
    fi

    for DERIVAT in .derivats/*; do
	derive_fetch $(basename $DERIVAT)
    done

    exit
fi

#
# derive diff
#
if [ "$1" = diff -o "$1" = check ]; then
    if [ -z "$2" ]; then
	GITPATH="$(gitpath)"
	if [ -z "$GITPATH" ]; then
	    echo "derive can only be done in a git repository!" >&2
	    exit 1
	fi
	
	cd $GITPATH
	
	if [ ! -d .derivats ]; then
	    echo "Cannot read '.derivats'." >&2
	    exit 2
	fi
	
	for DERIVAT in .derivats/*; do
	    derive_diff $(basename $DERIVAT)
	done
	
	exit
    fi
fi

#
# derive apply
#
if [ "$1" = apply -a -z "$2" ]; then
    GITPATH="$(gitpath)"
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH

    if [ ! -d .derivats ]; then
	echo "Cannot read '.derivats'." >&2
	exit 2
    fi

    for DERIVAT in .derivats/*; do
	derive_apply $(basename $DERIVAT)
    done

    exit
fi

#
# derive <derivat> list
#
if [ "$1" -a "$2" = list ]; then
    derive_list "$1"
    exit
fi
if [ "$1" -a "$2" = ls ]; then
    derive_list "$1"
    exit
fi

#
# derive <derivat> fetch
#
if [ "$1" -a "$2" = fetch ]; then
    derive_fetch "$1"
    exit
fi

#
# derive <derivat> diff
#
if [ "$1" -a "$2" = diff ]; then
    derive_diff "$1"
    exit
fi

#
# derive <derivat> apply
#
if [ "$1" -a "$2" = apply ]; then
    derive_apply "$1"
    exit
fi

#
# derive <derivat> init <proto-repository> [apply]
#
if [ "$1" -a "$2" = init -a "$3" ]; then
    REPO="$3"
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "derive init can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    mkdir -p .derivats
    
    if [ ! -f "$REPO/.proto-repository" ]; then
	echo "$REPO is not a proto-repository!"
	echo ".proto-repository missing."
	exit 1
    fi
    [ -f "$REPO/$DERIVAT" ] || exit 1
    [ -e ".derivats/$DERIVAT" ] && exit 1
    
    if [ "$4" = apply ]; then
	echo $REPO > .derivats/$DERIVAT
	echo $DERIVAT >> .derivats/$DERIVAT
	
	derive_fetch "$DERIVAT"
    else
	cat $REPO/$DERIVAT
    fi
    exit 0
fi

usage
exit 1
