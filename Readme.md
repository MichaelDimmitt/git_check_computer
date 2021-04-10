#### Info:
To see all overrides navigate to: https://github.com/MichaelDimmitt/my-bashrc-git-overrides

## Git Check Computer Command
quickly check your computer for<br/>
projects that require git actions to be up to date with origin

quickly check your computer projects with
1) files not tracked
2) changes not staged
3) changes not committed
4) changes not pushed

## Current supported environments: 
💻&nbsp;&nbsp;&nbsp;Macintosh<br/>
🐧&nbsp;&nbsp;&nbsp;Ubuntu - Linux

If you want support for your platform please open an issue and I will upload shortly.

## How it works
#### The persist file
1) a prompt asks for your git directories within the home directory delimited by spaces. 
2) if no input is provided the home directory is used as a default.
3) all git projects are found within git directories listed using the find command.
4) the folders found are added to a ~/.persist file

## Try it out without downloading the package:
```bash
bash <(curl -s https://raw.githubusercontent.com/MichaelDimmitt/git_check_computer/master/git_check_computer.sh)
```

## Homebrew package 
#### coming soon

## Demonstration, Use Existing Persist File
![use-existing-persist-file-take2](https://user-images.githubusercontent.com/11463275/97744153-21044080-1abd-11eb-9a4a-3e21a4992f7b.gif)

## Demonstration, Create Persist File
![update-persist-file](https://user-images.githubusercontent.com/11463275/97929687-aeeb6000-1d37-11eb-8053-e4084f577c49.gif)
