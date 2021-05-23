#!/usr/bin/env bash

#################################################################
#                                                               #
#   Tridion Content Delivery installation script                #
#                                                               #
#   Do not set the variables in this script.                    #
#   Instead put them into a script setenv.sh                    #
#                                                               #
#################################################################

declare -A delivery_vars
declare -A colours

# -------------------------------------------------------------------------- #
#   gets host IP of running system                                           #
# -------------------------------------------------------------------------- #
get_host_ip () {
    local ip
    case "$OSTYPE" in
        darwin*)
            ip=$(ipconfig getifaddr en0)
            ;;
        *)
            ip=$(hostname -I | cut -f1 -d' ')
            ;;
    esac
    echo ${ip}
}

# -------------------------------------------------------------------------- #
#   setup global variables                                                   #
# -------------------------------------------------------------------------- #
setup () {
    # do not drop this variable, since it is used in clean-target
    delivery_vars["TARGET_FOLDER"]="/usr/local/sdl/tridion"

    delivery_vars["HOST_IP"]=$(get_host_ip)
    delivery_vars["NAMESPACE_PREFIX"]="tcm"

    delivery_vars["DISCOVERY_SERVICE_URL"]="http://${delivery_vars["HOST_IP"]}:8082/discovery.svc"
    delivery_vars["CID_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8088/cid"
    delivery_vars["COMMUNITY_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8085/community.svc"
    delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8081/content.svc"
    delivery_vars["CONTEXT_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8087/context.svc"
    delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8084/v2"
    delivery_vars["DEPLOYER_WORKER_URL"]="http://${delivery_vars["HOST_IP"]}:8089/health"
    delivery_vars["IQ_INDEX_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8097/index.svc"
    delivery_vars["IQ_QUERY_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8098/search.svc"
    delivery_vars["MODERATION_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8086/moderation.svc"
    delivery_vars["PREVIEW_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8083/ws/preview.svc"
    delivery_vars["TOKEN_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8082/token.svc"
    delivery_vars["XO_MANAGEMENT_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8093/management.svc"
    delivery_vars["XO_QUERY_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8094/query.svc"
    delivery_vars["ELASTICSEARCH_URL"]="http://${delivery_vars["HOST_IP"]}:9200"
    delivery_vars["ELASTICSEARCH_HOST"]=${delivery_vars["HOST_IP"]}


    # Services
    CID=false
    COMMUNITY=false
    CONTENT=false
    CONTEXT=false
    DEPLOYER=false
    DEPLOYER_COMBINED=false
    DEPLOYER_WORKER=false
    DISCOVERY=false
    IQ_COMBINED=false
    IQ_INDEX=false
    IQ_QUERY=false
    MODERATION=false
    MONITORING=false
    PREVIEW=false
    SESSION=false
    XO_MANAGEMENT=false
    XO_QUERY=false

    PRODUCT_NAME=""
    INSTALL=false
    JENKINS=""
    SERVICES_FOLDER="$(pwd)/../../roles"
    SERVICE_PARAMETERS=""
    ENVIRONMENT_FILE="setenv.sh"
    KILL_SERVICES=false
    CLEAN_TARGET=false

    case "$OSTYPE" in
        darwin*)
            SED_OPT_I="-i .bak"
            ;;
        *)
            SED_OPT_I="-i"
            ;;
    esac

    # Output colours
    colours[normal]=$(tput sgr0)
    colours[red]=$(tput setaf 1)
    colours[green]=$(tput setaf 2)
    colours[yellow]=$(tput setaf 3)
}

# -------------------------------------------------------------------------- #
#   print info                                                               #
# -------------------------------------------------------------------------- #
info() {
  printf '%s\n' "${colours[green]}$1${colours[normal]}"
}

# -------------------------------------------------------------------------- #
#   print warning                                                            #
# -------------------------------------------------------------------------- #
warn() {
  printf '%s\n' "${colours[yellow]}$1${colours[normal]}"
}

# -------------------------------------------------------------------------- #
#   print error                                                              #
# -------------------------------------------------------------------------- #
error() {
  printf '%s\n' "${colours[red]}$1${colours[normal]}"
}

# -------------------------------------------------------------------------- #
#   print error and exit                                                     #
# -------------------------------------------------------------------------- #
fatal_error() {
  error "[!] $1"
  exit 1
}

# -------------------------------------------------------------------------- #
#   function prints information that operation is started                    #
#   and does left padding                                                    #
#                                                                            #
#   $1 - message of started operation                                        #
# -------------------------------------------------------------------------- #
log_operation_start () {
  local pad_length=72

  local log_message="$1"
  local pad=$(printf '%0.1s' "-"{1..150})

  printf '%s ' "$log_message"
  printf '%*.*s' 0 $((pad_length - ${#log_message} )) "$pad"
}

# -------------------------------------------------------------------------- #
#   function prints green status of operation                                #
# -------------------------------------------------------------------------- #
log_operation_success () {
  info " [OK]"
}

# -------------------------------------------------------------------------- #
#   function prints green status of operation, operation is skipped          #
# -------------------------------------------------------------------------- #
log_operation_skip () {
  info " [SKIP]"
}

# -------------------------------------------------------------------------- #
#   function prints red status of operation                                  #
# -------------------------------------------------------------------------- #
log_operation_fail () {
  error " [FAIL]"
}

# ----------------------------------------- #
#   Get protocol:host:port/service/mappings #
#                                           #
#   $1 - capability name                    #
# ----------------------------------------- #
get_monitoring_url () {
  local service_url="${delivery_vars[$1]}"

  echo "$service_url/mappings"
}

# -------------------------------------------------------------------------- #
#   Wait till service is up and running on host:port/service                 #
#                                                                            #
#   $1 - service name                                                        #
#   $2 - service url                                                         #
# -------------------------------------------------------------------------- #
wait_for_service_start () {
  local service_name="$1"
  local service_url="$2"

  log_operation_start "${service_name^}: wait for service to start"

  local is_started=$(curl --write-out %{http_code} --silent --output /dev/null "$service_url")
  while [ "$is_started" == "000" ]; do
    sleep 1;
    is_started=$(curl --write-out %{http_code} --silent --output /dev/null "$service_url")
  done
  log_operation_success
}

# -------------------------------------------------------------------------- #
#   function for downloading and unpacking service                           #
#                                                                            #
#   $1 - service sub folder                                                  #
#   $2 - service name                                                        #
#   $3 - target folder for unpacked service                                  #
#   $4 - jenkins folder where specified service could be located (roles)     #
# -------------------------------------------------------------------------- #
download_service() {
  local sub_folder="$1"
  local service_name="$2"
  local target="$3"
  local jenkins="$4"

  log_operation_start "${service_name^}: drop previous version of service"
  if rm -rf "$target/$service_name"; then
    log_operation_success
  else
    log_operation_fail
  fi

  log_operation_start "${service_name^}: drop previous service archive"
  if [ -f "$service_name.zip" ]; then
    if rm -f "$service_name.zip"; then
      log_operation_success
    else
      log_operation_fail
    fi
  else
    log_operation_success
  fi

  log_operation_start "${service_name^}: download service" ;
  if wget -q "$jenkins/$sub_folder/standalone/*zip*/$service_name.zip" ; then
    log_operation_success
  else
    log_operation_fail
  fi

  log_operation_start "${service_name^}: unpack service"
  if unzip -q "$service_name.zip" -d "service_unp"; then
    log_operation_success
  else
    log_operation_fail
  fi

  mv "service_unp/standalone" "$target/$service_name"

  rm -rf "service_unp"
  log_operation_start "${service_name^}: remove downloaded archive"
  if rm -f "$service_name.zip"; then
    log_operation_success
  else
    log_operation_fail
  fi
}

# -------------------------------------------------------------------------- #
#   function for copying and unpacking service                               #
#                                                                            #
#   $1 - service sub folder                                                  #
#   $2 - service name                                                        #
#   $3 - target folder for unpacked service                                  #
#   $4 - local place where specified service could be located (roles)        #
# -------------------------------------------------------------------------- #
copy_service() {
  local sub_folder="$1"
  local service_name="$2"
  local target="$3"
  local service_folder="$4"

  log_operation_start "${service_name^}: drop previous version of service"
  if rm -rf "$target/$service_name"; then
    log_operation_success
  else
    log_operation_fail
  fi

  log_operation_start "${service_name^}: copy service folder"
  if cp -r "$service_folder/$sub_folder/standalone" "$target/$service_name" ; then
    log_operation_success
  else
    log_operation_fail
  fi
}

# -------------------------------------------------------------------------- #
#   function for determining product layout                                  #
#                                                                            #
#   $1 - service folder                                                      #
# -------------------------------------------------------------------------- #
get_product_layout() {
  local service_folder="$1"
  if [ -f "${service_folder}/standalone/PRODUCT" ] ; then
    echo $(cat ${service_folder}/standalone/PRODUCT)
  fi
}

# -------------------------------------------------------------------------- #
#   function for replacing default configuration files                       #
#                                                                            #
#   $1 - service name                                                        #
#   $2 - target folder for unpacked service                                  #
# -------------------------------------------------------------------------- #
update_configurations() {
  local service_name="$1"
  local target="$2"

  log_operation_start "${service_name^}: copy template configuration files to service"
  if [ -d "config/$service_name" ]; then
    local config_count=$(find "config/$service_name" -maxdepth 1 -type f | wc -l)
    if [ ${config_count} -gt 0 ]; then
      if find "config/$service_name/." -maxdepth 1 -type f | xargs -ISRC cp SRC "$target/$service_name/config/"; then
        log_operation_success
      else
        log_operation_fail
      fi
    fi
    if [ -d "config/$service_name/$PRODUCT_NAME" ]; then
      if find "config/$service_name/$PRODUCT_NAME/." -maxdepth 1 -type f | xargs -ISRC cp SRC "$target/$service_name/config/" ; then
        log_operation_success
      else
        log_operation_fail
      fi
    fi

    local original_log_folder="${delivery_vars["./logs"]}"
    delivery_vars["./logs"]="${delivery_vars["./logs"]}/${service_name}"

    log_operation_start "${service_name^}: put predefined values to configuration files"
    local config_files="$target/$service_name/config/*.xml"
    for a in "${!delivery_vars[@]}"; do
      find $config_files -type f -exec sed ${SED_OPT_I} "s/${a//\//\\/}/${delivery_vars[$a]//\//\\/}/g" {} \;
    done
    log_operation_success

    delivery_vars["./logs"]="$original_log_folder"
  else
    log_operation_skip
  fi
}


# -------------------------------------------------------------------------- #
#   function for starting standalone service                                 #
#                                                                            #
#   $1 - folder of service to start                                          #
#   $2 - target folder of service                                            #
#   $3 - startup parameters for service                                      #
# -------------------------------------------------------------------------- #
start_service() {
  local service="$1"
  local target="$2"
  local service_parameters="$3"
  local start_script="$target/$service/bin/start.sh"

  log_operation_start "${service^}: check that start script is available"
  if [ ! -f "$start_script" ]; then
    log_operation_fail
  else
    log_operation_success
  fi

  log_operation_start "${service^}: add rights to start script"
  if chmod +x "$start_script"; then
    log_operation_success
  else
    log_operation_fail
  fi

  echo "${service^}: start service, with parameters: $service_parameters"
  bash "$start_script" "$service_parameters" >/dev/null
}

# -------------------------------------------------------------------------- #
#   function for starting standalone service                                 #
#                                                                            #
#   $1 - service sub folder                                                  #
#   $2 - service name                                                        #
#   $3 - jenkins folder where specified service could be located (roles)     #
#   $4 - local place where specified service could be located (roles)        #
#   $5 - no download or copy, services are started on default folders        #
#   $6 - startup parameters for service                                      #
# -------------------------------------------------------------------------- #
install_service() {
  local sub_folder="$1"
  local service_name="$2"
  local target=${delivery_vars["TARGET_FOLDER"]}
  local jenkins="$3"
  local service_folder="$4"
  local install="$5"
  local service_parameters="$6"

  echo
  echo "${service_name^}: start install"

  if ! "$install"; then
    log_operation_start "${service_name^}: create target directory for service"
    if [ ! -d "$target/$service_name" ]; then
      if mkdir -p "$target/$service_name"; then
        log_operation_success
      else
        log_operation_fail
      fi
    else
      log_operation_success
    fi

    if [ ! -z "$jenkins" ]; then
      download_service "$sub_folder" "$service_name" "$target" "$jenkins"
    else
      copy_service "$sub_folder" "$service_name" "$target" "$service_folder"
    fi

    copy_extensions "$service_folder" "$target"
    update_configurations "$service_name" "$target"

    start_service "$service_name" "$target" "$service_parameters"
    return 1
  else
    log_operation_start "${service_name^}: check if service is available in target folder"
    if [ -d "$target/$service_name" ]; then
      log_operation_success

      start_service "$service_name" "$target" "$service_parameters"
      return 1
    else
      log_operation_fail
    fi
    return 0
  fi
}

copy_extensions() {
  local service_folder="$1"
  local target="$2"

  if [[ ("$PRODUCT_NAME" = "docs" || "$PRODUCT_NAME" = "dx") && "$service_name" = "content" ]]; then
    rsync -a "$service_folder/content/ish-cartridge/lib/." "$target/content/services/ish-extension-cartridge"
    rsync -a "$service_folder/content/ish-cartridge/config/." "$target/content/config"
    rsync -a "$service_folder/ugc/extension-cartridge/lib/." "$target/content/services/ugc-extension-cartridge"
    rsync -a "$service_folder/ugc/extension-cartridge/config/." "$target/content/config"
  fi

  if [[ "$PRODUCT_NAME" = "dx" && "$service_name" = "session" ]]; then
    rsync -a "$service_folder/content/ish-cartridge/lib/." "$target/session/services/ish-extension-cartridge"
    rsync -a "$service_folder/content/ish-cartridge/config/." "$target/session/config"
    rsync -a "$service_folder/ugc/extension-cartridge/lib/." "$target/session/services/ugc-extension-cartridge"
    rsync -a "$service_folder/ugc/extension-cartridge/config/." "$target/session/config"
  fi
}

# -------------------------------------------------------------------------- #
#   function for parsing Elasticsearch URL                                   #
#                                                                            #
#   $1 - Elasticsearch URL                                                   #
# -------------------------------------------------------------------------- #
get_es_startup_parameters() {
    # uri capture
    local uri="$@"

    # safe escaping
    uri="${uri//\`/%60}"
    uri="${uri//\"/%22}"

    # top level parsing
    local pattern='^(([a-z]{3,5})://)?((([^:\/]+)(:([^@\/]*))?@)?([^:\/?]+)(:([0-9]+))?)(\/[^?]*)?(\?[^#]*)?(#.*)?$'
    [[ "$uri" =~ $pattern ]] || return 1;

    # component extraction
    uri=${BASH_REMATCH[0]}
    uri_schema=${BASH_REMATCH[2]}
    uri_host=${BASH_REMATCH[8]}
    uri_port=${BASH_REMATCH[10]}

    # return success
    echo "-Des.host=${uri_host} -Des.port=${uri_port} -Des.scheme=${uri_schema} -Des.ingest.host=${uri_host} -Des.ingest.port=${uri_port} -Des.ingest.scheme=${uri_schema}"
}

# -------------------------------------------------------------------------- #
#    Script's command line help                                              #
# -------------------------------------------------------------------------- #

usage () {
  echo "\
Basic options:
    -?, -h, --help                  Display this help screen

    --sites                         Tridion Sites installation
    --docs                          Tridion Docs installation
    --dx                            Tridion DX (Docs & Sites) installation

    -s, --services-folder <path>    Path to services roles in file system
    -t, --target-folder <path>      Path to installation target
    -e, --environment-file <path>   Path to environment file (default setenv.sh)

    -a, --all                       Install all services
    -i, --install                   Start services from their default location
                                    (services should be already placed there)

    --auto-register                 Enable auto registration of services
    --kill-services                 Kill Tridion processes
    --clean-target                  Clean target directory

    --enable-cid                    Install Contextual Image Delivery service
    --enable-content                Install Content service
    --enable-context                Install Context service
    --enable-deployer               Install Deployer service
    --enable-deployer-combined      Install Deployer Combined service
    --enable-deployer-worker        Install Deployer Worker service
    --enable-discovery              Install Discovery service
    --enable-monitoring             Install Monitoring service
                                    (not included in --all case)
    --enable-preview                Install Preview service (Sites / DX only)
    --enable-session                Install Session-enable Content service (Sites / DX only)
    --enable-ugc-community          Install UGC Community service
    --enable-ugc-moderation         Install UGC Moderation service
    --enable-iq-index               Install IQ Index service (Docs / DX only)
    --enable-iq-query               Install IQ Query service (Docs / DX only)
    --enable-iq-combined            Install IQ Combined service (Docs / DX only)
    --enable-xo-management          Install XO Management service (Sites / DX only)
                                    (not included in -all case)
    --enable-xo-query               Install XO Query service (Sites / DX only)
                                    (not included in -all case)

    --cid-url <url>                 Capability for CID service
    --content-url <url>             Capability for Content service
    --context-url <url>             Capability for Context service
    --deployer-url <url>            Capability for Deployer service
    --deployer-worker-url <url>     URL for Deployer Worker service
    --discovery-url <url>           Capability for Discovery service
    --elasticsearch-url <url>       URL for Elasticsearch
    --elasticsearch-host <host>     Hostname for Elasticsearch
    --iq-index-url <url>            Capability for IQ Index service
    --iq-query-url <url>            Capability for IQ Query service
    --preview-url <url>             Capability for Preview service
    --session-url <url>             Capability for Session-enabled service
    --token-url <url>               Capability for Token service
    --ugc-community-url <url>       Capability for UGC Community service
    --ugc-moderation-url <url>      Capability for UGC Moderation service
    --xo-management-url <url>       Capability for XO Management service
    --xo-query-url <url>            Capability for XO Query service

Examples:
    Install services from standard layout:
        ./quickinstall.sh --all
    Install services from layout, and auto-register using Tridion Docs product:
        ./quickinstall.sh --docs --all --auto-register
    Install services from alternative source:
        ./quickinstall.sh --all -s /home/../roles
    Install and start all services:
        ./quickinstall.sh --all --install
    Configure Content and Deployer using Discovery service on a remote machine:
        ./quickinstall.sh --discovery-url http://remote.com:8082/discovery.svc \\
            --enable-content --enable-deployer --auto-register

Cleanup:
    Stop all services:
        ./quickinstall.sh --kill-services
    Clean services folder:
        ./quickinstall.sh --clean-target
"
  exit 1
}

# -------------------------------------------------------------------------- #
#    Check Java is available                                                 #
# -------------------------------------------------------------------------- #
check_java() {
  local _java
  if type -p java > /dev/null; then
    _java=java
  elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
    _java="$JAVA_HOME/bin/java"
  else
    fatal_error "Java is not available"
  fi
  info "Java version is: $($_java -version 2>&1 | awk -F '"' '/version/ {print $2}')"
}



# -------------------------------------------------------------------------- #
#    Determine global options                                                #
# -------------------------------------------------------------------------- #
get_global_options() {
  while [ "$#" -gt 0 ]; do
    case $1 in
      -h|--help)
        usage
        ;;
      -e|--environment-file)
        shift ; ENVIRONMENT_FILE="$1"
        [ -f "$ENVIRONMENT_FILE" ] || fatal_error "Environment file does not exist: ${ENVIRONMENT_FILE}"
        ;;
      -j|--jenkins-job)
        shift ; JENKINS="$1"
        local regex='(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
        [[ $JENKINS =~ $regex ]] || fatal_error "Jenkins link is not valid"
        ;;
      -s|--services-folder)
        shift ; SERVICES_FOLDER="$1"
        [ -d "$SERVICES_FOLDER" ] || fatal_error "Services folder does not exist: ${SERVICES_FOLDER}"
        ;;
      -t|--target-folder)
        shift ; delivery_vars["TARGET_FOLDER"]="$1"
        ;;
    esac
    shift
  done
}

# -------------------------------------------------------------------------- #
#    Determine product options                                               #
# -------------------------------------------------------------------------- #
get_product_options() {
  local productLayout=$(get_product_layout "${SERVICES_FOLDER}/deployer/deployer-sites")
  deployerPrefix="deployer-sites"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --sites)
        [ "$productLayout" == "Tridion Sites" ] ||
          fatal_error "This layout does not contain the correct Tridion Sites artifacts"
        PRODUCT_NAME="sites"
        delivery_vars["NAMESPACE_PREFIX"]="tcm"
        delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8084/v2"
        ;;
      --docs)
        [ "$productLayout" == "Tridion Docs" ] ||
          fatal_error  "This layout does not contain the correct Tridion Docs artifacts"
        PRODUCT_NAME="docs"
        deployerPrefix="deployer"
        PREVIEW=false
        SESSION=false
        delivery_vars["NAMESPACE_PREFIX"]="ish"
        delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8084/v2"
        ;;
      --dx)
        [ "$productLayout" == "Tridion Sites" ] ||
          fatal_error "This layout does not contain the correct Tridion Sites artifacts"
        PRODUCT_NAME="dx"
        deployerPrefix="deployer-dx"
        delivery_vars["NAMESPACE_PREFIX"]="tcm"
        delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8084/v2"
        ;;
    esac
    shift
  done

  # Determine default product based on layout
  if [ "${PRODUCT_NAME}" == "" ] ; then
    PRODUCT_NAME=$(echo ${productLayout} | cut -f2 -d' ' | tr '[:upper:]' '[:lower:]')
  fi
}

# -------------------------------------------------------------------------- #
#    Determine service options                                               #
# -------------------------------------------------------------------------- #
get_service_options() {
  for arg in "$@" ; do
    case "$arg" in
      -a|--all)
        DISCOVERY=true
        DEPLOYER_COMBINED=true
        CID=true
        CONTEXT=true
        if [ "$PRODUCT_NAME" = "sites" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          PREVIEW=true
          SESSION=true
        else
          CONTENT=true
        fi
        COMMUNITY=true
        MODERATION=true
        IQ_COMBINED=true
        ;;
      -i|--install)
        INSTALL=true
        ;;
      --auto-register)
        SERVICE_PARAMETERS="$SERVICE_PARAMETERS --auto-register"
        ;;
      --kill-services)
        KILL_SERVICES=true
        ;;
      --clean-target)
        CLEAN_TARGET=true
        ;;
      --enable-discovery)
        DISCOVERY=true
        ;;
      --enable-deployer)
        DEPLOYER=true
        ;;
      --enable-deployer-worker)
        DEPLOYER_WORKER=true
        ;;
      --enable-deployer-combined)
        DEPLOYER_COMBINED=true
        ;;
      --enable-content)
        CONTENT=true
        ;;
      --enable-cid)
        CID=true
        ;;
      --enable-context)
        CONTEXT=true
        ;;
      --enable-preview)
        if [ "$PRODUCT_NAME" = "docs" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          PREVIEW=true
        else
          warn "There is no Preview service for Tridion Docs"
        fi
        ;;
      --enable-session)
        if [ "$PRODUCT_NAME" = "sites" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          SESSION=true
        else
          warn "There is no Session service for Tridion Docs"
        fi
        ;;
      --enable-ugc-community)
        COMMUNITY=true
        ;;
      --enable-iq-index)
        if [ "$PRODUCT_NAME" = "docs" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          IQ_INDEX=true
        else
          warn "There are no IQ services for Tridion Sites"
        fi
        ;;
      --enable-iq-query)
        if [ "$PRODUCT_NAME" = "docs" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          IQ_QUERY=true
        else
          warn "There are no IQ services for Tridion Sites"
        fi
        ;;
      --enable-iq-combined)
        if [ "$PRODUCT_NAME" = "docs" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          IQ_COMBINED=true
        else
          warn "There are no IQ services for Tridion Sites"
        fi
        ;;
      --enable-ugc-moderation)
        MODERATION=true
        ;;
      --enable-monitoring)
        if [ "$PRODUCT_NAME" = "sites" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          MONITORING=true
        else
          warn "There are no monitoring services for Tridion Docs"
        fi
        ;;
      --enable-xo-management)
        if [ "$PRODUCT_NAME" = "sites" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          XO_MANAGEMENT=true
        else
          warn "There are no XO services for Tridion Docs"
        fi
        ;;
    --enable-xo-query)
        if [ "$PRODUCT_NAME" = "sites" ] || [ "$PRODUCT_NAME" = "dx" ] ; then
          XO_QUERY=true
        else
          warn "There are no XO services for Tridion Docs"
        fi
        ;;
      --cid-url)
        shift ; delivery_vars["CID_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --content-url)
        shift ; delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --context-url)
        shift ; delivery_vars["CONTEXT_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --deployer-url)
        shift ; delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --deployer-worker-url)
        shift ; delivery_vars["DEPLOYER_WORKER_URL"]="$1"
        ;;
      --discovery-url)
        shift ; delivery_vars["DISCOVERY_SERVICE_URL"]="$1"
        ;;
      --iq-index-url)
        shift ; delivery_vars["IQ_INDEX_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --iq-query-url)
        shift ; delivery_vars["IQ_QUERY_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --preview-url)
        shift ; delivery_vars["PREVIEW_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --token-url)
        shift ; delivery_vars["TOKEN_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --ugc-community-url)
        shift ; delivery_vars["COMMUNITY_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --ugc-moderation-url)
        shift ; delivery_vars["MODERATION_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --xo-management-url)
        shift ; delivery_vars["XO_MANAGEMENT_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --xo-query-url)
        shift ; delivery_vars["XO_QUERY_SERVICE_CAPABILITY_URL"]="$1"
        ;;
      --elasticsearch-host)
        shift ; delivery_vars["ELASTICSEARCH_HOST"]="$1"
        ;;
      --elasticsearch-url)
        shift ; delivery_vars["ELASTICSEARCH_URL"]="$1"
        ;;
    esac
    shift
  done

  if "$IQ_COMBINED" ; then
    delivery_vars["IQ_QUERY_SERVICE_CAPABILITY_URL"]="http://${delivery_vars["HOST_IP"]}:8097/search.svc"
  fi
}

setup

[ $# -ne 0 ] || usage

check_java
get_global_options $@
get_product_options $@
get_service_options $@

if [ -f ${ENVIRONMENT_FILE} ]; then
  . ./${ENVIRONMENT_FILE}
fi

# -------------------------------------------------------------------------- #
#    Script should be executed with appropriate permissions                  #
# -------------------------------------------------------------------------- #
if [ ! -d "${delivery_vars["TARGET_FOLDER"]}" ]; then
  if ! mkdir -p "${delivery_vars["TARGET_FOLDER"]}" > /dev/null 2>&1; then
    fatal_error "No permissions to work with target directory. Use -h/--help to customize target directory"
  fi
elif [ ! -w "${delivery_vars["TARGET_FOLDER"]}" ]; then
  fatal_error  "No permissions to work with target directory. Use -h/--help to customize target directory"
fi

delivery_vars["DISCOVERY_SERVICE_MONITORING_URL"]=$(get_monitoring_url "DISCOVERY_SERVICE_URL")
delivery_vars["CONTENT_SERVICE_MONITORING_URL"]=$(get_monitoring_url "CONTENT_SERVICE_CAPABILITY_URL")
delivery_vars["PREVIEW_SERVICE_MONITORING_URL"]=$(get_monitoring_url "PREVIEW_SERVICE_CAPABILITY_URL")
delivery_vars["DEPLOYER_SERVICE_MONITORING_URL"]=$(get_monitoring_url "DEPLOYER_SERVICE_CAPABILITY_URL")
delivery_vars["COMMUNITY_SERVICE_MONITORING_URL"]=$(get_monitoring_url "COMMUNITY_SERVICE_CAPABILITY_URL")
delivery_vars["MODERATION_SERVICE_MONITORING_URL"]=$(get_monitoring_url "MODERATION_SERVICE_CAPABILITY_URL")
delivery_vars["CONTEXT_SERVICE_MONITORING_URL"]=$(get_monitoring_url "CONTEXT_SERVICE_CAPABILITY_URL")
delivery_vars["CID_SERVICE_MONITORING_URL"]=$(get_monitoring_url "CID_SERVICE_CAPABILITY_URL")
delivery_vars["IQ_INDEX_SERVICE_MONITORING_URL"]=$(get_monitoring_url "IQ_INDEX_SERVICE_CAPABILITY_URL")
delivery_vars["IQ_QUERY_SERVICE_MONITORING_URL"]=$(get_monitoring_url "IQ_QUERY_SERVICE_CAPABILITY_URL")
delivery_vars["XO_MANAGEMENT_SERVICE_MONITORING_URL"]=$(get_monitoring_url "XO_MANAGEMENT_SERVICE_CAPABILITY_URL")
delivery_vars["XO_QUERY_SERVICE_MONITORING_URL"]=$(get_monitoring_url "XO_QUERY_SERVICE_CAPABILITY_URL")

# -------------------------------------------------------------------------- #
#    Clean up part with killing services and removing target folder          #
# -------------------------------------------------------------------------- #
if "$KILL_SERVICES" ; then
  processes_pids=$(ps aux | grep "[c]om.sdl" | grep "ServiceContainer" | awk '{print $2}')
  if [ ! -z "$processes_pids" ]; then
    info "Stopping Tridion processes"
    kill $processes_pids
  fi
  monitor_pid=$(ps aux | grep "com.tridion.monitor.Agent" | awk '{print $2}')
  if [ ! -z "$monitor_pid" ]; then
    info "Stopping Tridion Monitor process"
    kill $monitor_pid
  fi
fi

if "$CLEAN_TARGET" ; then
  info "Cleaning target directory: ${delivery_vars["TARGET_FOLDER"]}"
  rm -rf ${delivery_vars["TARGET_FOLDER"]}
fi

if "$KILL_SERVICES" || "$CLEAN_TARGET"; then
  exit
fi

es_startup_parameters=$(get_es_startup_parameters ${delivery_vars["ELASTICSEARCH_URL"]})


# -------------------------------------------------------------------------- #
#    Starting services one by one                                            #
# -------------------------------------------------------------------------- #
echo

if [ "$PRODUCT_NAME" = "sites" ]; then
  warn "======================== Tridion Sites is enabled ========================"
elif [ "$PRODUCT_NAME" = "docs" ]; then
  warn "======================== Tridion Docs is enabled ========================="
else
  warn "======================== Tridion DX is enabled ==========================="
fi

if "$DISCOVERY" ; then
  install_service "discovery" "discovery" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "discovery" "${delivery_vars["DISCOVERY_SERVICE_URL"]}"
  fi
fi

if "$DEPLOYER" ; then
  install_service "deployer/${deployerPrefix}" "deployer" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "deployer" "${delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$DEPLOYER_WORKER" ; then
  install_service "deployer/${deployerPrefix}-worker" "deployer-worker" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
   if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "deployer-worker" "${delivery_vars["DEPLOYER_WORKER_URL"]}"
  fi
fi

if "$DEPLOYER_COMBINED" ; then
  if ! "$DEPLOYER" && ! "$DEPLOYER_WORKER" ; then
    install_service "deployer/${deployerPrefix}-combined" "deployer-combined" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
    if [[ "$?" -eq 1 ]]; then
        wait_for_service_start "deployer-combined" "${delivery_vars["DEPLOYER_SERVICE_CAPABILITY_URL"]}"
    fi
  fi
fi

if "$CONTENT"; then
  if ! "$SESSION"; then
    install_service "content" "content" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
    if [[ "$?" -eq 1 ]]; then
      wait_for_service_start "content" "${delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"]}"
    fi
  fi
fi

if "$CID" ; then
  install_service "cid" "cid" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "cid" "${delivery_vars["CID_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$CONTEXT" ; then
  install_service "context/service" "context" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "context" "${delivery_vars["CONTEXT_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$PREVIEW" ; then
  install_service "preview" "preview" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "preview" "${delivery_vars["PREVIEW_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$SESSION"; then
  install_service "session/service" "session" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "session" "${delivery_vars["CONTENT_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$COMMUNITY" ; then
  install_service "ugc/service-community" "ugc-community" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "ugc-community" "${delivery_vars["COMMUNITY_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$MODERATION" ; then
  install_service "ugc/service-moderation" "ugc-moderation" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "ugc-moderation" "${delivery_vars["MODERATION_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$MONITORING" ; then
  install_service "monitoring/agent" "monitoring" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS"
fi

if "$IQ_INDEX" ; then
  install_service "iq/iq-index" "iq-index" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS $es_startup_parameters -Des.bootstrap.enable=true"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "iq-index" "${delivery_vars["IQ_INDEX_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$IQ_QUERY" ; then
  install_service "iq/iq-query" "iq-query" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS $es_startup_parameters -Des.bootstrap.enable=true"
   if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "iq-query" "${delivery_vars["IQ_QUERY_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$IQ_COMBINED" ; then
  if ! "$IQ_INDEX" && ! "$IQ_QUERY" ; then
    install_service "iq/iq-combined" "iq-combined" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS $es_startup_parameters -Des.bootstrap.enable=true"
    if [[ "$?" -eq 1 ]]; then
        wait_for_service_start "iq-combined" "${delivery_vars["IQ_INDEX_SERVICE_CAPABILITY_URL"]}"
    fi
  fi
fi

if "$XO_MANAGEMENT" ; then
  install_service "xo/xo-management" "xo-management" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS $es_startup_parameters"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "xo-management" "${delivery_vars["XO_MANAGEMENT_SERVICE_CAPABILITY_URL"]}"
  fi
fi

if "$XO_QUERY" ; then
  install_service "xo/xo-query" "xo-query" "$JENKINS" "$SERVICES_FOLDER" "$INSTALL" "$SERVICE_PARAMETERS $es_startup_parameters"
  if [[ "$?" -eq 1 ]]; then
    wait_for_service_start "xo-query" "${delivery_vars["XO_QUERY_SERVICE_CAPABILITY_URL"]}"
  fi
fi
