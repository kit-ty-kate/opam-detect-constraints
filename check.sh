#!/bin/sh

set -e
#set -o pipefail

if test $# -ne 0 ; then
  echo "Usage: $0 OPAMFILE"
  exit 1
fi

opamfile=./$1
shift

# TODO: Does not support complex dependencies (OR, explicit AND)
depends=$(opam show -f depends "$opamfile" | sed -E -e 's/ .*//' -e 's/.*"(.*)".*/\1/')

criteria="+removed,+count[version-lag,solution]"

export OPAMCRITERIA=$criteria
export OPAMFIXUPCRITERIA=$criteria
export OPAMUPGRADECRITERIA=$criteria
export OPAMEXTERNALSOLVER=builtin-0install

opam switch create . --empty

success=
failed=
internal_failures=
for dep in $depends ; do
  for ver in $(opam show -f all-versions "$dep") ; do
    pkg=${dep}.${ver}
    opam install "$opamfile" "$pkg"; res=$?
    case "$res" in
    0) success="$success $pkg" ;;
    20) ;;
    31) failed="$failed $pkg" ;;
    *) internal_failures="${internal_failures} $pkg" ;;
    esac
  done
done

echo
echo "This package succeeded with:"
for pkg in $success ; do
  echo "  - $pkg"
done

echo
echo "This package failed with:"
for pkg in $failed ; do
  echo "  - $pkg"
done

echo
echo "There was some unknown failures with:"
for pkg in ${internal_failures} ; do
  echo "  - $pkg"
done
