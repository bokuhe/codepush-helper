#/bin/bash

#===============
# CONFIG
#===============
source ./CONFIG

#==========
# FUNCTIONS
#==========
function get() {
    arr=${1}
    idx=${2}
 
    row=$arr[*]
    row=(${!row})
 
    echo "${row[$idx]}"
}
 
function get_names() {
    for p in ${PROJECTS[*]}; do
        row=$p[*]
        row=(${!row})
        echo "${row[0]}"
    done
}
 
function get_project() {
    name=${1}
    for p in ${PROJECTS[*]}; do
        row=$p[*]
        row=(${!row})
        if [ ${name} == ${row[0]} ]; then
            echo "${row[*]}"
            break
        fi
    done
}
 
# get_name
# ret=$(get_name ${PROJECTS[1]})
# echo "get_name $ret"
 
#get_work_dir
# ret=$(get_work_dir ${PROJECTS[1]})
# echo "get_work_dir $ret"
 
# get_names
# ret=($(get_names))
# echo "0: ${ret[0]}"
# echo "1: ${ret[1]}"
 
#=================
# PARSE PARAMETERS
#=================
function join_by { IFS="$1"; shift; echo "$*"; }
 
function usage() {
    b="\033[1m" # bold
    u="\033[4m" # underline
    e="\033[0m" # normal

    sh="codepush-helper.sh"
    arg1="command"
    arg2="project"
    arg3="target"
    names=$(join_by "|" $(get_names))

    echo "usage:"
    echo "\t${u}$sh${e} ${b}$arg1${e} ${b}$arg2${e} ${b}$arg3${e} [${b}ios${e}|${b}android${e}]"
    echo ""
    echo "commands:"
    echo "\t${b}$arg1${e}\trelease|disable|rollback"
    echo "\t${b}$arg2${e}\t$names"
    echo "\t${b}$arg3${e}\tproduction|staging"

    exit
}
 
# PARAM COUNT CHECK
if [ ${#} -ne 3 ] && [ ${#} -ne 4 ]; then usage; exit; fi
 
# VALID NAME CHECK
current=($(get_project "${2}"))
if [ -z ${current} ]; then usage; exit; fi
 
workdir=${current[1]}
app=${current[2]}
 
# MOVE WORKING DIR
cd $workdir
 
# PARSE
deploy=""
case ${3} in
    "production") deploy="Production" ;;
    "staging") deploy="Staging" ;;
    *) usage ;;
esac
 
target=""
case ${4} in
    "ios") target="ios" ;;
    "android") target="android" ;;
    *) ;; # ignore 4th param
esac
 
cmd="${1}"
cmd_android=""
cmd_ios=""
case $cmd in
    "release")
        commit_log=`git log -1`
        commit_hash=`git rev-parse --short HEAD`
 
        desc=$commit_hash
 
        cmd_android="appcenter codepush release-react -a $app-android -d $deploy --description '$desc'"
        cmd_ios="appcenter codepush release-react -a $app-ios -d $deploy --description '$desc'"
    ;;
    "disable")
        cmd_android="appcenter codepush patch -a $app-android $deploy --disabled true"
        cmd_ios="appcenter codepush patch -a $app-ios $deploy --disabled true"
    ;;
    "rollback") # do not use. not working.
        cmd_android="appcenter codepush rollback -a $app-android $deploy"
        cmd_ios="appcenter codepush rollback -a $app-ios $deploy"
    ;;
    "clear") # do not use. delete all release.
        cmd_android="appcenter codepush deployment clear -a $app-android $deploy"
        cmd_ios="appcenter codepush deployment clear -a $app-ios $deploy"
    ;;
    *) usage ;;
esac
 
#================
# CODEPUSH DEPLOY
#================
function deploy_android() {
    echo "DEPLOY ANDROID COMMAND> $cmd_android"
    $cmd_android
}
 
function deploy_ios() {
    echo "DEPLOY IOS COMMAND> $cmd_ios"
    $cmd_ios
}
 
function deploy() {
    case $target in
        "ios") deploy_ios ;;
        "android") deploy_android ;;
        *) deploy_ios ; deploy_android ;;
    esac
}
 
#===================
# CODEPUSH LABEL TAG - OPTION
#===================
function tag_ios() {
    ios_latest_label=`appcenter codepush deployment list --app $app-ios --output json | jq '.[] | select(.name == "'$deploy'") | .latestRelease.label' | sed 's/[^0-9]//g'`
    git push -d $GIT_REMOTE `git tag | grep -E 'latest/ios'` # clear old tags (remote) - option
    git tag -d `git tag | grep -E 'latest/ios'` # clear old tags (local) - option
    git tag "latest/ios-$ios_latest_label"
    git tag | grep -E 'latest/ios' | xargs git push $GIT_REMOTE # push tags (remote) - option
}
 
function tag_android() {
    android_latest_label=`appcenter codepush deployment list --app $app-android --output json | jq '.[] | select(.name == "'$deploy'") | .latestRelease.label' | sed 's/[^0-9]//g'`
    git push -d $GIT_REMOTE `git tag | grep -E 'latest/android'` # clear old tags (remote) - option
    git tag -d `git tag | grep -E 'latest/android'` # clear old tags (local) - option
    git tag "latest/android-$android_latest_label"
    git tag | grep -E 'latest/android' | xargs git push $GIT_REMOTE # push tags (remote) - option
}
 
function tag() {
    if [ "$deploy" == "Production" ] && [ "$cmd" == "release" ]; then
        git fetch $GIT_REMOTE --tags
        case $target in
            "ios") tag_ios ;;
            "android") tag_android ;;
            *) tag_ios ; tag_android ;;
        esac
    fi
}
 
#
# RUN
#
if [ $TEST == true ]; then
    echo $deploy
    echo $target
    echo $cmd_android
    echo $cmd_ios
else
    deploy
    tag
fi
