#!/bin/bash

LCMD="aws lambda --endpoint-url=http://localhost:4574"
DCMD="aws dynamodb --endpoint-url=http://localhost:4569"
ACMD="aws apigateway --endpoint-url=http://localhost:4567"

BUILD_DIR=build/distributions
FUNCTION_NAME="JavaLambda"
# lambda - filename: lambda.py, handler is the FUNCTION in the file
HANDLER="SteamLambdaHandler.handleRequest"
RUNTIME="java"
BUILD_ARTIFACT="$BUILD_DIR/product-service-0.0.1-SNAPSHOT.zip"

DYNAMODB_TABLE=nfjs-example

API_NAME=nfjs_api
AWS_DEFAULT_REGION=us-east-1
STAGE=dev

DEFAULT_UUID="b884f9b5-b7c9-4c3b-a87b-97f4cfdb3702"

show_help() {
cat << EOF
Usage: ${0##*/} [-hdv] [-i | s | l | t] [-c]
  Build AWS resources, mostly in LocalStack
      -h   display this help and exit
      -d   debug mode
      -v   verbose mode. Can be used multiple times for increased verbosity

      -i   print out the API Gateway endpoints
      -s   invoke the Lambda locally via SAM
      -l   create/update the lambda
      -t   test the GET endpoint

      -c   clean localstack
EOF
}

package_code() {
    echo -e "\n\tPackage code!"

    gradle clean build
}

create_lambda() {
    echo -e "\n\tCreate Lambda!"
    # check if Lambda exists
    EXISTS=$($LCMD list-functions \
        --query "Functions[?FunctionName==\`${FUNCTION_NAME}\`]" \
        --output text)

    if [ -z "$EXISTS" ]; then
        $LCMD create-function \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://$BUILD_ARTIFACT \
        --runtime $RUNTIME \
        --role arn:aws:iam::123456:role/role-name \
        --handler $HANDLER
    else
        $LCMD update-function-code \
        --function-name ${FUNCTION_NAME} \
        --zip-file fileb://${BUILD_ARTIFACT}
    fi

}

create_dynamodb_item() {
    item=$(
        jq -n \
            --arg uuid "$DEFAULT_UUID" \
            '{
        "uuid": {S: $uuid},
        "name": {"S": "Maki"},
        "cloud": {"S": "AWS"},
        "programmingLanguage": {"S": "Java"},
        "programmingLanguage2": {"S": "Python"}
        }'
    )
    echo $item > item.json

    $DCMD put-item \
        --table-name ${DYNAMODB_TABLE} \
        --item file://item.json
}

create_dynamodb() {
    echo -e "\n\tCreate DynamoDB table and data!"
    $DCMD create-table \
        --table-name ${DYNAMODB_TABLE} \
        --attribute-definitions \
        AttributeName=uuid,AttributeType=S \
        --key-schema AttributeName=uuid,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

    create_dynamodb_item
}

get_lambda_arn() {
    $LCMD list-functions \
        --query "Functions[?FunctionName==\`${FUNCTION_NAME}\`].FunctionArn" \
        --output text
}

print_endpoints() {
    API_ID=$(${ACMD} get-rest-apis | jq -r '.items[0].id')
    ENDPOINT="http://localhost:4567/restapis/${API_ID}/${STAGE}/_user_request_/employees"
    echo "API available at:"
    echo "GET ${ENDPOINT}/:uuid"
    echo "POST ${ENDPOINT}"
}

test_lambda() {
    set -x
    curl -Lik http://127.0.0.1:5000/employees/$DEFAULT_UUID
    set +x
}

print_sam() {
    EVENT_FILE="event.json"
    OUT_FILE="output.json"

    echo "generate the same EVENT an API Gateway would so you can local invoke the lambda, see $EVENT_FILE"

    set -x
    sam local generate-event apigateway aws-proxy --path employees/$DEFAULT_UUID --method GET > $EVENT_FILE

    $LCMD invoke --function-name $(get_lambda_arn) --payload file://$EVENT_FILE $OUT_FILE
    set +x
}

clean_localstack() {
    echo "stopping docker-compose"
    docker-compose down

    echo "cleaning up .localstack"
    rm -fr ./localstack/*

    echo "all done!"
}

create_apigateway() {
    echo -e "\n\tAPI Gateway"
    API_ID=$(${ACMD} create-rest-api \
        --name ${API_NAME} | jq -r '.id')

    PARENT_ID=$(${ACMD} get-resources \
        --rest-api-id ${API_ID} | jq -r '.items[0].id')

    RESOURCE_ID=$(${ACMD} create-resource \
        --rest-api-id ${API_ID} \
        --parent-id ${PARENT_ID} \
        --path-part "employees" | jq -r '.id')

    $ACMD put-method \
        --rest-api-id ${API_ID} \
        --resource-id ${RESOURCE_ID} \
        --http-method POST \
        --authorization-type "NONE"

    $ACMD put-integration \
        --rest-api-id ${API_ID} \
        --resource-id ${RESOURCE_ID} \
        --http-method POST \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${AWS_DEFAULT_REGION}:lambda:path/2015-03-31/functions/$(get_lambda_arn)/invocations" \
        --passthrough-behavior WHEN_NO_MATCH

    RESOURCE_ID=$($ACMD create-resource \
        --rest-api-id ${API_ID} \
        --parent-id ${PARENT_ID} \
        --path-part "employees/{uuid}" | jq -r '.id')

    $ACMD put-method \
        --rest-api-id ${API_ID} \
        --resource-id ${RESOURCE_ID} \
        --http-method GET \
        --request-parameters "method.request.path.token=true" \
        --authorization-type "NONE"

    $ACMD put-integration \
        --rest-api-id ${API_ID} \
        --resource-id ${RESOURCE_ID} \
        --http-method GET \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${AWS_DEFAULT_REGION}:lambda:path/2015-03-31/functions/$(get_lambda_arn)/invocations" \
        --passthrough-behavior WHEN_NO_MATCH

    $ACMD create-deployment \
        --rest-api-id ${API_ID} \
        --stage-name ${STAGE}

    print_endpoints
}

debug=
verbose=
info=
sam=
lambda=
test=
clean=

while getopts "hdvisltc" opt; do
  case "$opt" in
       h)  show_help; exit 0;;
       d)  debug=1;;
       i)  info=1;;
       s)  sam=1;;
       l)  lambda=1;;
       t)  test=1;;
       c)  clean=1;;
       v)  verbose=$((verbose+1));;
       \?) show_help >&2; exit 1;;
   esac
done

[[ $debug -eq 1 ]] && set -x

[[ $clean -eq 1 ]] && clean_localstack && exit 0

[[ $info -eq 1 ]] && print_endpoints && exit 0

[[ $lambda -eq 1 ]] && create_lambda && exit 0

[[ $sam -eq 1 ]] && print_sam && exit 0

[[ $test -eq 1 ]] && test_lambda && exit 0

package_code
create_lambda
create_dynamodb
create_apigateway
