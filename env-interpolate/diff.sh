#!/bin/bash

left=${1?"Usage: $0 2.21.ref new.version.output"}
shift
right=${1?"Usage: $0 2.21.ref new.version.output"}
shift

jq -n --slurpfile a $left --slurpfile b $right --arg left "${left%.json}" --arg right "${right%.json}" '
  [$a[][], $b[][]]
  | group_by(.Name)
  | map(select(length > 1) | {
    Name: .[0].Name,
    $left: .[0].Env,
    $right: .[1].Env,
    Diff: {
      $left: (.[0].Env - .[1].Env),
      $right: (.[1].Env - .[0].Env),
    },
  })
  | map(select(.Diff.[$left] != [] and .Diff.[$right] != [] ))
'
