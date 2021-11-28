FROM golang:1.17.3-alpine3.14

RUN go install github.com/awslabs/aws-cloudformation-template-formatter/cmd/cfn-format@v1.1.2-1

ENTRYPOINT ["cfn-format"]
CMD ["-h"]
