#!/bin/bash

cd "$(dirname "$0")/.."

readonly src_file='src/prepare-commit-msg.sh'

function main {
    for i18n_file in $(find i18n -name *.i18n)
    do
        local lang_name="$(basename -s '.i18n' "${i18n_file}")"
        local dist_file="$(basename -s '.sh' "${src_file}").${lang_name}"

        echo -n "building '${dist_file}'..."
        cp "${src_file}" "${dist_file}"

        while IFS=$'\t' read -r key message
        do
            perl -p -i -E "s/\\Q${key}\\E/${message//\\/\\\\}/g" "${dist_file}"
        done < <(load_msgs "${i18n_file}")

        echo 'done'
    done
}

function load_msgs {
    local i18n_file="$1"
    cat "${i18n_file}" \
        | awk '
            BEGIN {
                OFS = "\t"
            }
            {
                step        = NR % 3
                txt[step]   = $0
            }
            step == 0 {
                print txt[1], txt[2]
            }
        '
}

main
