#!/bin/sh

set -e
set -o pipefail

if test $# -ne 1 ; then
  echo "Usage: $0 OPAMFILE"
  exit 1
fi

opamfile=$1
shift

switch=$(dirname "$opamfile")

pkgname=$(opam show -f name "$opamfile")
pkgver=$(opam show -f version "$opamfile")
pkg=${pkgname}.${pkgver}

opam switch remove "$switch"
opam switch create "$switch" --empty
opam pin add --switch "$switch" -yn -k path "$pkg" $(dirname "$opamfile")

depends=$(opam list --switch "$switch" --required-by "$pkg" --all-versions -s)

success=
skip=
failed=
internal_failures=
for dep in $depends ; do
  res=0
  opam install --switch "$switch" -y "$dep" "$pkg" || res=$?
  opam remove --switch "$switch" -ya "$dep" "$pkg"
  case "$res" in
  0) success="$success $dep" ;;
  20) skip="$skip $dep" ;;
  31) failed="$failed $dep" ;;
  *) internal_failures="${internal_failures} $dep" ;;
  esac
done

echo
echo "----------------------"

echo
echo "These packages were skipped:"
for pkg in $skip ; do
  echo "  - $pkg"
done

echo
echo "These packages succeeded:"
for pkg in $success ; do
  echo "  - $pkg"
done

echo
echo "These packages failed:"
for pkg in $failed ; do
  echo "  - $pkg"
done

echo
echo "There was some unknown failures with:"
for pkg in ${internal_failures} ; do
  echo "  - $pkg"
done
