#!/bin/bash
#
# File: proto.sh
# Implements: proto-derivat control
#
# Copyright: Jens L��s, UU 2010, 2011
# Copyright license: According to GPL, see file COPYING in this directory.
#

VERSION=VERSION
DATE=DATE

function usage {
    echo "proto $VERSION ($DATE)"
    echo
    echo "Invocations:"
    echo " proto"
    echo " proto [-v] list|ls"
    echo " proto fetch"
    echo " proto diff|check"
    echo " proto apply"
    echo " proto <prototype> list|ls"
    echo " proto find|from <filename>"
    echo " proto <prototype> fetch"
    echo " proto <prototype> diff|check"
    echo " proto <prototype> apply"
    echo " proto <prototype> delete [apply]"
    echo " proto <prototype> init <proto-repository> [apply]"
    echo " proto init <proto-repository>/<prototype> [apply]"
}

VERBOSE=n
if [ "$1" = "-v" ]; then
    VERBOSE=y
    shift
fi

function gitpath {
    local P
    P="$(pwd)"

    while true; do
	[ -d "$P/.git" ] && echo $P && return 0
	P=$(dirname "$P")
	[ "$P" = "/" ] && return 1
    done
}

function sed_file {
    local F L
    F="$1"
    cat "$F.sed"|while read L; do
	sed -i "$L" "$F"
    done
}

function fetch_files {
    local F REPO
    REPO=$1
    
    while read F; do
	if [ ! -f "$F" ]; then
	    mkdir -p $(dirname "$F")
	    cp "$REPO/$F" "$F"
	    [ -f "$F.sed" ] && sed_file "$F"
	fi
    done
}

function delete_files {
    local F DN
    
    while read F; do
	if [ -e "$F" ]; then
	    git rm -f "$F" || rm -f "$F"
	    DN=$(dirname "$F")
	    rmdir "$DN" &> /dev/null
	fi
    done
}

function diff_files {
    local F REPO FT TMPFILE
    REPO=$1
    
    while read F; do
	if [ -f "$F" ]; then
	    FT="$(file -b -i "$F")"
	    if [ "${FT:0:11}" = application -a "${FT:0:19}" != application/x-shell ]; then
		if [ "$(head -c 1024000 "$F"|md5sum)" != "$(head -c 1024000 "$REPO/$F"|md5sum)" ]; then
		    echo "Binary file $F differs."
		fi
	    else
		if [ -f "$F.sed" ]; then
		    TMPFILE=/tmp/$$_$(basename "$F")
		    cp "$REPO/$F" "$TMPFILE"
		    cp "$F.sed" "$TMPFILE.sed"
		    sed_file "$TMPFILE"
		    diff -u "$F" "$TMPFILE"
		    rm -f "$TMPFILE" "$TMPFILE.sed"
		else
		    diff -u "$F" "$REPO/$F"
		fi
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
	mkdir -p $(dirname "$F")
	cp "$REPO/$F" "$F"
	[ -f "$F.sed" ] && sed_file "$F"
    done
}

function derive_list {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    PROTO=$(cat ".derivats/$DERIVAT"|tail -n 1)
    cat $REPO/$PROTO
}

function derive_fetch {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH

    if [ ! -f ".derivats/$DERIVAT" ]; then
	echo "ERROR: .derivats/$DERIVAT missing!" >&2
	exit 1
    fi
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    PROTO=$(cat ".derivats/$DERIVAT"|tail -n 1)
    cat $REPO/$PROTO|fetch_files "$REPO"
}

function derive_delete {
    DERIVAT="$1"
    APPLY="$2"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH

    if [ ! -f ".derivats/$DERIVAT" ]; then
	echo "ERROR: .derivats/$DERIVAT missing!" >&2
	exit 1
    fi
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    PROTO=$(cat ".derivats/$DERIVAT"|tail -n 1)
    if [ "$APPLY" = apply ]; then
	cat $REPO/$PROTO|delete_files
	rm -f ".derivats/$DERIVAT"
    else
	cat $REPO/$PROTO
    fi
}

function derive_apply {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    PROTO=$(cat ".derivats/$DERIVAT"|tail -n 1)
    cat $REPO/$PROTO|apply_files "$REPO"
}

function derive_diff {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    PROTO=$(cat ".derivats/$DERIVAT"|tail -n 1)
    cat $REPO/$PROTO|diff_files "$REPO"
}

function derive_apply {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH
    
    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
    PROTO=$(cat ".derivats/$DERIVAT"|tail -n 1)
    cat $REPO/$PROTO|apply_files "$REPO"
}

function print_pfx {
    local L
    
    while read L; do
	echo $1 $L
    done
}


if [ "${1:0:1}" = '-' ]; then
    usage
    exit 0
fi

