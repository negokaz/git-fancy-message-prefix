# Development Guide

## When you added some messages for i18n

Run `bin/make-i18n-template.sh`

The script build:

- i18n/
    - _template.txt
    - en.i18n

## When you maked change src

Run `bin/make-dist.sh`

The script build:

- / (project root)
    - prepare-commit-msg.*
    - (for each language file in the `i18n` directory)
