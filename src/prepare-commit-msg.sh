#!/bin/bash
#
# https://github.com/negokaz/git-fancy-message-prefix
#

function templates {
# format:
#
#   prefix:   emoji(code)   description
#
# Full Emoji List: https://unicode.org/emoji/charts/full-emoji-list.html
cat <<EOF
feat:     \U2728    {{A new feature}}
fix:      \U1f41e   {{A bug fix}}
doc:      \U1f4da   {{Documentation only changes}}
style:    \U1f484   {{Changes that do not affect the meaning of the code\n(white-space, formatting, missing semi-colons, etc)}}
refactor: \U1f528   {{A code change that neither fixes a bug nor adds a featur}}
perf:     \U1f680   {{A code change that improves performance}}
test:     \U1f6a8   {{Adding missing or correcting existing tests}}
chore:    \U1f477   {{Changes to the build process or auxiliary tools and libraries\nsuch as documentation generation}}
merge:    \U1f500
EOF
# "merge:" is a special prefix to create merge commit message.
}

readonly overview_title="{{Overview (Uncomment one of the following templates)}}"
readonly  details_title="{{Details}}"


readonly COMMIT_MSG_FILE=$1 COMMIT_SOURCE=$2 SHA1=$3

function main {
    case "${COMMIT_SOURCE}" in
        message) # use -m/-F
            local prefix="$(extract_prefix "${COMMIT_MSG_FILE}")"
            add_emoji "${prefix}" "${COMMIT_MSG_FILE}"
            ;;
        template) # use template (ex: -t option)
            : # do nothing
            ;;
        merge) # merge commit
            add_emoji ":merge" "${COMMIT_MSG_FILE}"
            ;;
        squash) # squash commits in a branch with --squash
            : # do nothing
            ;;
        commit) # use -c/-C/--amend
            if is_interactive "${COMMIT_MSG_FILE}"
            then
                local prefix="$(extract_prefix_without_emoji "${COMMIT_MSG_FILE}")"
                apply_template "${prefix}" "${COMMIT_MSG_FILE}"
            fi
            ;;
        *) # no option
            create_full_template "${COMMIT_MSG_FILE}"
            ;;
    esac
}

function create_full_template {
    local message_file="$1"
    local msg_temp_file="$(mktemp)"
    {
        echo "# ${overview_title}"
        print_templates
        echo ""
        echo "# ${details_title}"
        echo ""
        cat "${message_file}"
    } > "${msg_temp_file}"

    cat "${msg_temp_file}" > "${message_file}"
    rm  "${msg_temp_file}"
}

function apply_template {
    local prefix="$1" message_file="$2"
    local msg_temp_file="$(mktemp)"
    local template=$(select_template "${prefix}")
    {
        if [[ -z "${template}" ]]
        then
            # invalid prefix
            extract_title "${message_file}"
            print_templates
        else
            # valid prefix
            local title="$(extract_title_without_prefix "${message_file}")"
            print_templates "${prefix}" "${title}"
        fi
        echo
        echo "# ${details_title}"
        echo
        extract_details "${message_file}"
    } > "${msg_temp_file}"

    cat "${msg_temp_file}" > "${message_file}"
    rm  "${msg_temp_file}"
}

function print_templates {
    local apply_prefix="$1" apply_title="$2"

    templates | grep -v '^merge:' | sed -e 's/\\/\\\\/g' \
        | while read prefix emoji description
        do
            if [[ "${apply_prefix}" = "${prefix}" ]]
            then
                echo "$(emoji_char "${emoji}")${prefix}${apply_title}"
            else
                echo "#$(emoji_char "${emoji}")${prefix} "
            fi
            echo -e "${description}" | awk '
                NR == 1 {
                    print "#  └ " $0
                }
                NR != 1 {
                    print "#    " $0
                }
            '
        done
}

function add_emoji {
    local prefix="$1"
    local message_file="$2"

    local template=$(select_template "${prefix}")
    local emoji=$(emoji_of "${template}")

    local msg_temp_file="$(mktemp)"
    
    echo "${emoji}$(cat ${message_file})" > "${msg_temp_file}"
    cat "${msg_temp_file}" > "${message_file}"
    rm  "${msg_temp_file}"
}

function select_template {
    templates | awk -v prefix="$1" '$1 == prefix'
}

function decode_emoji {
    perl -CO -pE 's/\\u(\p{Hex}+)/chr(hex($1))/xieg'
}

function emoji_char {
    echo "$1" | decode_emoji
}

function emoji_of {
    local template="$1"
    echo "${template}" | awk '{ print $2 }' | decode_emoji
}

function is_interactive {
    local message_file="$1"
    # If it is interactive mode, it may contain comment lines ('^#')
    grep -E '^#' "${message_file}" &> /dev/null
}

function extract_prefix {
    local file="$1"
    extract_title "${file}" | awk '{ print $1 }'
}

function extract_prefix_without_emoji {
    local file="$1"
    extract_prefix "${file}" | sed -E 's/[^a-zA-Z0-9:]//g'
}

function extract_title {
    local file="$1"
    cat "${file}" | head -n 1
}

function extract_title_without_prefix {
    local file="$1"
    extract_title "${file}" | awk '{ $1 = ""; print }'
}

function extract_details {
    local file="$1"
    cat "${file}" | tail -n +3
}

main
