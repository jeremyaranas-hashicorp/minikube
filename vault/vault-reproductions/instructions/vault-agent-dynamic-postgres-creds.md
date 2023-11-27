Set up a Vault cluster with Vault Agent and dynamic Postgresql credentials

1. Start Minikube
   1. `minikube start`
2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`
3. Configure Vault Agent and Postgresql database credentials
   1. cd to **configure_components**
      1. `./vault-agent.sh`
      2. Deploy Postgres pod
         1. `./postgresql-app-pod-01.sh`
      3. Configure Postgres database secrets engine
         1. Get IP of Postgres pod
            1. `export PG_IP=$(kubectl get pod postgres --template '{{.status.podIP}}')`
         2. Write database config
            1. `kubectl exec -ti -n vault vault-0 -- vault write database/config/postgresql plugin_name=postgresql-database-plugin connection_url="postgresql://{{username}}:{{password}}@$PG_IP:5432/postgres?sslmode=disable" allowed_roles=readonly username="root"  password="rootpassword"`
         3. Create a file for the Postgres creation statements in the Vault pod
            1. Remote into Vault pod
               1. `kubectl exec -ti -n vault vault-0 -- sh`
               2. Create file
                  1. `vi /tmp/readonly.sql` 
                  2. Add the following content
                ```
                CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;
                GRANT ro TO "{{name}}";
                ```
               3. Exit pod
         4. Write role for database config
            1. `kubectl exec -ti -n vault vault-0 -- vault write database/roles/readonly db_name=postgresql creation_statements=@/tmp/readonly.sql default_ttl=1m max_ttl=1m`
         5. Create roles in Postgres
            1. Remote into Postgres pod
               1. `kubectl exec -ti postgres -- sh`
                  1. Run the following commands
                     1. `psql -U root -c "CREATE ROLE \"ro\" NOINHERIT;"`
                     2. `psql -U root -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"ro\";"`
            2. Exit pod
      4. Update Kubernetes auth method config to work with sample application pod
         1. `kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config kubernetes_host="https://10.96.0.1:443"`
      5. Deploy sample application
         1. `./sample_app.sh`
         2. Check that credentials are automatically updated in sample application pod
            1. Remote into orgchart pod
               1. `kubectl exec -ti -n vault orgchart-<123> -- sh`
                  1. Check database-creds.txt to see credentials update
                     1. `watch -n 1 cat /vault/secrets/database-creds.txt`
         3. Check that credentials are renewed in Postgres pod
            1. Remote into Postgres pod
               1. `kubectl exec -ti postgres -- sh`
                  1. Run while loop to see credentials update
                     1. `while :; do psql -U root -c "SELECT usename, valuntil FROM pg_user;"; sleep 1; done`