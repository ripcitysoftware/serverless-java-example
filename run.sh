#!/usr/bin/env bash

show_help() {
cat << EOF
Usage: ${0##*/} [-hdv] [-labsp] [-o]
  Tool for building and running your Docker centric application
      -h   display this help and exit
      -d   debug mode
      -v   verbose mode. Can be used multiple times for increased verbosity

      -l   run Liquibase, this is the Docker container product-migrations
      -a   run ALL services, this will build (if '-b' also used) and run product-service
               and the DB
      -b   run the multistage-build file for this project
      -p   run the database (Postgres) and migrations only

      -o   tail output from running containers
      -s   stop ALL docker containers managed by this script
EOF
}

function log_output() {
    [[ $verbose -gt 0 ]] &&
        echo \ "running docker-compose logs -f, press ctrl-c to stop tailing output"

    [[ $logging -eq 1 ]] &&
        LIQUIBASE_PATH=./ docker-compose -f docker-compose.build.yml -f ./src/main/liquibase/docker-compose.yml logs -f
}

function db_only() {
    echo "starting the database and running migrations ONLY"
    set -x
    LIQUIBASE_PATH=./ docker-compose -f ./src/main/liquibase/docker-compose.yml up -d
    set +x

    [[ $logging -eq 1 ]] &&
         LIQUIBASE_PATH=./ docker-compose -f ./src/main/liquibase/docker-compose.yml logs -f

}

function liquibase() {
    echo "running liquibase ONLY"
    set -x
    LIQUIBASE_PATH=./ docker-compose -f ./src/main/liquibase/docker-compose.yml run --rm product-migrations
    set +x
}

function run_all() {
    echo "running ALL services"

    [[ $build -eq 1 ]] && build

    set -x
    docker-compose -f docker-compose.build.yml -f ./src/main/liquibase/docker-compose.yml up -d
    set +x

    [[ $logging -eq 1 ]] &&
        docker-compose -f docker-compose.build.yml -f ./src/main/liquibase/docker-compose.yml logs -f
}

function stop_all() {
    echo "stopping ALL services"
    set -x
    docker-compose -f docker-compose.build.yml -f ./src/main/liquibase/docker-compose.yml down
    set +x
}

function build() {
    echo "Build product-service"
    set -x
    docker-compose -f docker-compose.build.yml build --no-cache
    set +x
}

debug=
verbose=
liquibase=
all=
build=
logging=
stop=
database=

while getopts "hdvlabosp" opt; do
  case "$opt" in
       h)  show_help; exit 0;;
       d)  debug=1;;
       v)  verbose=$((verbose+1));;
       l)  liquibase=1;;
       a)  all=1;;
       b)  build=1;;
       o)  logging=1;;
       p)  database=1;;
       s)  stop=1;;
       \?) show_help >&2; exit 1;;

   esac
done

[[ $# -eq 0 ]] && show_help && exit 1

[[ $debug -eq 1 ]] && set -x

[[ $liquibase -eq 1 ]] && liquibase && exit 0

[[ $database -eq 1 ]] && db_only && exit 0

[[ $all -eq 1 ]] && run_all && exit 0

[[ $stop -eq 1 ]] && stop_all && exit 0

[[ $logging -eq 1 ]] && log_output && exit 0
