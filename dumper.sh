#!/usr/bin/env sh
set -x

DUMP_DIR=$(mktemp -p /tmp -d)

trap cleanup EXIT

cleanup() {
  if [ -n "$DUMP_DIR" ]; then
    \rm -rf "$DUMP_DIR"
  fi
}

kubectl get pods -A -o json | jq -r '.items[] | [.metadata.namespace, .metadata.name] | @tsv' |
  while IFS=$'\t' read -r namespace name; do
    kubectl -n "$namespace" get pods "$name" -o yaml > "$DUMP_DIR"/"$namespace"-"$name".yaml
    kubectl -n "$namespace" logs "$name" --all-containers > "$DUMP_DIR"/"$namespace"-"$name".log
  done

NOW=$(date +%Y%m%d%H%M%S)
tar -zcvf dump-"$NOW".tar.gz "$DUMP_DIR"