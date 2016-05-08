#!/bin/bash
function die(){
  echo "$1" 1>&2
  exit 1
}

dir="$1"
[ -z "$dir" ] && dir=`pwd`
gem=`basename --suffix=.dir "$dir"`

set -e

#"install"
[ -e ~/tarrunner_bin/gzip ] || ln -s `which gzip` ~/tarrunner_bin/gzip

#todo: cleanup temp files and *.gz

cd "$dir"
rm -f metadata.gz
textrecv --as-tarrunner gzip -c -9 -n metadata >metadata.gz
chmod a-wx metadata.gz

#check for permissions problems
for badperm in `find data ! -perm /o+r`; do
  die "unreadable file in gem: $badperm"
done

rm -f data.tar.gz

cd data
  textrecv --as-tarrunner \
    tar czf - `find . -mindepth 1 -maxdepth 1| cut -d/ -f2-` \
      --owner=wheel --group=wheel \
      >../data.tar.gz
  chmod a-wx ../data.tar.gz
cd ..

#make sure every file mentioned in $dir/contents
#is present in $dir/data/ and vice versa
temp=`tempfile -p rgemt`
find data -type f | cut -d/ -f2- | cat - contents | sort | uniq -u >"$temp"
if [ -s "$temp" ]; then
  echo "mismatch(es) between contents and data/ : "
  cat "$temp"
  exit 1
fi 1>&2

#was:
  #while read cfile; do
  #  if [ ! -e "$cfile" ]; then
  #    echo "file missing from contents: $cfile" 1>&2
  #    exit 1
  #  fi
  #done <../contents


#ensure only allowed file contents (from current project) in gem
gem_sha=`tempfile -p gemsh`
git_sha=`tempfile -p gitsh`
from_gem=`tempfile -p fmgem`
from_git=`tempfile -p fmgit`
find data -type f | \
     cut -d/ -f2- | \
     ( cd data; xargs -L20 sha512sum ) >"$gem_sha"
     cut -d" " -f1      <"$gem_sha"       >"$from_gem"

( cd ..;
  git ls-files | \
    xargs -L20 sha512sum
) >"$git_sha"
cut -d" " -f1      <"$git_sha"        >"$from_git"





#set difference: from_gem - from_git
gem_only=`tempfile -p gemol`
cat "$from_gem" "$from_git" "$from_git" | sort | uniq -u >"$gem_only"
#other way is ok: don't care about files in git only

if [ -s "$gem_only" ] ; then
  echo "file contents found only in gem:" 1>&2
  egrep `perl -wpe 's/\n/|/' <"$gem_only"`jjjjjjjjjjjjjjjjjjjjj "$gem_sha"| cut -d" " -f2-
  exit 1
fi

#make sure that files are checked in to git
gitstatus=`tempfile -p gitst`
cd ..
git status --porcelain |egrep -v '^\?\? ' >"$gitstatus" || true
if [ -s "$gitstatus" ]; then
  echo "error: files in project not completely checked in:" 1>&2
  cat "$gitstatus"
  exit 1
fi
if ! git branch|egrep -q '^\* master$' ; then
  die "error: please be on master"
fi
if ! git log -1 --format=format:%d master | egrep -q '[( ]origin/master,' ; then
  die "error: please push all changes on master"
fi
cd "$dir"


#compose new checksums.yaml(.gz) with correct sha512s for repacked files
rm -f checksums.yaml{,.gz}
{
  echo ---
  echo SHA512:
  echo -n '  metadata.gz: ' ; sha512sum metadata.gz|cut -d" " -f1
  echo -n '  data.tar.gz: ' ; sha512sum data.tar.gz|cut -d" " -f1
} > checksums.yaml
chmod a-wx checksums.yaml
textrecv --as-tarrunner gzip -c -9 -n checksums.yaml >checksums.yaml.gz

#pack data.tar.gz, metadata, checksums.yaml up as gem file
textrecv --as-tarrunner tar cf -    \
  metadata.gz data.tar.gz checksums.yaml.gz \
  --owner=wheel --group=wheel >../"$gem"

