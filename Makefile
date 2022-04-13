FORMAT_CMD := docker run --rm -v $(PWD):/app -w /app -it aws_cfn_templates_formatter

.PHONY: help
help: ## ドキュメントのヘルプを表示する。
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: deploy
deploy: ## デプロイする。
	# IAM周りを変更する場合は --capabilities CAPABILITY_NAMED_IAM オプションが必須
	aws cloudformation deploy --stack-name iam --template-file ./src/iam.yml --capabilities CAPABILITY_NAMED_IAM
	aws cloudformation deploy --stack-name s3 --template-file ./src/s3.yml
	aws s3 cp src/ec2.yml s3://cfn.jiro4989.com/
	make -C src/module/delete_tmp_resource ENV=ops NAME=delete-tmp-resource
	make deploy-env ENV=dev

.PHONY: deploy-env
deploy-env: ## 環境指定でデプロイする。ENV変数が必須パラメータ。内部用。
	aws cloudformation deploy --stack-name $(ENV)-network --template-file ./src/network.yml --parameter-overrides EnvironmentName=$(ENV) ProjectName=work
	aws cloudformation deploy --stack-name $(ENV)-securitygroup --template-file ./src/securitygroup.yml --parameter-overrides EnvironmentName=$(ENV) ProjectName=work

.PHONY: deploy-ec2-env
deploy-ec2-env: ## EC2を作る
	aws cloudformation deploy --stack-name $(ENV)-ec2 --template-file ./src/ec2.yml --parameter-overrides EnvironmentName=$(ENV) ProjectName=work --capabilities CAPABILITY_NAMED_IAM

.PHONY: format
format: ## フォーマット済みか検証する
	for f in src/*.yml; do \
		$(FORMAT_CMD) -v $$f; \
	done

.PHONY: format-save
format-save: ## フォーマットして上書きする
	for f in src/*.yml; do \
		$(FORMAT_CMD) -w $$f; \
	done

.PHONY: setup-tool
setup-tool: setup-tool-formatter setup-tool-linter ## ツールイメージを生成する

.PHONY: setup-tool-formatter
setup-tool-formatter: ## フォーマッタをインストールする
	cd tool/formatter && docker build -t aws_cfn_templates_formatter .

.PHONY: setup-tool-linter
setup-tool-linter: ## Linterをインストールする
	cd tool/linter && docker build -t aws_cfn_templates_linter .
