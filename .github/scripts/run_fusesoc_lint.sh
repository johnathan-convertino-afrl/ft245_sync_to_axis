#!/bin/bash

printf "Add verible to path\n"

export PATH=$(pwd)/verible/bin/:$PATH 

core_name=$(fusesoc --cores-root . list-cores | tail -1 | awk '{print$1}')

printf "Found Core: %s\n" $core_name

fusesoc --cores-root . run --target lint $core_name
