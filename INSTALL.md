# Where these go

Unzip over ~/projects/sandbox. Paths match the repo:

- infra/*.tf, infra/index_rewrite.js  -> replace your infra files (terraform.tfvars is NOT included; keep yours)
- apps/ulid/api/build.sh              -> new
- scripts/deploy-web.sh               -> new

Add to .gitignore:

    apps/ulid/api/build/
    infra/.build/

# Order (one line each)

    chmod +x apps/ulid/api/build.sh scripts/deploy-web.sh
    apps/ulid/api/build.sh
    cd infra
    terraform init
    terraform plan
    terraform apply -target=aws_apigatewayv2_stage.default -target=aws_lambda_permission.api_gateway
    curl "$(terraform output -raw api_endpoint)/api/ulid?count=3"

After AWS verifies the account for CloudFront:

    terraform apply
    cd ..
    scripts/deploy-web.sh

Then open https://sandbox.descentintoart.com/ulid/
