# aws-lambda-r-runtime

## Description
This package makes it easy to run AWS Lambda Functions written in R.

The build source is completely rewritten to be executed in Docker, with 1 single command.
Besides building the standard R, it also installs required packages.

## usage
_Modify the docker-compose.yml to your liking before starting the build!_

Make sure your AWS credentials are set as environment variables, or create an .env file with the following content:
```bash
AWS_ACCESS_KEY_ID={the access key of your aws account}
AWS_SECRET_ACCESS_KEY={the secret of your aws account}
AWS_DEFAULT_REGION={your default region}
```

Now run the build:
```bash
docker build . -t aws-lambda-r-runtime
docker-compose up
```
