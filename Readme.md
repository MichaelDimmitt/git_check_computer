## Git Check Computer Command
quickly check your computer for<br/>
projects that require git actions to be up to date with origin

quickly check your computer projects with
1) files not tracked
2) changes not staged
3) changes not committed
4) changes not pushed

## Current supported environments: 
💻&nbsp;&nbsp;&nbsp;Macintosh

If you want support for your platform please open an issue and I will upload shortly.

## How it works
#### The persist file
1) a prompt asks for your git directories within the home directory delimited by spaces. 
2) if no imput is provided the home directory is used as a default.
3) all git projects are found within git directories listed using the find command.
4) the folders found are added to a ~/.persist file

## Try it out without downloading the package:
```bash
bash <(curl -s https://raw.githubusercontent.com/MichaelDimmitt/git_check_computer/master/git_check_computer.sh)
```

## Homebrew package coming soon
