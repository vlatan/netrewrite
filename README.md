# Netrewrite


## Install Picogen static website generator

```
python3 -m venv .venv &&
source .venv/bin/activate &&
pip install --upgrade pip &&
pip install picogen
```


## Generate the website

As per the [Picogen](https://pypi.org/project/picogen/) library use `picogen --generate` to generate a website into the `build` directory, using the default theme. Alternativelly run `python generate.py` to use one of its functions.


## Preview localy

```
python -m http.server --directory build --bind localhost
```

## Deploy to AWS Amplify

Move local build to bucket and start AWS Amplify deployment.

```
picogen --deploy <bucket-name> &&
aws amplify start-deployment \
--app-id <app-id> \
--branch-name <branch-name> \
--source-url s3://<bucket-name>/ \
--source-url-type BUCKET_PREFIX
```

Source: [Updating a static website deployed to Amplify from an S3 bucket](https://docs.aws.amazon.com/amplify/latest/userguide/update-website-deployed-from-s3.html).  
Note: Need to have AWS-CLI 2.18.7+ and a proper AWS policy so the user can perform these commands.