.PHONY: help
help: ## ドキュメントのヘルプを表示する。
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: test
test:
	./script/test.sh

.PHONY: lint
lint:
	cfn-lint

.PHONY: deploy
deploy: test ## デプロイする。
	# IAM周りを変更する場合は --capabilities CAPABILITY_NAMED_IAM オプションが必須
	aws cloudformation deploy --stack-name iam --template-file ./template/iam.yml --capabilities CAPABILITY_NAMED_IAM
	aws cloudformation deploy --stack-name s3 --template-file ./template/s3.yml
	aws s3 cp template/ec2.yml s3://cfn.jiro4989.com/
	make -C template/module/delete_tmp_resource ENV=ops NAME=delete-tmp-resource
	make deploy-env ENV=dev

.PHONY: deploy-env
deploy-env: ## 環境指定でデプロイする。ENV変数が必須パラメータ。内部用。
	aws cloudformation deploy --stack-name $(ENV)-network --template-file ./template/network.yml --parameter-overrides EnvironmentName=$(ENV) ProjectName=work
	aws cloudformation deploy --stack-name $(ENV)-securitygroup --template-file ./template/securitygroup.yml --parameter-overrides EnvironmentName=$(ENV) ProjectName=work

.PHONY: deploy-ec2-env
deploy-ec2-env: ## EC2を作る
	aws cloudformation deploy --stack-name $(ENV)-ec2 --template-file ./template/ec2.yml --parameter-overrides EnvironmentName=$(ENV) ProjectName=work --capabilities CAPABILITY_NAMED_IAM

.PHONY: setup
setup:
	pip3 install -r requirements.txt
