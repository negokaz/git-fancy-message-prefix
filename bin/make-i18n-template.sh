#!/bin/bash

cd "$(dirname "$0")/.."

readonly template_file='i18n/_template.txt'
readonly default_i18n_file='i18n/en.i18n'

for file in $(find src -type f)
do
    echo -n "buidling '${template_file}'..."
    grep --only-matching -E '{{.+}}' "${file}" \
        | awk '{ print $0 "\n\n" }' \
        > "${template_file}"
    echo 'done'
    
    echo -n "buidling '${default_i18n_file}'..."
    grep --only-matching -E '{{.+}}' "${file}" \
        | awk '{   
                    print $0
                    sub(/^{{/, "", $0)
                    sub(/}}$/, "", $0)
                    print $0 "\n"
                }' \
        > "${default_i18n_file}"
    echo 'done'
done
