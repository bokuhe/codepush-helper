# codepush-helper

Utility script to make codepush deploy

## Feature

- Deploy codepush with a simple command
- Manage various projects at once
- Automatic git tag creation

## Prerequisites

- Optimized and tested for macOS
- Installed 'appcenter-cli' and logged in into appcenter
- Installed 'jq'

## Usage

1. Clone repo
2. Add project settings to 'codepush-helper.sh'

```
#===============
# CONFIGURATIONS
#===============
TEST=false

GIT_REMOTE="origin"

# name, workdir, codepush-app(without '-$platform')
P1=("station" "/Users/bokuhe/station" "codepush-project/station")
P2=(...)
PROJECTS=(P1 P2 ...)
```

3. Add execute permission to 'codepush-helper.sh'

```
$ chmod +x codepush-helper.sh
```

4. Run script

```
$ ./codepush-helper.sh release station production
```

## License

[Apache2](LICENSE)
