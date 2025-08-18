#!/usr/bin/env bash

# Aggregate all the extracted data from test automation into a single file
# And compare all versions together

if [ $# -lt 2 ]; then
  echo "Usage: $0 <base_ref.json> <to_compare.json> [to_compare.json ...]"
  exit 1
fi

# Build the jq command dynamically
files=("$@")
slurpfile_args=""
arg_params=""
file_vars=""
env_array=""
result_fields=""
diff_fields=""

for i in "${!files[@]}"; do
  file="${files[$i]}"
  varname="file$i"
  basename="${file%.json}"

  # Build slurpfile arguments
  slurpfile_args="$slurpfile_args --slurpfile $varname \"$file\""

  # Build arg parameters for basenames
  arg_params="$arg_params --arg ${varname}_name \"$basename\""

  # Build file variable references for the array
  if [ $i -eq 0 ]; then
    file_vars="\$$varname[][]"
    env_array="\$$varname[][]"
  else
    file_vars="$file_vars, \$$varname[][]"
    env_array="$env_array, \$$varname[][]"
  fi

  # Build result fields (using variable names from --arg)
  result_fields="$result_fields, (\$${varname}_name): .[${i}].Env"

  # Build diff fields - compare each file against the first one
  if [ $i -eq 0 ]; then
    diff_fields="(\$${varname}_name): (.[${i}].Env - (.[1:] | map(.Env) | add // []))"
  else
    diff_fields="$diff_fields, (\$${varname}_name): (.[${i}].Env - .[0].Env)"
  fi
done

# Remove leading comma and space from result_fields
result_fields="${result_fields#, }"

# Build the complete jq command
jq_command="jq -n $slurpfile_args $arg_params '
  [$env_array]
  | group_by(.Name)
  | map(select(length > 1) | {
    Name: .[0].Name,
    $result_fields,
    Diff: {
      $diff_fields
    }
  })
'"

# Execute the command
eval "$jq_command"

exit
