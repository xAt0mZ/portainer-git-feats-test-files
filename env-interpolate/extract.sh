#!/bin/bash

docker ps -a --format "{{.Names}}" | grep '^with' | xargs -I {} docker inspect {} | jq '.[0] |
  {
    Name: .Name | .[1:-7],
    Env: .Config.Env | map(select(test("^(A|B|C)="))) | sort_by(if test("^A=") then 0 elif test("^B=") then 1 else 2 end),
  }'
