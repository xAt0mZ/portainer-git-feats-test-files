#!/bin/bash

left=${1?"Usage: $0 2.21.ref new.version.output"}
shift
right=${1?"Usage: $0 2.21.ref new.version.output"}
shift

jq -n --slurpfile a $left --slurpfile b $right --arg left $left --arg right $right '
  [$a[][], $b[][]]
  | group_by(.Name)
  | map(select(length > 1) | {Name: .[0].Name, EnvDiff: ([.[0].Env - .[1].Env] + [.[1].Env - .[0].Env])})
  | map(select(.EnvDiff != [[],[]]))
  | map({Name:.Name, $left:.EnvDiff[0], $right:.EnvDiff[1]})
'
