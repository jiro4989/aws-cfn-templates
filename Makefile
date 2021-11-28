.PHONY: help
help: ## ドキュメントのヘルプを表示する。
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: deploy
deploy: ## デプロイする。
	# IAM周りを変更する場合は --capabilities CAPABILITY_NAMED_IAM オプションが必須
	aws cloudformation deploy --stack-name iam-group --template-file ./src/iam_group.yml --capabilities CAPABILITY_NAMED_IAM
	make deploy-env ENV=dev
	#make deploy-env ENV=prd

.PHONY: deploy-env
deploy-env: ## 環境指定でデプロイする。ENV変数が必須パラメータ。内部用。
	aws cloudformation deploy --stack-name $(ENV)-network --template-file ./src/network.yml --parameter-overrides EnvironmentName=$(ENV) ProjectName=work

.PHONY: setup-tool
setup-tool: setup-tool-formatter setup-tool-linter ## ツールイメージを生成する

.PHONY: setup-tool-formatter
setup-tool-formatter: ## フォーマッタをインストールする
	cd tool/formatter && docker build -t aws_cfn_templates_formatter .

.PHONY: setup-tool-linter
setup-tool-linter: ## Linterをインストールする
	cd tool/linter && docker build -t aws_cfn_templates_linter .
