.PHONY: deploy
deploy:
	aws cloudformation deploy \
	--stack-name $(ENV)-$(NAME)-logstream \
	--template-file template.yml \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides Env=$(ENV) Name=$(NAME)