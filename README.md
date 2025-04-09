## SSL Orchestrator - Application Study Tool (AST) Transformer

This project creates the objects on the BIG-IP to support JSON-transformed consumption of SSLO summary logs to the AST otel-collector.

To install:

* Export the BIG-IP user:pass:
  ```bash
  export BIGUSER='admin:password'
  ```

* Run the installer from the BIG-IP shell:
  ```bash
  curl -s https://raw.githubusercontent.com/kevingstewart/sslo-ast-transformer/refs/heads/main/sslo-ast-transformer-installer.sh | bash
  ```

* Update the **_sslo_ast_transformer_pool_external** pool to add the AST otel-collector member IP and port (:514)

* In the Log Settings section of the SSL Orchestrator topology configuration, add the **_sslo_ast_transformer_log_pub** log publisher, and ensure that "SSL Orchestrator Generic" (logging) is set to "Information" to generate the SSL Orchestrator traffic summary logs.

----
The installer creates the following objects:
* Log parsing iRule
* External pool (points to AST otel-collector)
* Internal pool (points to transformer virtual server)
* Log destination (points to internal pool)
* Log publisher (points to log destination)
* Access log config (points to log publisher)
* Virtual server (includes the parsing iRule and points to the external otel-collector pool)
