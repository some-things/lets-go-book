#!/usr/bin/env bash

MYSQL_CHART_VERSION="9.1.4"
PROJECT_NAMESPACE="snippetbox"
SCRIPT_DIR="$(dirname "${BASH_SOURCE[@]}")"

main() {
  echo "Creating kind cluster"
  kind create cluster

  echo "Creating namespace"
  kubectl create ns $PROJECT_NAMESPACE

  echo "Deploying mysql chart"
  helm upgrade --install my-mysql bitnami/mysql --version $MYSQL_CHART_VERSION \
    --namespace $PROJECT_NAMESPACE --create-namespace --wait

  echo "Connecting via telepresence"
  telepresence quit && telepresence connect --no-report

  MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace ${PROJECT_NAMESPACE} my-mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)

  cat <<EOF
Deployment complete - you can now connect to the cluster via telepresence!

MySQL Username: root
MySQL Password: kubectl get secret --namespace ${PROJECT_NAMESPACE} my-mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d

export MYSQL_ROOT_PASSWORD=\$(kubectl get secret --namespace ${PROJECT_NAMESPACE} my-mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)
mysql -h my-mysql.${PROJECT_NAMESPACE}.svc.cluster.local -uroot -p"\$MYSQL_ROOT_PASSWORD"
EOF

  echo "Executing SQL"
  mysql -h my-mysql.${PROJECT_NAMESPACE}.svc.cluster.local -u root -p"${MYSQL_ROOT_PASSWORD}" <"${SCRIPT_DIR}/base.sql"

  echo "Successfully created base infra"
}

main
