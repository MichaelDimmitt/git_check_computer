create_persist_file() {
  echo "Please enter any folders seperated by spaces with child git directories";
  echo "If no folder is provided ~/ will be used by default";
  read answer;
  echo "Working on creating a ~/.persist file, this may take 4 minutes future lookups will be much faster!";
  echo "searching the following directory: ~/"$answer;
  find $HOME$answer -type d -name .git 2>/dev/null > ~/.persist.txt;
  cat .persist.txt | grep -v "Library/" > ~/.persist.txt;
  cat .persist.txt | wc -l;
};
create_persist_file;
