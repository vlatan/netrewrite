---
Title: Static Site on AWS
Date: 2017-10-23 10:20
Modified: 2024-07-07 10:20
Category: Backend
Image: images/static-site-aws-720x250.jpg
Slug: static-site-aws
---

![Static Site on AWS](images/static-site-aws-720x250.jpg "Static Site on AWS")

If your content doesn't change really dynamically, I mean
dramatically dynamically, you don't need a server, a web
server, database, a web scripting language, content
management system (CMS) and so on. What you need is a
static website. Let me be clear, a blog doesn't constitute
a dynamic website. Not anymore. You can run e serverless
blog now. Like the one you're looking at right now.

Now, of course you'll don't have a fancy platform where
you'll simply login, type your content in and hit publish.
You need to be a little bit more tech savvy since you'll
be writing in [markdown](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
and previewing your content locally before syncing it with
your live website. And that adds a little bit of fun while
playing with your blog.
 

## Table of Contents:

1. [Static Website Generator](#static-website-generator)
2. [Hosting (Amazon Web Services)](#hosting-aws)
	* [Create S3 Buckets](#create-s3-buckets)
	* [Create CloudFront Distributions](#create-cloudfront-distributions)
	* [Manage DNS with Amazon Route 53](#manage-dns-with-amazon-route-53)
	* [Get custom SSL Certificate](#get-custom-ssl-certificate)
3. [Deployment](#deployment)
	* [Create an IAM User](#create-an-iam-user)
	* [Install and Configure AWS CLI](#install-and-configure-aws-cli)
  * [Updating the Website](#updating-the-website)
4. [Cache-control](#cache-control)
	* [Versioning](#versioning)
	* [Cache Sparingly](#cache-sparingly)
	* [Manually Invalidate](#manually-invalidate)
5. [Add Dynamics](#add-dynamics)
6. [Setup Email](#setup-email)
7. [Wrap Up](#wrap-up)


## Static Website Generator

For a static website you need a website generator.
There are plenty to choose from, like [Pelican](https://getpelican.com/), 
[Hugo](https://gohugo.io/), [Jekyll](https://jekyllrb.com/),
[Hexo](https://hexo.io/), [Octopress](http://octopress.org/)
to name a few, but this website is made with a generator that I wrote myself
- [Picogen](https://github.com/vlatan/picogen/tree/main).
It's written in [Python](https://www.python.org/) and it's really simple.
 
Anyways, whichever static website generator you'll end up using you'll need to basically learn how to
operate it and generate content. The point is you need to end up with a locally hosted
website that you can manipulate in any way you want and eventually deploy to AWS.
 

## Hosting (AWS)

Since you don't need a classic server for a static website you
can literally host it on a contend delivery network (CDN).
There are [numerous solutions](https://gohugo.io/hosting-and-deployment/)
out there but I really do fancy
[Amazon Web Services (AWS)](https://aws.amazon.com/).
 
Once you sign up, AWS has an automated process (shortcut)
for creating a static website which will guide you and
automatically create an *S3 bucket* and a *CloudFront*
distribution but it won't handle `www` to `non-www`
redirection (or vice-versa if you prefer) nor will
automatically enable HTTPS access to your own custom
domain which requires a SSL certificate.

Here's an excellent documentation on
[how to setup a
static HTTP website](http://docs.aws.amazon.com/AmazonS3/latest/dev/hosting-websites-on-s3-examples.html)
including the usage of a custom domain name. Amazon even
has a whitepaper on [building static
websites](https://d0.awsstatic.com/whitepapers/Building%20Static%20Websites%20on%20AWS.pdf)
(44 pages PDF). After you acquaint yourself with these
docs you'll realize it all boils down to:
 

### Create S3 Buckets

[Create two *S3 buckets*](http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html)
(`example.com` and `www.example.com`). The first one will host
your files (make sure you choose **"use this bucket to host a website"**
in the bucket's properties), the second one will redirect
to the first one (make sure you choose **"redirect requests"** for this one).
This way we handle `www` to `non-www` redirection.

The files in the first bucket, the one that'll host the files, need
to be publicly accessible in order *CloudFront* or anyone to be able to fetch
them from there. Therefore you need to unblock all public access in the bucket settings
and define the following bucket policy in the bucket's permissions:
 
``` json
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "AllowPublicRead",
              "Effect": "Allow",
              "Principal": "*",
              "Action": [
                  "s3:GetObject"
              ],
              "Resource": [
                  "arn:aws:s3:::example.com/*"
              ]
          }
      ]
}
```


### Create CloudFront Distributions

[Create
two *CloudFront* distributions](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html)
for each of the buckets. Those distributions' origins will
be the buckets' hosting endpoints. Basically a
*CloudFront* distribution will point to a bucket's endpoint URL.
You can see a bucket's endpoint URL by checking out the
bucket's properties. It'll look something like this:
`http://example.com.s3-website-us-east-1.amazonaws.com`
depending on the name of your bucket (in this case `example.com`)
and the region of the bucket (in this case `us-east-1`).
Basically, this URL needs to be an origin for a *CloudFront distribution*,
respectively. Finally, you'll end up having two URLs at CloudFront
similar to this: `xxx.cloudfront.net`.

There are several key settings for these distributions that you
don't wanna forget to do. Make sure they redirect HTTP to HTTPS
and they compress objects automatically (in the **"Behaviour"** settings),
and set up *Alternate Domain Names (CNAMEs)* for each using your
custom domain `example.com` and `www.example.com`
respectively (in the **"General"** settings).


### Manage DNS with Amazon Route 53

First you need to [create a public
hosted zone](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html)
for `example.com` at [Amazon Route 53](https://aws.amazon.com/route53/)
which is Amazon's DNS web service. Then you need to go to your
domain name registrar, i.e. GoDaddy, Namechap, etc.
(unless your domain registrar is [Amazon](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar.html) itself),
and there point your domain to the nameservers at the newly created
public hosted zone. There are usually four nameservers and they look like this:

``` bash
ns-xxx.awsdns-xx.org.
ns-xxxx.awsdns-xx.co.uk.
ns-xxx.awsdns-xx.net.
ns-xxx.awsdns-xx.com.
```

Then, at the hosted zone you'll create ALIAS for your custom domain
`example.com` and point that to [your CloudFront
distribution](#create-cloudfront-distributions) (`xxx.cloudfront.net`)
whose origin is the bucket we've named exactly like your
domain (`example.com`). That's the bucket where you files
will reside. You'll also create another ALIAS, but this
time for the `www` version of your custom domain
`www.exaxmple.com` and point that to the other
*CloudFront distribution* whose origin is the other
bucket named `www.example.com`.
 

### Get custom SSL Certificate

In order your website (your custom domain) to be able to be
accessible via HTTPS you need to get [CloudFront
Custom SSL certificate](https://aws.amazon.com/cloudfront/custom-ssl-domains/) for your custom
domain which is relatively short process (you need to verify that you own
the domain over email) and more importantly it's FREE.
Worth to mention it's a *SNI* certificate which is [widely
supported](https://caniuse.com/#feat=sni).

In the *Cloudfront distribution's* **"General"** settings there's an
option to get custom SSL Certificate. Click that option and Amazon
will guide you through the process. Make sure the certificate covers
both `example.com` and `www.example.com`.


## Deployment

At this phase you need to somehow transfer your files from your
local computer over to the cloud, and make sure the process
isn't tedious, and desirably accomplished with one simple
command every time you need to update your website.


### Create an IAM User

First, you'll need to [create
an IAM user](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console),
locally with "programmatic access" to [your S3 bucket](#create-s3-buckets)
where the website's files are located. Take note of its
`Access Key ID` and `Secret Access Key`.
 
Then [create
a new access policy](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_change-permissions.html#by-direct-attach-policy)
for that user and paste the code below. Make sure you use
the name of your hosting bucket in this policy under
`"Resource":`, in our case `example.com`

``` json
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:DeleteObject",
          "s3:Put*",
          "s3:Get*",
          "s3:List*"
        ],
        "Resource": [
          "arn:aws:s3:::example.com",
          "arn:aws:s3:::example.com/*"
        ]
      }
    ]
}
```

What we're doing here is practically giving programmatic access
to your S3 bucket to a very limited IAM user (he can only get, put,
delete and list objects in a specific S3 bucket via the command line
using `AWS CLI`).


### Install and Configure AWS CLI

You need `AWS CLI` on your computer to be able
to communicate with the bucket by using the IAM user you already created.

The installation process is different for different operating systems.
Check out the AWS docs if you have problems installing `AWS CLI` [on Linux](http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html) or
[on Windows](http://docs.aws.amazon.com/cli/latest/userguide/awscli-install-windows.html).
Here's the install command on Linux, assuming you have `pip` installed:

``` bash
pip install awscli --upgrade --user
```

Please read on [how
to configure the AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration).
In this process you're going to need the IAM user's `Access Key ID`,
`Secret Access Key`, and the region of your hosting bucket
(in this case `us-east-1`) and use them in a simple configuration command:
 
``` bash
aws configure
```

You will get the following requests to populate, one by one.
You can leave the last one blank.

``` bash
AWS Access Key ID [None]: <Access Key ID>
AWS Secret Access Key [None]: <Secret Access Key>
Default region name [None]: us-east-1
Default output format [None]:
```

Basically, this will create two files (`config` and `credentials`)
in the `~/.aws` folder. Make sure those files are protected:

``` bash
sudo chmod 600 ~/.aws/config
sudo chmod 600 ~/.aws/credentials
```


### Updating the Website

Now that you've mastered your static website generator of choice updating the website is easy. 
First enter into your website's directory:

``` bash
cd /path/to/your/website/example.com
```

Sync the local folder where your website is built (i.e. `/path/to/public`) with your hosting S3 bucket:

``` bash
#!/bin/sh
  
# get into the public directory
cd /path/to/public

# sync images(jpg, jpeg, png, gif, svg), css and js 
# to s3://example.com with big max-age
aws s3 sync . s3://example.com --exclude "*" \
--include "*.jpg" --include "*.jpeg" --include "*.png" \
--include "*.gif" --include "*.svg" --include "*.webp" \
--include "*.css" --include "*.js" \
--cache-control "public, max-age=31536000" \
--storage-class INTELLIGENT_TIERING --delete

# sync json, ico, xml, xsl files
# to s3://example.com with small max-age
aws s3 sync . s3://example.com --exclude "*" \
--include "*.json" --include "*.ico" --include ".xml" \
--include ".xsl" --cache-control "public, max-age=86400" \
--storage-class INTELLIGENT_TIERING --delete

# sync the rest of the files with no max-age cache
aws s3 sync . s3://example.com --storage-class INTELLIGENT_TIERING --delete
```

We chose the storage class to be `INTELLIGENT_TIERING` which
is a storage where AWS decides whether to classify the object as
frequently (STANDARD) or infrequently (STANDARD\_IA) accessed
therefore trying to lower the storage price.

We also have put different cache-control for different files.
Static files with huge max-age, some files with less max-age and the rest
with no max-age at all.

For convenience you can put these commands in a bash script in
`/home/<user>/.local/bin` and name it for example `n-sync`. Don't forget
to run`source .bashcr` or just restart the terminal in order to make
the script available.

So when you're ready to push the changes to the bucket, in other words
to make the changes live, you can do it with one command:

``` bash
cd example.com && n-sync
```

You will use this command every time you want to update your live
website, and push the changes you made locally. So the process
goes like this: You make changes locally (you create a new post, make design
changes, etc.) and then when satisfied you're basically pushing the newest
version online.


## Cache-control

You can set the cache at a bucket level (as shown in the example above)
and/or at the *CloudFront* distribution level (**"Behavior"** Settings).
You can either set *CloudFront* to respect the origin's `cache-control`
headers if any, meaning to keep the files at the edge as per the origin's
headers value, or set up your own time/duration for keeping the files
at the edge while ignoring the bucket cache values. In the second
scenario the `cache-control` headers at the origin are still used
for stating the browser's cache duration.

Here you have a [very
specific table](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html#ExpirationDownloadDist)
explaining what happens when you set or don't set `cache-control`
headers at origin in respect to Minimum TTL, Maximum TTL and Default
TTL values at *CloudFront* distribution (**"Behavior"** Settings).
It is fairly well explained in which situations which value
takes precedence.

When it comes to cache-control there are three strategies:


### Versioning

This method can be only applied for a static, external files
such as CSS, JS, etc. For example, when you make a change to
your CSS file(s), thus you change the design of your website,
you just append a version string to the end of the CSS URL
in your document, like this:

``` html
<link rel="stylesheet" href="https://example.com/css/style.css?v=11262017">
```

By doing this you're pointing to a new version of the CSS file
and *CloudFront* will pick up this new version (if the distribution
is set up to respect queries), and so the visitors of your website.
The old version is irrelevant.

However, since your site is a static site and it basically resides
on a content delivery network (CloudFront) as a whole, including the HTML,
I vote for inlining all of your external files (CSS, synchronous JS, etc.)
that block the critical rendering path. Your HTML pages will be cached and
stored on the CDN anyway and it's somewhat illogical to cache those files
separately. If you were running an ordinary server you would want ONLY your
external static files to be cached at a CDN, and even then you might want
to use [rel="preload"](/posts/preload-observe-intersect/#preload).


### Cache Sparingly

If you make frequent changes or pump up a lot of content to your site you
don't want to keep your files at *CloudFront* (the edge) for too long in order
the changes to fairly quickly reflect. By setting low TTL at edge *CloudFront*
will frequently check for fresh content at the bucket and invalidate the cache.


### Manually Invalidate

However, if you update the website once in a while you want to store your files
at the edge for a while since they're not changing that frequently or ever at
all. In that case when you update the website you'll have to invalidate
the *CloudFront* cache manually either for the whole site or for a specific
page, as needed.

If you want to invalidate the *CloudFront* cache from the command line you can
add the following chunk to the [IAM's policy we've created earlier](#create-an-iam-user):

``` json
{
    "Effect": "Allow",
    "Action": [
      "cloudfront:GetInvalidation",
      "cloudfront:CreateInvalidation"
    ],
    "Resource": "*"
  }
```

See, we didn't specify a concrete resource for the *CloudFront* cache
invalidation permission because there's nothing to specify since in the
cache invalidation command you have to explicitly specify the distribution
ID every single time. Every *CloudFront* distribution has a unique ID,
available at the *CloudFront* dashboard.

For example, after publishing a new post I would invalidate the cache just
for the homepage, the category list page, the sitemap and the RSS page where
this title/link presumably makes an appearance. If I change something in a
single post or a category page, I would obviously invalidate just that URL's
cache.

Here's the command for invalidating the whole website's cache,
given the fact that we've already equipped the IAM user to do this:

``` bash
aws cloudfront create-invalidation \
  --distribution-id <cloudfront-distribution-id-here> --paths "/*"
```

You can put this command in a bash script too in `/home/<user>/.local/bin`
and name it for example `n-invalidate`. Call it every time when you're making
a massive change across the website and you want that change to
reflect to the live version instantly.


Manual [cache
invalidation costs money](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html#PayingForInvalidation),
but frequent file requests at bucket level cost too which will happen
often with the first scenario. So it's a trade off. You need to decide
which option suits you the best. Manually invalidate the cache once in
a while or leave the bucket relatively open for frequent uncached hits.
Anyhow, both cases cost pennies, unless your site is humongous and has
tons of traffic. Even then compared to hosting a dynamic website on a
classic server it's way cheaper.


## Add Dynamics

If you're not happy with having a truly static website you can easily
add dynamic elements to it. For example if you want comments on your
blog-posts you can always plug-in a third-party commenting system
(e.g. [Disqus](https://disqus.com/)). If you wish to add a contact
form there are third-party solutions for that too
(e.g. [Formspree](https://formspree.io/)).

If you want to manipulate or add HTTP headers you can do that right at *CloudFront* by using a header policy. You can even change your content right before hitting the client's browser by using [CloudFront Functions](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-functions.html) or [Lambda Functions](https://aws.amazon.com/lambda/).


## Setup Email

Every website needs a domain email address (e.g. `contact@example.com`).
Now, since you can't [setup a traditional secure mail server](/posts/setup-secure-mail-server/) (you
don't have a server at all) you
can just [get a
SendGrid account and white-label your domain](/posts/setup-secure-mail-server/#get-a-sendgrid-account-and-whitelabel-your-domain)
and then you can use for example just the Gmail interface for
sending/receiving emails by adding the email above into your
Gmail account, treating it as an alias and using *SendGrid*
as an SMTP server (`smtp.sendgrid.net`) where you'll enter
`apikey` literally as a username and your actual *SendGrid*
API key as a password, while using port 587, over secured
connection using TLS.
 

## Wrap Up

Don't let this monstrous, 2000-words-article (plus additional resources)
intimidate you. It's a relatively easy process to set up your static site
and get it up and running in the cloud. If I could do it anyone can do it.

While making this website I was following this tutorial to the letter.
Not to brag, but it's blazingly fast and virtually unhackable.
There's nothing to hack really.
