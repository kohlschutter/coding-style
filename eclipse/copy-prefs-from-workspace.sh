#!/bin/bash
#
# Copies coding style preferences from the Eclipse workspace configuration
# and modifies it for our purposes.
#
# Calling this script is only necessary if you want to modify the preferences.
#

cd $(pwd)
d=$(dirname "$(pwd)")
while [ ! -d "$d/.metadata/.plugins" ]; do
  d1=$d
  d=$(dirname "$d")
  if [ -z "$d" -o "$d" == "$d1" ]; then
    break
  fi
done

settingsFile="$d/.metadata/.plugins/org.eclipse.core.runtime/.settings/org.eclipse.jdt.core.prefs"
if [ ! -f "$settingsFile" ]; then
  echo "Could not find settings file: $settingsFile" >&2
  exit 1
fi

echo "Using settings from: $settingsFile"
cat "$settingsFile" | egrep "eclipse.preferences|org.eclipse.jdt.core.(formatter|compiler)" | \
  sort -u > org.eclipse.jdt.core.prefs

cat org.eclipse.jdt.core.prefs | grep -q "org.eclipse.jdt.core.compiler.doc.comment.support"
if [ $? -ne 0 ]; then
  echo "Enabling Javadoc support (missing from original preferences)"
  echo "org.eclipse.jdt.core.compiler.doc.comment.support=enabled" >> org.eclipse.jdt.core.prefs
fi

for v in 6 7; do
  out="java$v-org.eclipse.jdt.core.prefs"
  outStrict="java$v-strict-org.eclipse.jdt.core.prefs"
  echo "Creating preference files for Java compliance level 1.$v in $out and $outStrict"
  cat org.eclipse.jdt.core.prefs | \
    egrep -v "org.eclipse.jdt.core.compiler.(codegen.targetPlatform|compliance|source|problem.suppressOptionalErrors)" > $out
  cat >>$out <<EOT
org.eclipse.jdt.core.compiler.codegen.targetPlatform=1.$v
org.eclipse.jdt.core.compiler.compliance=1.$v
org.eclipse.jdt.core.compiler.source=1.$v
org.eclipse.jdt.core.compiler.problem.suppressOptionalErrors=enabled
EOT
  cat $out | gsed -r "s/=warning$/=error/g" > $outStrict
done

rm org.eclipse.jdt.core.prefs
