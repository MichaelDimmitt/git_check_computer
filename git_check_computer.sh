run_with_dots() {
  # https://stackoverflow.com/a/25904176/5283424
  "$@" &
  while kill -0 $!
  do
      printf '.' > /dev/tty;
      sleep 2;
  done
  printf '\n' > /dev/tty;
}

create_persist_file() {
  echo "Please enter any folders seperated by spaces with child git directories";
  echo "If no folder is provided ~/ will be used by default";
  echo -e " \033[5;31;47m awaiting input: \033[0m"
  read answer;
  echo -e " \033[5;32;47m pass! no longer awaiting input: \033[0m"
  echo "Working on creating a ~/.persist file, this may take 4 minutes future lookups will be much faster!";
  echo "searching the following directory: $HOME/$answer";
  run_with_dots find $HOME/$answer -type d -name .git 2>/dev/null > ~/.persist.txt;
  cat ~/.persist.txt | grep -v "Library" > fold.txt && mv fold.txt ~/.persist.txt;
  cat ~/.persist.txt | wc -l;
};

[ -f ~/.persist.txt ] || (
  echo "creating persist file";
  create_persist_file;
)
[ -f ~/.persist.txt ] &&  
  ( echo "persist file, type [Uu] to update or any character to continue";
    old_stty_cfg=$(stty -g);
    stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg;
    if echo "$answer" | grep -iq "^u" ;then
        echo "updating persist file";
        create_persist_file;
    else
        echo No;
    fi )

unset -f run_with_dots;
unset -f create_permission_file;
