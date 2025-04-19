---
Title: Offload Your Static Content to Amazon S3
Date: 2017-11-06 10:20
Modified: 2017-11-06 10:20
Category: Backend
Image: images/offload-static-content-amazon-s3-720x250.jpg
Slug: offload-static-content-amazon-s3
---

![Offload Your Static Content to Amazon S3](images/offload-static-content-amazon-s3-720x250.jpg "Offload Your Static Content to Amazon S3")

The first question that comes to mind is: Why do I want to offload my static
content to Amazon S3 when I'm already serving my static content via content
delivery network (CDN)? Amazon S3 is not a CDN and by definition it'll have a
poorer performance because it'll serve the static content from one particular
region instead from the nearest point of presence (PoP) to the user.

That's true, but by offloading your static content to Amazon s3 you will not
ditch the CDN you're using. You will just point the CDN to pull your resources
from the Amazon s3 bucket instead of directly from your server. By doing that
you'll enable a layer between your CDN and your server that will literally cost
pennies.

Your site we'll be no longer mirrored to your CDN, there will be no more
requests from your CDN to your server, your static content we'll be arguable
more accessible because it's not sitting on a live server, but in a static
storage. Plus it's very fun to do this.


## In this tutorial:

1. [Prerequisites](#prerequisites)
2. [Create a sync script](#create-a-sync-script)
3. [Setup a cron job](#setup-a-cron-job)
4. [Update your CDN](#update-your-cdn)


## Prerequisites

First, you need to accomplish two very important tasks:

1. [Set up your AWS](/posts/backup-site-properly/#aws-setup), and
2. [Install and configure the AWS CLI on
your server](/posts/static-site-hugo-aws/#install-and-configure-aws-cli).


## Create a sync script

Now since you've created an **s3 bucket** and **IAM user** at **AWS**,
and installed and configured `AWS CLI` on your server,
create/open a shell script file:

``` bash
nano ~/.local/bin/s3-sync
```

Paste the following:

``` bash
#!/bin/sh

# find out the aws path with 'which aws' in your terminal
aws='/usr/local/bin/aws'

# your s3 bucket
bucket='s3://your-bucket'

# get into the website's root folder
cd /var/www/example.com/htdocs

echo "Syncing htdocs (static files) with $bucket..."

# sync images(jpg, jpeg, png, gif, svg), css and js to $bucket
$aws s3 sync . $bucket --exclude "*" --include "*.jpg" \
--include "*.jpeg" --include "*.png" --include "*.gif" \
--include "*.svg" --include "*.css" --include "*.js" \
--cache-control "public, max-age=31536000" \
--storage-class INTELLIGENT_TIERING \
--acl public-read --delete --quiet

# sync json, ico and xml to $bucket with less max-age
$aws s3 sync . $bucket --exclude "*" --include "*.json" \
--include "*.ico" --include ".xml" \
--cache-control "public, max-age=86400" \
--storage-class INTELLIGENT_TIERING \
--acl public-read --delete --quiet

now=$(date + "%D - %T")
echo "Static files synced. Current time: $now.\n"
```

Exit `CTRL + X`, save `y`.

`/usr/local/bin/aws` is the path to `aws`. Find out the path to `aws`
on your server with this command:

``` bash
which aws
```

`/var/www/example.com/htdocs` is your website's root directory.  
`--exclude "*"` - exclude everything.  
`--include ".jpg"` - include all files with `jpg` extension, for example.  
`--acl public-read` - set the files to be public.  
`--delete` - delete files in the bucket that do not exist at origin (your server).  
`--quiet` - do all this quietly without output.

Make the script executable only by you:

``` bash
chmod 700 ~/.local/bin/s3-sync
```

Test the script:

``` bash
s3-sync
```

Go over to your bucket at Amazon **s3** and see if your
website's static assets are copied there. If so, you're golden.


## Setup a cron job

The script above is very heavy. In a solidly populated website, with thousands
of files, it will take a long time to finish (around 40 - 50 seconds). And it
will spike the server's CPU usage if the server is somewhat underpowered.
So it doesn't make sense to run this script frequently but only when there
are changes in the website's static content. But how to detect these changes?

We can run a small python detection script on small intervals via cron and
only when there are changes in the static content of the website
we can launch the big script that communicates with **s3**.

``` bash
nano ~/.local/bin/detect-changes
```

Below is the content of the script. We will not go into it, there are comments
inside which explain what the script is trying to do. It basically creates
a dictionary of static files as keys and their last modified times as values
and compares that dictionary against the latest one stored in a `json` file.

If there are changes (new, deleted or modified static files) it
stores/overwrites the dictionary in the `json` file which later serves
as the latest directory snapshot to compare any new state to it.

``` python
#! /usr/bin/env python3

import os
import json


def compute_dir_index(path, extensions):
    """
    path: path to a website's root directory.
    extensions: allowed file extensions.
    Returns a dictionary with 'file: last modified time'.
    """

    index={}
    # traverse the website's dir
    for root, dirs, filenames in os.walk(path):
        # loop through the files in the current directory
        for f in filenames:
            # if a file ends with a desired extension
            if f.endswith(extensions):
                # get the file path relative to the website's dir
                file_path=os.path.relpath(os.path.join(root, f), path)
                # get the last modified time of that file
                mtime=os.path.getmtime(os.path.join(path, file_path))
                # put them in the index
                index[file_path]=mtime

    # return a dict of files as keys and
    # last modified time as their values
    return index


if __name__ == "__main__":
    # file extensions to track (basically all the static files)
    extensions = ('.jpg', '.jpeg', '.png', '.gif', '.svg',
                '.css', '.js', '.json', '.ico', '.xml')

    # path to the website's root directory
    path = '/var/www/example.com/htdocs/'

    # compute the new index
    new_index = compute_dir_index(path, extensions)

    # the old index json file
    json_file = '/var/www/example.com/index.json'

    # try to read the old json file
    try:
        with open(json_file, 'r') as f:
            old_index=json.load(f)
    # if there's no such file the old_index is an empty dict
    except IOError:
        old_index = {}

    # if there's a difference
    if new_index != old_index:
        # run the s3-sync script
        os.system('/home/user/.local/bin/s3-sync')
        # save/overwrite the json file with the new index
        with open(json_file, 'w') as f:
            json.dump(new_index, f, indent=4)
```

Now we need to create a cronjob.  
Open `crontab`:

``` bash
crontab -e
```

Paste this cronjob:

``` bash
# Run the script every 5 minutes
* /5 * * * * /home/user/.local/bin/detect-changes >> /tmp/offload.log
```

Exit `Ctrl + x`, save `y`.

As you can see we'll dump the logs to `/tmp/offload.log`.


## Update your CDN

Now, go to your CDN and configure it to pull from the following URL
instead of from your server, which is the endpoint of the bucket:

`https://s3-us-west-1.amazonaws.com/your-bucket-name`  
`s3-us-west-1` is the region of the bucket and you need to
[identify yours](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region).

However, if you use **CloudFront** as your CDN you don't need to
declare the objects in the bucket public, meaning you can omit `--acl public-read`
above in the syncing script and you also don't need the endpoint URL.

Instead you can
[allow ONLY your
designated CloudFront distribution to access that bucket](https://aws.amazon.com/premiumsupport/knowledge-center/cloudfront-access-to-amazon-s3/)
by choosing the bucket as the CloudFront distribution's origin,
restrict bucket access from there and grant to the distribution
read permissions on the bucket which will automatically write a bucket policy
for this purpose if you choose so.

If you go over to your bucket now you'll see a policy that looks like this:

``` json
{
    "Sid": "1",
    "Effect": "Allow",
    "Principal": {
        "AWS": "arn:aws:iam::cloudfront:user/CloudFront \
                Origin Access Identity EAF5XXXXXXXXX"
        },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::AWSDOC-EXAMPLE-BUCKET/*"
}
```

The above method won't work with static websites hosted on an **s3** bucket.
In that case you'll still need to declare the endpoint ULR of the bucket over
to the CloudFront distribution and make the objects public either via
`--acl public-read` on every upload / command or by making the whole bucket
public.


## Wrap up

We're done. One downside that I can think of is the fact that when you
upload a static file to your website, it will be available at the **s3** bucket
5 minutes later(you can always make the intervals smaller).
So you'll need to wait for a few minutes before hitting ‘publish post'
so all your newest static assets become available at the CDN.
