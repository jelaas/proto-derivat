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
    echo " derive [-v] list|ls"
    echo " derive fetch"
    echo " derive diff|check"
    echo " derive apply"
    echo " derive <derivat> list|ls"
    echo " derive find <filename>"
    echo " derive <derivat> fetch"
    echo " derive <derivat> diff|check"
    echo " derive <derivat> apply"
    echo " derive <derivat> delete [apply]"
    echo " derive <derivat> init <proto-repository> [apply]"
    echo " derive init <proto-repository>/<derivat> [apply]"
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

function delete_files {
    local F
    
    while read F; do
	if [ -e "$F" ]; then
	    git rm -f "$F" || rm -f "$F"
	    rmdir "$(dirname $F)" &> /dev/null
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
    PROTO=$(cat ".derivats/$DERIVAT"|tail -n 1)
    cat $REPO/$PROTO
}

function derive_fetch {
    DERIVAT="$1"
    GITPATH="$(gitpath)"
    
    if [ -z "$GITPATH" ]; then
	echo "derive can only be done in a git repository!" >&2
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
	echo "derive can only be done in a git repository!" >&2
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
	echo "derive can only be done in a git repository!" >&2
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
	echo "derive can only be done in a git repository!" >&2
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
	echo "derive can only be done in a git repository!" >&2
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
	DERIVAT=$(basename $DERIVAT)
	REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
	echo $(basename $REPO)/$(basename $DERIVAT)
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
# derive find <filename>
#
if [ "$1" = find -a "$2" ]; then
    FN="$2"
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
	DERIVAT=$(basename $DERIVAT)
	if derive_list $DERIVAT|grep -q "$FN"; then
	    REPO=$(cat ".derivats/$DERIVAT"|head -n 1)
	    echo $(basename $REPO)/$DERIVAT $(derive_list $DERIVAT|grep "$FN")
	fi
    done
    
    exit
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
	DERIVAT=$(basename $DERIVAT)
	derive_fetch $DERIVAT
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
	    DERIVAT=$(basename $DERIVAT)
	    derive_diff $DERIVAT
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
	DERIVAT=$(basename $DERIVAT)
	derive_apply $DERIVAT
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
    DERIVAT="$1"
    derive_fetch "$DERIVAT"
    exit
fi

#
# derive <derivat> delete
#
if [ "$1" -a "$2" = delete ]; then
    DERIVAT="$1"
    derive_delete "$DERIVAT" "$3"
    exit
fi

#
# derive <derivat> diff|check
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
# derive <derivat> apply
#
if [ "$1" -a "$2" = apply ]; then
    derive_apply "$1"
    exit
fi

INITCMD=n
#
# derive init <proto-repository>/<derivat> [apply]
#
if [ "$1" = init -a "$2" ]; then
    REPO="${2%/*}"
    DERIVAT="${2##*\/}"
    GITPATH="$(gitpath)"
    APPLY="$3"
    INITCMD=y
fi

#
# derive <derivat> init <proto-repository> [apply]
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
	echo "derive init can only be done in a git repository!" >&2
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
