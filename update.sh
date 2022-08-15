#!/bin/bash
# Derived from https://github.com/postgis/docker-postgis/blob/master/update.sh
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
    versions=( */Dockerfile )
fi
versions=( "${versions[@]%/Dockerfile}" )

for image in default osm2pgr; do
    rm -f      _dockerlists_${image}.md
    echo " " > _dockerlists_${image}.md
    echo "| DockerHub image | Dockerfile | OS | Postgres | PostGIS | pgRouting |" >> _dockerlists_${image}.md
    echo "| --------------- | ---------- | -- | -------- | ------- | --------- |" >> _dockerlists_${image}.md
done

dockerhublink="https://hub.docker.com/r/pgrouting/pgrouting/tags?page=1&name="
githubrepolink="https://github.com/pgRouting/docker-pgrouting/blob/master"

# sort version numbers with highest last (so it goes first in .travis.yml)
IFS=$'\n'; versions=( $(echo "${versions[*]}" | sort -V) ); unset IFS

defaultDebianSuite='bullseye-slim'
declare -A debianSuite=(
    # https://github.com/docker-library/postgres/issues/582
    [10]='bullseye-slim'
    [11]='bullseye-slim'
    [12]='bullseye-slim'
    [13]='bullseye-slim'
    [14]='bullseye-slim'
)

defaultPostgisDebPkgNameVersionSuffix='3'
declare -A postgisDebPkgNameVersionSuffixes=(
    [2.5]='2.5'
    [3.0]='3'
    [3.1]='3'
    [3.2]='3'
)

for version in "${versions[@]}"; do
    IFS=- read postgresVersion postgisVersion pgroutingVersion <<< "$version"

    # Extract the latest patch release for a given major.minor release (unchanged for main/develop version)
    pgroutingFullVersion="$pgroutingVersion"
    if [ "$pgroutingVersion" != "develop" ] && [ "$pgroutingVersion" != "main" ]; then
        pgroutingFullVersion="$(git ls-remote --refs --sort='v:refname' https://github.com/pgrouting/pgrouting.git | grep -F "$pgroutingVersion" | cut --delimiter='/' --fields=3 | tail -n 1)"
        # Convert vA.B.C to A.B.C
        pgroutingFullVersion="${pgroutingFullVersion:1}"
    fi

    echo " "
    echo "---- generate Dockerfile for $version ----"
    echo "postgresVersion=$postgresVersion"
    echo "postgisVersion=$postgisVersion"
    echo "pgroutingFullVersion=$pgroutingFullVersion"

    if [ "2.5" == "$postgisVersion" ]; then
        # posgis 2.5 only in the stretch ; no bullseye version
        tag='stretch-slim'
    else
        tag="${debianSuite[$postgresVersion]:-$defaultDebianSuite}"
    fi
    suite="${tag%%-slim}"

    srcVersion="${pgroutingFullVersion}"
    if [ "$pgroutingFullVersion" == "develop" ] || [ "$pgroutingFullVersion" == "main" ]; then
        srcSha256=""
        pgroutingGitHash="$(git ls-remote https://github.com/pgrouting/pgrouting.git heads/${pgroutingFullVersion} | awk '{ print $1}')"
    else
        srcSha256="$(curl -sSL "https://github.com/pgRouting/pgrouting/archive/v${srcVersion}.tar.gz" | sha256sum | awk '{ print $1 }')"
        pgroutingGitHash=""
    fi
    (
        set -x
        cp -p initdb-pgrouting.sh update-pgrouting.sh "$version/"
        cp -p -r Dockerfile.template README.md.template docker-compose.yml.template extra "$version/"
        if [ "$pgroutingFullVersion" == "develop" ] || [ "$pgroutingFullVersion" == "main" ]; then
            cp -p Dockerfile.develop.template "$version/Dockerfile.template"
        fi
        mv "$version/Dockerfile.template" "$version/Dockerfile"
        sed -i 's/%%PG_MAJOR%%/'"$postgresVersion"'/g; s/%%POSTGIS_VERSION%%/'"$postgisVersion"'/g; s/%%PGROUTING_VERSION%%/'"$pgroutingVersion"'/g; s/%%PGROUTING_FULL_VERSION%%/'"$pgroutingFullVersion"'/g; s/%%PGROUTING_SHA256%%/'"$srcSha256"'/g; s/%%PGROUTING_GIT_HASH%%/'"$pgroutingGitHash"'/g; ' "$version/Dockerfile"
        mv "$version/README.md.template" "$version/README.md"
        sed -i 's/%%PG_MAJOR%%/'"$postgresVersion"'/g; s/%%POSTGIS_VERSION%%/'"$postgisVersion"'/g; s/%%PGROUTING_VERSION%%/'"$pgroutingVersion"'/g; s/%%PGROUTING_FULL_VERSION%%/'"$pgroutingFullVersion"'/g;' "$version/README.md"
        mv "$version/docker-compose.yml.template" "$version/docker-compose.yml"
        sed -i 's/%%PG_MAJOR%%/'"$postgresVersion"'/g; s/%%POSTGIS_VERSION%%/'"$postgisVersion"'/g; s/%%PGROUTING_VERSION%%/'"$pgroutingVersion"'/g; s/%%PGROUTING_FULL_VERSION%%/'"$pgroutingFullVersion"'/g;' "$version/docker-compose.yml"

        echo "| [pgrouting/pgrouting:${version}](${dockerhublink}${version}) | [Dockerfile](${githubrepolink}/${version}/Dockerfile) | ${postgresVersion} | ${postgisVersion} | ${pgroutingFullVersion} |" >> _dockerlists_default.md

        mv "$version/extra/Dockerfile.template" "$version/extra/Dockerfile"
        sed -i 's/%%PG_MAJOR%%/'"$postgresVersion"'/g; s/%%POSTGIS_VERSION%%/'"$postgisVersion"'/g; s/%%PGROUTING_VERSION%%/'"$pgroutingVersion"'/g; s/%%PGROUTING_FULL_VERSION%%/'"$pgroutingFullVersion"'/g;' "$version/extra/Dockerfile"
    
        echo "| [pgrouting/pgrouting:${version}-osm2pgr](${dockerhublink}${version}-osm2pgr) | [Dockerfile](${githubrepolink}/${version}/extra/Dockerfile) | ${postgresVersion} | ${postgisVersion} | ${pgroutingFullVersion} |" >> _dockerlists_osm2pgr.md
    )
done

echo "|-------------------------|"
echo "|-   Generated images    -|"
echo "|-------------------------|"

for image in default osm2pgr; do
    echo " "
    echo "---- ${image} ----"
    cat _dockerlists_${image}.md
done

echo " "
echo "Postprocessing todo:"
echo "- add the new versions to README.md ( manually )"
ls -la  _dockerlists_*.md
echo " "
echo " - done - "
