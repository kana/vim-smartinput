#!/bin/bash

example_count=0

example_count=$((example_count + 1))
subject='smartinput#map_to_trigger'
example='should not beep if the cursor will be moved to an empty line'
if make TEST_TARGETS="${0%.t}.vim" test | grep --quiet --invert-match $'\a'
then
  result='ok'
else
  result='not ok'
fi
echo "$result $example_count - $subject $example"

echo "1..$example_count"

# vim: filetype=sh
