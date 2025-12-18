#!/usr/bin/env bash

if [[ -z "${BIGUSER}" ]]
then
    echo 
    echo "The user:pass must be set in an environment variable. Exiting."
    echo "   export BIGUSER='admin:password'"
    echo 
    exit 1
fi

## Create the _sslo_ast_pool pool (leave empty on install)
## --> points to AST otel-collector
echo "..Creating the _sslo_ast_pool pool (empty at install)"
tmsh create ltm pool _sslo_ast_pool

## Create the _sslo_ast_log_dest HSL log destination
## --> points to _sslo_ast_pool pool
echo "..Creating the _sslo_ast_log_dest log destination"
tmsh create sys log-config destination remote-high-speed-log _sslo_ast_log_dest \
protocol udp \
distribution adaptive \
pool-name _sslo_ast_pool

## Create the _sslo_ast_log_pub HSL log publisher
## --> points to log destination
echo "..Creating the _sslo_ast_log_pub log publisher"
tmsh create sys log-config publisher _sslo_ast_log_pub \
destinations replace-all-with { _sslo_ast_log_dest }

## Create the _sslo_ast_logger access log (use this in SSLO log settings)
## --> points to log publisher
echo "..Creating the _sslo_ast_logger"
tmsh create apm log-setting _sslo_ast_logger \
access replace-all-with { \
general-log { \
log-level { \
access-control err \
access-per-request err \
ssl-orchestrator info } \
type ssl-orchestrator \
publisher _sslo_ast_log_pub } }

echo "..All objects created. Update the _sslo_ast_pool with the IP address of the AST otel-collector node"
exit 0


