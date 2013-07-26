#!/bin/bash
#
# Copyright (C) 2013 Stefan Rotman - Puzzle ITC GmbH <rotman@puzzle.ch>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Combining multiple Git Repositories with full branching and tagging history

########################
# VARIABLE DEFINITIONS #
########################

####
# The name of the target
TARGET_REPO=target-repo

####
# The working directory
WORKSPACE="${HOME}/gitmerge/${TARGET_REPO}_$(date +%Y%m%d_%H%M)"

####
# Definition of project codes and projects
declare -A PROJECTS
PROJECTS=( [R1]=project1
         [R2]=project2
         [R3]=project3 )

####
# Definition of project codes and repositories
declare -A REPOSITORIES
REPOSITORIES=( [R1]=/path/to/repo1.git
         [R2]=http://example.com/git/repo2.git
         [R3]=https://example.com/git/repo3.git )

####
# The project codes of the projects to combine.
MERGE_PROJECTS="R1 R2 R3"

########################
# FUNCTION DEFINITIONS #
########################

function log
{
    echo "  # "
    echo "  # ${@} #"
    echo "  # "
}

function init_target
{
    log "initialize ${TARGET_REPO}"

    mkdir -p "${WORKSPACE}/${TARGET_REPO}"
    (
        cd "${WORKSPACE}/${TARGET_REPO}" &&
	git init
    )
}

function rewrite_project
{
    _CODE="${1}"
    _PROJECT="${2}"

    (
        cd "${WORKSPACE}/${_PROJECT}" &&
        log "[${_PROJECT}] rewrite into self-subdir" &&
        git filter-branch --tag-name-filter cat --index-filter 'SHA=$(git write-tree); rm $GIT_INDEX_FILE && git read-tree --prefix='${_PROJECT}'/ $SHA' -- --all &&
        for __BRANCH in $(git branch | tr \* \  )
        do
            __NAMESPACE="$(echo ${__BRANCH} | cut -sd \/ -f 1)"
            __TARGET_BRANCH="${_CODE}-$(echo ${__BRANCH} | cut -d \/ -f 2)"
            if [ -n "${__NAMESPACE}" ]
            then
                __TARGET_BRANCH="${__NAMESPACE}/${__TARGET_BRANCH}"
            fi
            git branch -m "${__BRANCH}" "${__TARGET_BRANCH}" &&
            echo "Branch ${__BRANCH} => ${__TARGET_BRANCH}"
        done
    )
}

function port_project
{
    _CODE="${1}"
    _PROJECT="${2}"

    (
        cd "${WORKSPACE}/${TARGET_REPO}" &&
        log "[${_PROJECT}] port to ${_CODE} scope of ${TARGET_REPO} " &&
        (
            cd "${WORKSPACE}/${_PROJECT}" &&
            git fast-export --all
        ) \
	| sed -r 's/refs\/tags\/(.+)/refs\/tags\/'$_CODE'-\1/g' \
	| git fast-import
    )
}

function process_project
{
    _CODE="${1}"
    _PROJECT="${2}"
    _PROJECT_REPO="${3}"

    if [ ! -d "${WORKSPACE}/${_PROJECT}" ]
    then
        log "[${_PROJECT}] Clone bare from repository ${_PROJECT_REPO}"

        git clone --bare "${_PROJECT_REPO}" "${WORKSPACE}/${_PROJECT}"
    fi

    rewrite_project "${_CODE}" "${_PROJECT}"
    cleanup "${_PROJECT}"
    port_project "${_CODE}" "${_PROJECT}"
}

function process_projects
{
    for __CODE in ${MERGE_PROJECTS}
    do
        process_project "${__CODE}" "${PROJECTS[$__CODE]}" "${REPOSITORIES[$__CODE]}"
    done
}

function cleanup
{
    _TARGET="${1}"
    (
        cd "${WORKSPACE}/${_TARGET}"

        log "[${_TARGET}] Remove backup references"
        git for-each-ref --format='%(refname)' refs/original | \
            while read ref
            do
                git update-ref -d "$ref"
            done

        log "[${_TARGET}] Expire reflog"
        git reflog expire --expire=0 --all

        log "[${_TARGET}] Repack and drop old unreachable objects"
        git repack -ad
        git prune # For objects that repack -ad might have left around
    )
}

########################
# EXECUTION PLAN       #
########################

mkdir -p "${WORKSPACE}" &&
(
    init_target &&
    process_projects &&
    cleanup "${TARGET_REPO}" &&
    echo "Repository merge into new '${WORKSPACE}/${TARGET_REPO}' completed." 
) 2>&1 | tee "${WORKSPACE}/${TARGET_REPO}_$(date +%Y%m%d_%H%M).log"
