create_persist_file() {
  find $HOME -type d -name .git 2>/dev/null > ~/.persist.txt;
  cat .persist.txt | grep -v "Library/" > ~/.persist.txt;
  cat .persist.txt | wc -l;
};
create_persist_file;
