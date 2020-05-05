### ALIASES ###

source ~/.iterm2_shell_integration.bash

# User settings
# ANU_ID, NCI_USER, NCI_PROJECT, IODINE_USER
if [ -f ~/.usr_profile ]; then
    . ~/.usr_profile
fi

# Overwrite system programs
alias ls='ls -G'
alias scp='scp -rv'
alias cp='cp -r'
alias du='du -hsc'
#alias mv='mv -i'

# destinations
export DEV=${HOME}/pydev
export WORKSPACE=${HOME}/workspace
export CPC="/Volumes/CHEMPC409"  # ANU hard drive
export MYHD="/Volumes/LilyPass"  # my hard drive, exfat

# shortcuts
alias wk='cd $WORKSPACE'
alias doc='cd $HOME/Documents'
alias dev='cd $HOME/pydev'
alias cpc='cd $CPC'
alias mp='cd $MYHD'

# envs
alias mda='conda activate mda && cd $DEV/mdanalysis && git status'
alias rdk='conda activate rdkit-dev && cd $DEV/rdkit && git status'
alias rdkw='conda activate rdkit-dev && cd $WORKSPACE/rdkit'

# functions
alias p='ping 8.8.8.8'
alias subl='sublime'
alias rebash='echo "    sourcing ~/.bashrc" && source ~/.bashrc'
alias aliases='vim ~/.bash_aliases'
alias mdtest='pytest --disable-pytest-warnings --maxfail=1'
alias untarbz='tar -zxvf'
alias untargz='tar -xv'

function omara {
    if [ ! -d "$OMARA" ]; then
        /usr/bin/osascript -e "try" -e "mount volume \"smb://${ANU_ID}@${ANU_SHARED}\"" -e "end try"
    fi
    cd $OMARA
}

function nomara {
    sudo umount $OMARA
}

function serve {
    python -m sphinx_autobuild source build
}

function scratch {
        ssh -t gadi "cd /scratch/${NCI_PROJECT}/${NCI_USER} && exec ${SHELL} -l"
}

function weather {
    dest=${1:-Melbourne}
    curl v2.wttr.in/${dest}
}


function tunnel {
    port=$1
    dest=${2:-gavle}
    ssh -N -f -L 127.0.0.1:${port}:127.0.0.1:${port} ${dest}
}


function killport {
    port=$1
    lsof -ti:${port} | xargs kill -9
}

function qgadi {
	jobs=$(ssh gadi qstat -u $NCI_USER |  grep $NCI_USER)
	echo "=================================================================================="
	echo "$jobs"
	echo "=================================================================================="
	njobs=$( echo "$jobs" | wc | awk "{ print \$1 }")
	qjobs=$( echo "$jobs" | awk "{print\$10}" | grep Q | wc | awk "{ print \$1 }")
	echo "Total   Q = $njobs"
	echo "Waiting Q = $qjobs"
}

function qiod {
	jobs=$(ssh iodine qstat -u $IODINE_USER |  grep $IODINE_USER)
	echo "=================================================================================="
	echo "$jobs"
	echo "=================================================================================="
	njobs=$(echo "$jobs" | wc | awk "{ print \$1 }")
	qjobs=$(echo "$jobs" | awk "{print\$10}" | grep Q | wc | awk "{ print \$1 }")
	echo "Total   Q = $njobs"
	echo "Waiting Q = $qjobs"
}

function scpfrom {
    src=$1
    items=${@:2:$(($# - 1))}
    dest=${@:$#}

    for x in $items; do
        scp "${src}/${x}" $dest
    done
}

function togadi {
    items=${@:2:$(($# - 1))}
    dest=${@:$#}

    scp $items "${GADI_SCRATCH}/${dest}"
}

function fromgadi {
    scpfrom $GADI_SCRATCH "$@"
}

function jupyterkernel {
        kernelname=$1
        conda activate $kernelname && python -m ipykernel install --user --name $kernelname --display-name "Python (${kernelname})"
}

function getpr {
    if [[ $# -eq 0 ]]; then
        printf "usage: getpr pr [new-branch-name] [remote-source]\nFetch and check out a pull request by ID\n"
        return
    fi

    n=$'\n'  # sigh
    pr=$1
    branchname=${2:-tmppr}
    src=${3:-upstream}
    cmd="git fetch $src pull/${pr}/head:${branchname}"
    read -p "    $cmd$n    Press y to continue.$n" toexe
    case $toexe in
        [Yy]* ) $cmd;;
    esac
    read -p "    Check out ${branchname}?$n    Press y for yes.$n" tocheck
    case $tocheck in
        [Yy]* ) git checkout $branchname;;
    esac
}

function gclone {
    # argparse?
    if [[ $# -eq 0 ]]; then
        printf "usage: gclone [user] repo [dest]\nClone repos from Github.\n"  # help
        return
    elif [[ $# -eq 1 ]]; then
        user=$GITHUB_USER
        repo=$1
    elif [[ $# -eq 2 ]]; then
        user=$1
        repo=$2
    fi
    
    n=$'\n'  # there must be a better way...
    cmd="git clone git@github.com:${user}/${repo}.git ${@:3}"
    read -p "      $cmd$n      Press y to continue.$n" toexe
    case $toexe in
        [Yy]*) $cmd;;
    esac
}
