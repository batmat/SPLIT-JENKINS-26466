#!/bin/bash

# Quick & Dirty Git manip script for JENKINS-26466

set -eou pipefail

# comment those two lines if you don't have like me two remotes for the jenkins repo
git remote rm origin
git remote rm upstream

echo "deleting tags"
for tag in $(git tag)
do
  git tag -d $tag
done

echo "moving associated tests"
git mv test/src/test/java/hudson/node_monitors/ core/src/test/java/hudson/
git ci -m 'Move node_monitors along the associated code before split'

echo "Keeping only node_monitors"
git filter-branch \
       --msg-filter 'cat; echo "previous-sha: $GIT_COMMIT"' \
       --index-filter \
          'git rm --cached -qr -- . && \
           git reset -q $GIT_COMMIT -- \
              core/src/main/java/hudson/node_monitors \
              core/src/main/resources/hudson/node_monitors \
              ' \
       --prune-empty \
       -- --all

echo "subdirectory filtering core"
git filter-branch -f \
       --subdirectory-filter core \
       --prune-empty \
       -- --all

echo "Cleaning/pruning!"
git clean -df
git gc --aggressive --prune=now
