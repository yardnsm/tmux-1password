#!/usr/bin/env bash

# ------------------------------------------------------------------------------

# Shamelessly taken from:
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash/4025065#4025065

# ------------------------------------------------------------------------------

semver::compare() {
    if [[ $1 == $2 ]]; then
        return 0
    fi

    local IFS="."
    local i
    local version_1="$1"
    local version_2="$2"

    # Fill empty fields in version_1 with zeros
    for ((i=${#version_1[@]}; i<${#version_2[@]}; i++)); do
        version_1[i]=0
    done

    for ((i=0; i<${#version_1[@]}; i++)); do
        if [[ -z ${version_2[i]} ]]; then
            # Fill empty fields in version_2 with zeros
            version_2[i]=0
        fi

        if ((10#${version_1[i]} > 10#${version_2[i]})); then
            return 1
        fi

        if ((10#${version_1[i]} < 10#${version_2[i]})); then
            return 2
        fi
    done

    return 0
}
