.PHONY: deploy
deploy:
	make -C ../logstream
	zip $(NAME).zip lambda_function.py
	aws s3 cp $(NAME).zip s3://lambda.jiro4989.com/$(ENV)/
	aws cloudformation deploy \
	--stack-name $(ENV)-$(NAME)-main \
	--template-file template.yml \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides Env=$(ENV) Name=$(NAME)
