#/bin/bash
 
#===============
# CONFIGURATIONS
#===============
TEST=false
 
GIT_REMOTE="origin"
 
# name, workdir, codepush-app(without '-$platform'),
P1=("station" "/Users/bokuhe/station-mobile" "codepush-project/station")
P1=("mirror" "/Users/bokuhe/mirror-mobile-app" "codepush-project/mirror")
PROJECTS=(P1 P2)
 
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
    names=$(join_by "|" $(get_names))
    echo "codepush-helper.sh [release|disable|rollback] [$names] [production|staging]"
    exit
}
 
# PARAM COUNT CHECK
if [ ${#} -ne 3 ]; then usage; exit; fi
 
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
    *) ;;
esac
 
cmd_android=""
cmd_ios=""
case ${1} in
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
    case $deploy in
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
    git tag "latest/ios-$ios_latest_label"
}
 
function tag_android() {
    android_latest_label=`appcenter codepush deployment list --app $app-android --output json | jq '.[] | select(.name == "'$deploy'") | .latestRelease.label' | sed 's/[^0-9]//g'`
    git tag "latest/android-$android_latest_label"
}
 
function tag() {
    if [ "$deploy" == "Production" ]; then
	git fetch $GIT_REMOTE --tags
        git push -d $GIT_REMOTE `git tag | grep -E 'latest/'` # clear old tags (remote) - option
        git tag -d `git tag | grep -E 'latest/'` # clear old tags (local) - option
        case $target in
            "ios") tag_ios ;;
            "android") tag_android ;;
            *) tag_ios ; tag_android ;;
        esac
        git tag | grep -E 'latest/' | xargs git push $GIT_REMOTE # push tags (remote) - option
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