#
# proto
#
if [ -z "$1" ]; then
    GITPATH="$(gitpath)"
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH

    if [ ! -d .derivats ]; then
	echo "Cannot read '.derivats'." >&2
	exit 2
    fi

    for DERIVAT in .derivats/*; do
	DERIVAT=$(basename $DERIVAT)
	REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
	echo $(basename $REPO)/$(basename $DERIVAT)
    done
    exit 0
fi

#
# proto list
#
if [ "$1" = list -o "$1" = ls ]; then
    if [ -z "$2" ]; then
	GITPATH="$(gitpath)"
	if [ -z "$GITPATH" ]; then
	    echo "proto can only be done in a git repository!" >&2
	    exit 1
	fi
	
	cd $GITPATH
	
	if [ ! -d .derivats ]; then
	    echo "Cannot read '.derivats'." >&2
	    exit 2
	fi
	
	for DERIVAT in .derivats/*; do
	    DERIVAT=$(basename $DERIVAT)
	    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
	    if [ "$VERBOSE" = y ]; then
		derive_list $(basename $DERIVAT)|print_pfx "$(basename $REPO)/$(basename $DERIVAT)"
	    else
		derive_list $(basename $DERIVAT)
	    fi
	done
	
	exit
    fi
fi

#
# proto find <filename>
#
if [ "$1" = find -o "$1" = from ]; then
    if [ "$2" ]; then
	FN="$2"
	GITPATH="$(gitpath)"
	if [ -z "$GITPATH" ]; then
	    echo "proto can only be done in a git repository!" >&2
	    exit 1
	fi
	
	cd $GITPATH
	
	if [ ! -d .derivats ]; then
	    echo "Cannot read '.derivats'." >&2
	    exit 2
	fi
	
	for DERIVAT in .derivats/*; do
	    DERIVAT=$(basename $DERIVAT)
	    if derive_list $DERIVAT|grep -q "$FN"; then
		REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
		echo $(basename $REPO)/$DERIVAT $(derive_list $DERIVAT|grep "$FN")
	    fi
	done
	
	exit
    fi
fi

#
# proto fetch
#
if [ "$1" = fetch -a -z "$2" ]; then
    GITPATH="$(gitpath)"
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH

    if [ ! -d .derivats ]; then
	echo "Cannot read '.derivats'." >&2
	exit 2
    fi

    for DERIVAT in .derivats/*; do
	DERIVAT=$(basename $DERIVAT)
	derive_fetch $DERIVAT
    done

    exit
fi

#
# proto diff
#
if [ "$1" = diff -o "$1" = check ]; then
    if [ -z "$2" ]; then
	GITPATH="$(gitpath)"
	if [ -z "$GITPATH" ]; then
	    echo "proto can only be done in a git repository!" >&2
	    exit 1
	fi
	
	cd $GITPATH
	
	if [ ! -d .derivats ]; then
	    echo "Cannot read '.derivats'." >&2
	    exit 2
	fi
	
	for DERIVAT in .derivats/*; do
	    DERIVAT=$(basename $DERIVAT)
	    derive_diff $DERIVAT
	done
	
	exit
    fi
fi

#
# proto apply
#
if [ "$1" = apply -a -z "$2" ]; then
    GITPATH="$(gitpath)"
    if [ -z "$GITPATH" ]; then
	echo "proto can only be done in a git repository!" >&2
	exit 1
    fi
    
    cd $GITPATH

    if [ ! -d .derivats ]; then
	echo "Cannot read '.derivats'." >&2
	exit 2
    fi

    for DERIVAT in .derivats/*; do
	DERIVAT=$(basename $DERIVAT)
	derive_apply $DERIVAT
    done

    exit
fi

#
# proto <derivat> list
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
# proto <derivat> fetch
#
if [ "$1" -a "$2" = fetch ]; then
    DERIVAT="$1"
    derive_fetch "$DERIVAT"
    exit
fi

#
# proto <derivat> delete
#
if [ "$1" -a "$2" = delete ]; then
    DERIVAT="$1"
    derive_delete "$DERIVAT" "$3"
    exit
fi

#
# proto <derivat> diff|check
#
if [ "$1" -a "$2" = diff ]; then
    derive_diff "$1"
    exit
fi
if [ "$1" -a "$2" = check ]; then
    derive_diff "$1"
    exit
fi

#
# proto <derivat> apply
#
if [ "$1" -a "$2" = apply ]; then
    derive_apply "$1"
    exit
fi

INITCMD=n
#
# proto init <proto-repository>/<derivat> [apply]
#
if [ "$1" = init -a "$2" ]; then
    REPO="${2%/*}"
    DERIVAT="${2##*\/}"
    GITPATH="$(gitpath)"
    APPLY="$3"
    INITCMD=y
fi

#
# proto <derivat> init <proto-repository> [apply]
#
if [ "$1" -a "$2" = init -a "$3" ]; then
    REPO="$3"
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    APPLY="$4"
    INITCMD=y
fi

if [ "$INITCMD" = y ]; then
    if [ -z "$GITPATH" ]; then
	echo "proto init can only be done in a git repository!" >&2
	exit 1
    fi
    
    if [ "${DERIVAT:~1}" != ".p" ]; then
	echo "A derivat name must have the suffix '.p'" >&2
	exit 1
    fi

    cd $GITPATH
    
    mkdir -p .derivats
    
    if [ ! -f "$REPO/.proto-repository" ]; then
	echo "$REPO is not a proto-repository!"
	echo ".proto-repository missing."
	exit 1
    fi

    if [ ! -f "$REPO/.proto-repository-id" ]; then
	echo "File: $REPO/.proto-repository-id is missing"
	echo "Create the file with a unique id-string as content."
	echo " Example content: dev4"
	exit 1
    fi

    read REPOID < "$REPO/.proto-repository-id"

    [ -f "$REPO/$DERIVAT" ] || exit 1
    [ -e ".derivats/$DERIVAT" ] && exit 1
    [ -e ".derivats/id::$REPOID:$DERIVAT" ] && exit 1
    
    if [ "$APPLY" = apply ]; then
	echo $REPO > .derivats/id::$REPOID:$DERIVAT
	echo $DERIVAT >> .derivats/id::$REPOID:$DERIVAT
	
	derive_fetch "id::$REPOID:$DERIVAT"
    else
	cat $REPO/$DERIVAT
    fi
    exit 0
fi

usage
exit 1