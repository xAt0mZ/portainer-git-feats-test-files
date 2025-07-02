#!/bin/bash

a=${1?"Usage: $0 2.21.ref new.version.output"}
shift
b=${1?"Usage: $0 2.21.ref new.version.output"}
shift
c=${1?"Usage: $0 2.21.ref new.version.output"}
shift

jq -n --slurpfile a $a --slurpfile b $b --slurpfile c $c --arg an "${a%.json}" --arg bn "${b%.json}" --arg cn "${c%.json}" '
  [$a[][], $b[][], $c[][]]
  | group_by(.Name)
  | map(select(length > 1) | {
    Name: .[0].Name,
    $an: .[0].Env,
    $bn: .[1].Env,
    $cn: .[2].Env,
    Diff: {
      $an: (.[0].Env - .[1].Env - .[2].Env),
      $bn: (.[1].Env - .[0].Env),
      $cn: (.[2].Env - .[0].Env),
    },
  })
'
