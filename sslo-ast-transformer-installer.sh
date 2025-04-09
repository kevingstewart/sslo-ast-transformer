#!/bin/bash

IRULEURL="https://raw.githubusercontent.com/kevingstewart/sslo-ast-transformer/refs/heads/main/sslo-ast-transformer-rule"

if [[ -z "${BIGUSER}" ]]
then
    echo 
    echo "The user:pass must be set in an environment variable. Exiting."
    echo "   export BIGUSER='admin:password'"
    echo 
    exit 1
fi

## Create the _sslo_ast_transformer rule
echo "..Creating the _sslo_ast_transformer_rule iRule"
rule=$(curl -sk ${IRULEURL})
data="{\"name\":\"_sslo_ast_transformer_rule\",\"apiAnonymous\":\"${rule}\"}"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "${data}" \
https://localhost/mgmt/tm/ltm/rule -o /dev/null

## Create the _sslo_ast_transformer_pool_internal pool
echo "..Creating the _sslo_ast_transformer_pool_internal pool"
## --> points to transformer VIP
tmsh create ltm pool _sslo_ast_transformer_pool_internal \
members replace-all-with { 198.18.245.245:514 }

## Create the _sslo_ast_transformer_pool_external pool (leave empty on install)
## --> points to AST otel-collector
echo "..Creating the _sslo_ast_transformer_pool_external pool"
tmsh create ltm pool _sslo_ast_transformer_pool_external

## Create the _sslo_ast_transformer_log_dest HSL log destination
## --> points to internal pool --> VIP --> external pool
echo "..Creating the _sslo_ast_transformer_log_dest log destination"
tmsh create sys log-config destination remote-high-speed-log _sslo_ast_transformer_log_dest \
protocol udp \
distribution adaptive \
pool-name _sslo_ast_transformer_pool_internal

## Create the _sslo_ast_transformer_log_pub HSL log publisher
## --> points to log destination
echo "..Creating the _sslo_ast_transformer_log_pub log publisher"
tmsh create sys log-config publisher _sslo_ast_transformer_log_pub \
destinations replace-all-with { _sslo_ast_transformer_log_dest }

## Create the _sslo_ast_transformer_logger access log (use this in SSLO log settings)
## --> points to log publisher
echo "..Creating the _sslo_ast_transformer_logger"
tmsh create apm log-setting _sslo_ast_transformer_logger \
access replace-all-with { \
general-log { \
log-level { \
access-control err \
access-per-request err \
ssl-orchestrator info } \
type ssl-orchestrator \
publisher _sslo_ast_transformer_log_pub } }

## Create the _sslo_ast_transformer_vip virtual server
## --> pools to AST otel-collector
echo "..Creating the _sslo_ast_transformer_vip virtual server"
tmsh create ltm virtual _sslo_ast_transformer_vip \
destination 198.18.245.245:514 \
ip-protocol udp \
source-address-translation { type automap } \
vlans-enabled \
profiles replace-all-with { sslo-default-udp } \
rules { _sslo_ast_transformer_rule } \
pool _sslo_ast_transformer_pool_external
