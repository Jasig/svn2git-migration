#/bin/bash

set -e

PROGNAME=${0##*/}
PRODDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


SVN_CMD=/usr/bin/svn
GIT_CMD=/usr/bin/git
SLD_CMD=$PRODDIR/svn_load_dirs.pl

usage()
{
  cat << EO
        Usage: $PROGNAME [options]

        Options:
EO
  cat <<EO | column -s\& -t

        -h|--help & show this output
        -g|--git & Path to the local git repository
        -w|--working-dir & Path to the working directory to keep SVN checkouts in
        -b|--branch & Branch to sync, can be specified multiple times
        -u|--username & The SVN username to use when making commits
        -d|--debug & Enable debug output
EO
} 

SHORTOPTS="hg:w:b:du:"
LONGOPTS="help,git:working-dir:branch:debug,username"

ARGS=$(getopt -s bash --options $SHORTOPTS --longoptions $LONGOPTS --name $PROGNAME -- "$@" ) 

DEBUG=false
GIT_BRANCH_COUNT=0
declare -a GIT_BRANCHES

eval set -- "$ARGS"
while true; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -g|--gitversion)
            shift
            GIT_REPO=$1
            ;;
        -w|--working-dir)
            shift
            WORKING_DIR=$1
            ;;
        -b|--branch)
            shift
            GIT_BRANCHES[$GIT_BRANCH_COUNT]=$1
            GIT_BRANCH_COUNT=$(( $GIT_BRANCH_COUNT + 1 ))
            ;;
        -u|--username)
            shift
            SVN_USERNAME=$1
            ;;
        -d|--debug)
            DEBUG=true
            ;;
        --)
            shift
            break
            ;;
        *)
            shift
            break
            ;;
   esac
   shift
done

if $DEBUG; then
    echo "PROGNAME=$PROGNAME"
    echo "PRODDIR=$PRODDIR"
    echo "GIT_REPO=$GIT_REPO"
    echo "WORKING_DIR=$WORKING_DIR"
    echo "GIT_BRANCH_COUNT=$GIT_BRANCH_COUNT"
    echo "SVN_USERNAME=$SVN_USERNAME"
    
    for GIT_BRANCH in ${GIT_BRANCHES[@]}; do
        echo "GIT_BRANCH=$GIT_BRANCH"
    done
fi

# Verify required arguments
if [ -z "$GIT_REPO" ]; then
    echo "No git repository set"
    usage
    exit 1
fi
if [ -z "$WORKING_DIR" ]; then
    echo "No working directory set"
    usage
    exit 1
fi
if [ $GIT_BRANCH_COUNT -eq 0 ]; then
    echo "No branches were specified"
    usage
    exit 1
fi    

# Verify git repo exists
if [ ! -d "$GIT_REPO/.git" ]; then
    echo "$GIT_REPO is not a git repository"
    exit 1
fi

# Create working directory if it doesn't exist
if [ ! -d "$WORKING_DIR" ]; then
    echo "$WORKING_DIR does not exist, creating ..."
    mkdir -p $WORKING_DIR
fi

# Prefix svn username if specified
if [ -n "$SVN_USERNAME" ]; then
    SVN_USERNAME="-svn_username $SVN_USERNAME"
fi

echo "`date` $GIT_REPO - Switching to Repository"
pushd $GIT_REPO

echo "`date` $GIT_REPO - Fetch all changes"
$GIT_CMD fetch --all -p

GIT_REPO_BASENAME=`basename $GIT_REPO`

for GIT_BRANCH in ${GIT_BRANCHES[@]}; do
    echo -e "`date`\t$GIT_BRANCH - Switching to branch"
    $GIT_CMD checkout $GIT_BRANCH
    
    
    SVN_PATH=`git svn info | grep URL: | sed 's/^URL: //'`
    if [ ! -n "$SVN_PATH" ]; then
        echo -e "`date`\t$GIT_BRANCH - Has no SVN Information, cannot sync"
        exit 1
    fi
    echo -e "`date`\t$GIT_BRANCH - Maps to $SVN_PATH"
    
            
    echo -e "`date`\t$GIT_BRANCH - Generating change log"
    CHANGE_LOG=`$GIT_CMD log --pretty=format:"%H - %s" origin/${GIT_BRANCH} ^${GIT_BRANCH}`
    if [ ! -n "$CHANGE_LOG" ]; then
        echo -e "`date`\t$GIT_BRANCH - Is up to date"
        continue
    fi
    CHANGE_LOG=`echo -e "Updating SVN $SVN_PATH from Git branch $GIT_BRANCH\n\n$CHANGE_LOG"`
    

    echo -e "`date`\t$GIT_BRANCH - Merging changes from origin"
    $GIT_CMD merge origin/$GIT_BRANCH
    
        
    echo -e "`date`\t$GIT_BRANCH - Exporting copy of git branch"
    GIT_EXPORT_DIR="${GIT_REPO_BASENAME}_git_${GIT_BRANCH}"
    $GIT_CMD archive --format=tar --prefix=${GIT_EXPORT_DIR}/ HEAD | (cd $WORKING_DIR && tar xf -)
    

    SVN_BASE=`dirname $SVN_PATH`
    SVN_BRANCH=`basename $SVN_PATH`
    SVN_WORKING_DIR="$WORKING_DIR/${GIT_REPO_BASENAME}_svn_${SVN_BRANCH}"
    if [ ! -d "$SVN_WORKING_DIR/.svn" ]; then
        echo -e "`date`\t$GIT_BRANCH - SVN Working Copy doesn't exist, checking out $SVN_PATH to $SVN_WORKING_DIR"
        rm -Rf $SVN_WORKING_DIR
        $SVN_CMD co $SVN_PATH $SVN_WORKING_DIR
    fi
    

    echo -e "`date`\t$GIT_BRANCH - Running svn_load_dirs to sync svn with git"
    $SLD_CMD $SVN_BASE $SVN_BRANCH $WORKING_DIR/$GIT_EXPORT_DIR $SVN_USERNAME -wc $SVN_WORKING_DIR -v -no_user_input -message  "$CHANGE_LOG"
    

    echo -e "`date`\t$GIT_BRANCH - Remove git export: $WORKING_DIR/$GIT_EXPORT_DIR"
    rm -Rf $WORKING_DIR/$GIT_EXPORT_DIR
done

echo "`date` $GIT_REPO - Svn Update Complete"
popd
