#!/usr/bin/env bash

TOKEN_FILE="./token" # generate and put your token in a file named token
URL="" # add your foundry url
CATALOG=${URL}"/foundry-catalog/api"
DATA_PROXY=${URL}"/foundry-data-proxy/api"

DATASET="ri.foundry.main.dataset.<uuid>" # add the rid for the dataset to append to

function startTransaction {
  datasetRid=$1
  txnRid=$(curl -k "$CATALOG/catalog/datasets/${datasetRid}/transactions" -H "Authorization: Bearer $(cat $TOKEN_FILE)" -H "Content-Type: application/json" -d '{"branchId": "master"}' | jq ".rid" | sed "s/\"//g") 
  echo $txnRid
}

function setTransactionTypeToAppend {
  datasetRid=$1
  txnRid=$2
  curl -k "$CATALOG/catalog/datasets/${datasetRid}/transactions/${txnRid}" -H "Authorization:Bearer $(cat $TOKEN_FILE)" -H "Content-Type: application/json" -d '"APPEND"'
}

function commitTransaction {
  datasetRid=$1
  txnRid=$2
  curl -k "$CATALOG/catalog/datasets/${datasetRid}/transactions/${txnRid}/commit" -H "Authorization:Bearer $(cat $TOKEN_FILE)" -H "Content-Type: application/json" -d '{}'
}

function addFileToTransaction {
  datasetRid=$1
  txnRid=$2
  file=$3

  curl -k "$DATA_PROXY/dataproxy/datasets/${datasetRid}/transactions/${txnRid}/putFile?logicalPath=${file}" -H "Authorization: Bearer $(cat $TOKEN_FILE)" -H "Content-Type: application/json" -d @$file

}



function addFile {

  file=$1
  
  txnRid=""

  txnRid=$(startTransaction $DATASET)
  echo "Transaction Started: $DATASET $txnRid"

  setTransactionTypeToAppend $DATASET $txnRid
  echo "Set transaction to append: $txnRid"

  addFileToTransaction $DATASET $txnRid $file
  echo "Added file to transaction: $file"

  commitTransaction $DATASET $txnRid
  echo "Committed transaction"
}


function addAllJsonFiles {
  for file in $(ls *.json);
    do addFile $file
  done
}

addAllJsonFiles
