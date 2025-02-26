#!/bin/bash

our=./2.21.5.reference
other=${1?"Usage: $0 file.ref"}

jq -n --slurpfile a $our --slurpfile b $other '
  [$a[], $b[]] | 
  group_by(.Name) | 
  map(select(length > 1) | {Name: .[0].Name, EnvDiff: ([.[0].Env - .[1].Env] + [.[1].Env - .[0].Env]) | flatten}) | 
  map(select(.EnvDiff != []))
' 
