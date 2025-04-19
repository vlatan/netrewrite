---
Title: Migrate from HTTP to HTTPS
Date: 2017-12-06 10:20
Modified: 2017-12-06 10:20
Category: Backend
Image: images/backup-site-properly-720x250.jpg
Slug: migrate-http-https
---

![Migrate from HTTP to HTTPS](images/migrate-http-https-720x250.jpg "Migrate from HTTP to HTTPS")

I was reluctant to switch to HTTPS for a long time until [Google announced](https://security.googleblog.com/2017/04/next-steps-toward-more-connection.html)
that *Chrome* will mark HTTP pages as "Not secure" if there are means for users to enter data. This is a
deal-breaker because on a given (e.g. WordPress) blog you have a comment form, contact form, and possibly a
newsletter form where users enter data.

When Chrome users land on an HTTP page with a form of any kind they will be greeted with a "Not Secure" warning.
Eventually Google will mark all HTTP websites as "Not Secure" in Chrome, and further more all browsers will do
the same making HTTP websites obsolete. In near future all websites will be HTTPS, thus making this article
obsolete too.

So therefore, if you still operate a HTTP website it's about time to switch to HTTPS. In order to do that you
need a solid plan. The more complex the website the more solid the plan. Below are some aspects you need to look
at before, during and after the switch.


## On this page:

1. [Externals](#externals)
    * [Ads](#ads)
    * [Content delivery network](#content-delivery-network)
    * [Other external resources](#other-external-resources)
2. [Firewall](#firewall)
3. [Web server](#web-server)
    * [Generate a private key](#generate-a-private-key)
    * [Generate a Certificate Signing Request (CSR)](#generate-a-certificate-signing-request-csr)
    * [Get the certificate(s)](#get-the-certificate-s)
    * [Install the certificate(s)](#install-the-certificate-s)
    * [Configure Nginx](#configure-nginx)
    * [Optimize Nginx for HTTPS](#optimize-nginx-for-https)
    * [Insert strict transport security header (HSTS)](#insert-strict-transport-security-header-hsts)
4. [Enable HTTPS at proxy](#enable-https-at-proxy)
5. [Redirect from HTTP to HTTPS](#redirect-from-http-to-https)
    * [Avoid infinite loop error](#avoid-infinite-loop-error)
6. [Replace HTTP with HTTPS](#replace-http-with-https)
    * [Update the links in the template files](#update-the-links-in-the-template-files)
    * [Update the links in the database](#update-the-links-in-the-database)
7. ["Talk" to Google](#talk-to-google)
    * [Add new property in Google Search Console](#add-new-property-in-google-search-console)
    * [Submit new sitemap to Google](#submit-new-sitemap-to-google)
    * [Update the Google Analytics profile](#update-the-google-analytics-profile)
    * [Re-associate Google Analytics with Google Search](#re-associate-google-analytics-with-google-search)
8. [Update the external services](#update-the-external-services)
9. [Extras](#extras)
10. [Crawl and fix](#crawl-and-fix)


## Externals

Since all resources on a given HTTPS page need to be loaded via HTTPS you need to make sure this rule is strictly
enforced. All resources on a given page need to be HTTPS compatible. So, you need to comb your site and
determine which external resources it uses, and switch them to HTTPS protocol.


### Ads

[AdSense](https://www.google.com/adsense/start/) ads for sure are HTTPS compatible, as many other
networks' ads are too, but make sure you request HTTPS compatible code from your ad network if you happen to run
something other than AdSense.

If you use AdSense, when you setup an ad unit you have an option to decide what happens when no ads are
available. This is particularly important if you use [Ad Balance](https://support.google.com/adsense/answer/7215246?hl=en). If you choose to redirect the
unsold inventory to some other networks or to an in-house ads make sure the redirect URL supports HTTPS.


### Content delivery network

If you use a content delivery network (CDN) to deliver your static files to your visitors they need to be
delivered via HTTPS too. If you use [CloudFront](https://aws.amazon.com/cloudfront/) you get a SSL
certificate for free, and if you use some other CDN you need to buy a SSL certificate for the subdomain (or
domain) that you're going to use as CDN.

You can go with buying a wildcard certificate `*example.com` which will cover all possible subdomains
on a given domain but that's somewhat expensive for a regular Joe. Instead, if you do not plan using subdomains,
buy two separate certificates for the domain `example.com` (this always includes the `www`
variant), and for the specific subdomain `cdn.example.com` which you'll be going to use as a CDN.


### Other external resources

For example, if your site is running [jQuery](https://jquery.com/), [Google Fonts](https://fonts.google.com/), or some custom scripts, iframes or any other resources
loaded from elsewhere you need to make sure they use HTTPS protocol.


## Firewall

If HTTPS access to your website is blocked by the server's firewall (port 443 is not open) you need to [add an iptable rule](https://www.linode.com/docs/security/firewalls/control-network-traffic-with-iptables/) (ipv4 and/or ipv6) to allow HTTPS requests, or make sure there's one in the first place. Simply,
make sure your server accepts HTTPS requests at firewall level.

List iptables' rules with line numbers.

``` bash
sudo iptables -L -nv --line-numbers
```

Check to see whether this rule exists:

``` bash
ACCEPT  tcp --  any any anywhere  anywhere  tcp dpt:https state NEW
```

If you don't see a HTTPS access rule you'll have to insert it. The number `8` below is the line number
where you want the rule to be inserted. It could be a different line number in your case.

``` bash
sudo iptables -I INPUT 8 -p tcp --dport 443 \
-m state --state NEW -j ACCEPT
```

Anyhow, the HTTPS rule should be inserted right after the HTTP rule. You can't append it at the end of the
ruleset because all traffic not encompassed by the rules need to be dropped by a final rule at the end of the
firewall ruleset.

Of course this rule, along with all firewall rules, needs to be preserved on server reboot. Install
`iptables-persistent` if you already haven't. During the installation you'll be prompted to save the
current firewall rules.

``` bash
sudo apt-get install iptables-persistent
```

To enforce the iptables' rules after a change (like when inserting, deleting or replacing a rule or when
completely changing the whole ruleset) run:

``` bash
dpkg-reconfigure iptables-persistent
```

When you're done, list the iptabels again to see if everything's OK.


## Web server

In order to accept HTTPS requests you need to configure your web server whether that be Nginx, Apache, LiteSpeed,
etc. For example here's what you need to do to enable HTTPS on Nginx:


### Generate a private key

HTTPS works on a basis of pair of keys in way. One secret key and one public provided by a Certificate Authority,
which is the SSL certificate itself. First you need to generate the private key on your server.

``` bash
sudo openssl genrsa -out /etc/ssl/private/example.com.key 2048
```

### Generate a Certificate Signing Request (CSR)

Since the key above is PRIVATE, meaning it's secret and you shouldn't reveal it to anyone, you need to generate a
"code" which is extrapolated from that key and it's called Certificate Signing Request (CSR). This "code" will
be needed in the process of acquiring the SSL certificate.

``` bash
sudo openssl req -new -key /etc/ssl/private/example.com.key \
-out /etc/ssl/private/example.com.csr
```

You will be asked to provide the following information:

`Country` - two-letter ISO [country code](http://www.worldatlas.com/aatlas/ctycodes.htm).  
`State or Province` - your state/province (do not abbreviate).  
`City or Locality` - your city (do not abbreviate).  
`Organization` - either your website's name or `NA` if you don't run a company.  
`Organization Unit` - you can skip this, enter `NA`.  
`Common Name` - your domain name (`example.com`).  
`Email Address` - your email address.

You will be also asked to enter some extra information (`A Challenge Password`, and
`An Optional Company Name`) but you can enter a dot `'.'` to leave these options blank.

Once you're done copy the CSR code contained in the file you've just created
`/etc/ssl/private/example.com.csr`. You'll need to provide this code while buying/activating the
certificate from a Certificate Authority (CA).

Restrict access to the files we've created so far:

``` bash
sudo chmod 400 /etc/ssl/private/example.com.*
```

### Get the certificate(s)

Although you can acquire a free certificate from [Let's Encrypt](https://letsencrypt.org/) I would
recommend (if you're an individual) a [PositiveSSL](https://www.ssls.com/ssl-certificates/comodo-positivessl) certificate from [SSLs.com](https://www.ssls.com/) (a Namecheap company).

It's a straightforward process. You will be asked to provide the same info you've entered while you were
generating the CSR (Country, State or Province, etc.), plus the CSR "code". In addition you need to verify that
you own the domain, either by email, or via uploading a file to the root of the domain. Anyhow, I'm sure you can
handle the process just fine.

After you complete the process you will receive several files to download.

1. Certificate for your domain - `example.com.crt`
2. Two intermediate certificates: `COMODORSADomainValidationSecureServerCA.crt` and `COMODORSAAddTrustCA.crt`
3. Root certificate - `AddTrustExternalCARoot.crt`, and
4. p7b certificate - you can ignore this one, it's for Windows usage.

Sometimes, the intermediate certificates and the root certificate are bundled into one file so you'll get just:

1. Certificate for your domain - `example.com.crt`
2. Bundle - `example.com.ca-bundle`
3. p7b certificate - you can ignore this one.


### Install the certificate(s)

Whatever you've got you can upload/save all files into `/etc/ssl/certs` folder on your server.
Concatenate the needed certificates into one file. The ORDER of concatenation is **very
important**.

Get into that folder:

``` bash
sudo cd /etc/ssl/certs
```

In you have multiple intermediate certificates run:

``` bash
sudo cat example.com.crt \
COMODORSADomainValidationSecureServerCA.crt \
COMODORSAAddTrustCA.crt \
AddTrustExternalCARoot.crt >> example.com.chain.crt
```

If you have a bundle of certificates run:

``` bash
sudo cat example.com.crt example.com.ca-bundle >> \
example.com.chain.crt
```

### Configure Nginx

Once you've installed the certificates you need to instruct the web server to utilize HTTPS, meaning to provide
the location of the certificate files and the private key:

``` nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name example.com;

    ssl_certificate /etc/ssl/certs/example.com.chain.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;

    # Rest of the config:
    # […]
}
```

### Optimize Nginx for HTTPS

Before utilizing the full force of HTTPS you need to tweak Nginx a little bit.

Cache sessions:

``` nginx
ssl_session_cache shared:SSL:64m;
ssl_session_timeout 1d;
```

Lower buffer size:

``` nginx
ssl_buffer_size 8k;
```

Default is 16k. We lower this to minimize the time to first byte (TTFB) according to NGINX docs. You can even
make it 4k. Test what works best for you.

Use only TLS:

``` nginx
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
```

Use ciphers:

``` nginx
ssl_prefer_server_ciphers on;
ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DHE+AES128:!ADH:!AECDH:!MD5;
```

Generate DH parameters file:

``` bash
sudo openssl dhparam 2048 -out /etc/nginx/cert/example.com.dhparam.pem
```

Provide its location in the server config:

``` nginx
ssl_dhparam /etc/nginx/cert/example.com.dhparam.pem;
```

Enable OSCP stapling:

You again need to concatenate the certificates you've been given. First should go the intermediates, then the
root certificate. Here we don't use the domain certificate.

``` bash
sudo cd /etc/ssl/certs
```

``` bash
sudo cat COMODORSADomainValidationSecureServerCA.crt \
COMODORSAAddTrustCA.crt AddTrustExternalCARoot.crt \
>> example.com.stapling.crt
```

Or, if you've been given a bundle (intermediate certs and the root cert in one file) then just copy the bundle
and rename it:

``` bash
sudo cp example.com.ca-bundle example.com.stapling.crt
```

Then provide the location of the stapling cert chain in the config, along with the `resolver`
(Google's public DNS in this case):

``` nginx
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/nginx/cert/example.com.stapling.crt;
resolver 8.8.8.8 8.8.4.4;
```

### Insert strict transport security header (HSTS)

Be extremely careful with this header. First, set the max-age
relatively low, like in this example:

``` nginx
add_header Strict-Transport-Security "max-age=86400" always;
```

When you're 100% sure your website operates smoothly under HTTPS for a relatively long period of time you can
increase the max-age to minimum one year (31536000), add `preload` directive, include the subdomains
in the header and submit your domain in the [preload list](https://hstspreload.org/) and expect your
domain's protocol to be literally hard-coded into Chrome and other browsers which will make your website load
even faster. This is the point of no return. You can't go back
to HTTP at this point.

``` nginx
add_header Strict-Transport-Security \
"max-age=31536000; includeSubDomains; preload" always;
```

The `always` directive is there to ensure that the header will be applied for all responses, including
the internal errors. Note, you can place this header outside the Nginx server config block, namely in the parent
http block.

At this point you're done with configuring, tuning and optimizing HTTPS on Nginx and the server config should
look something like this:

``` nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name example.com;

    # Cert and key
    ssl_certificate /etc/ssl/certs/example.com.chain.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;

    # Session cache (1MB can store about 4000 sessions)
    ssl_session_cache shared:SSL:64m;

    # Cache the sessions above for one day
    ssl_session_timeout 1d;

    # We lower this to minimize the time to first byte (TTFB)
    # Default is 16k
    ssl_buffer_size 8k;

    # Ciphers
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DHE+AES128:!ADH:!AECDH:!MD5;

    # DH parameters
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    # SSL protocols
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

    # OSCP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/certs/example.com.stapling.crt;
    resolver 8.8.8.8 8.8.4.4;

    # HTTP Strict Transport Security (HSTS) Header
    add_header Strict-Transport-Security "max-age=86400" always;

    # Rest of the config:
    # […]
}
```

## Enable HTTPS at proxy

If your website sits behind a proxy it's logical that the proxy needs to accept HTTPS requests too. For example
if you use [CloudFlare](https://www.cloudflare.com/) you need to employ a universal SSL certificate
there, buy a dedicated one or import a custom certificate that you bought from somewhere else, [depending on
your plan](https://support.cloudflare.com/hc/en-us/articles/200170516-How-do-I-add-SSL-to-my-site-) at CloudFlare. Finally, switch to full (strict) SSL.


## Redirect from HTTP to HTTPS

First you need to make this happen at a proxy level, that is if you use a proxy. For example at CloudFlare they
do this automatically when you employ HTTPS, but you can additionally [add
a page rule](https://support.cloudflare.com/hc/en-us/articles/200170536-How-do-I-redirect-all-visitors-to-HTTPS-SSL-) to make sure all HTTP requests go to HTTPS.

Secondly, add a redirect at the web server level too, in this case Nginx. To accomplish this you'll need a
separate server config block placed above the main server config block that we've already created.

``` nginx
# Redirect HTTP to HTTPS
server {
        listen [::]:80;
        listen 80;

        # The host name to respond to
        server_name example.com www.example.com;

        # Redirect
        return 301 https://example.com$request_uri;
}
```

This will additionally take care of the `www` to `non-www` redirection.


### Avoid infinite loop error

These redirects are tricky though. If for some reason, before employing HTTPS, you were permanently redirecting
your users from HTTPS to HTTP (which is a bad practice) now you will get into trouble. 301 redirects are
hard-cached by the browsers. "Permanent" (301) means you will never want to change that redirection, so browsers
hard-cache that rule indefinitely.

Now when you switch to HTTPS the following will happen when a regular user (with a "HTTPS to HTTP" 301
redirection rule cached at his browser) hits a HTTPS website: The browser cache will immediately instruct the
page to go to HTTP thus the first redirection happens. And once that happens the web server redirect rule will
instruct the browser to go to HTTPS version of the website. Then the browser cache will kick in again
redirecting to HTTP, and then web server will redirect to HTTPS again, and the user will face an
**infinite loop** which will produce an error. In short, your website will be inaccessible for the
users who have cached "HTTPS to HTTP" 301 redirects in their browsers.

If you happen to be in this minority there's a hack that will help you. Before even attempting to switch to HTTPS
make sure you **remove** "HTTPS to HTTP" redirection. After that you need to drop in a
cache-control header with short expiry time and leave that there on your website for a prolonged period of time
to ensure your regular visitors' browsers get the memo that the rules tied with your pages (particularly this
301 redirection) shouldn't be cached indefinitely. It's a hack but it works.

``` nginx
add_header Cache-Control "max-age=3600";
```

Only then you would want to proceed with the whole [HTTPS implementation](#web-server) in order to
avoid the infinite loop error.


## Replace HTTP with HTTPS

If you have HTTP links hardcoded in your template files in your website's root folder (i.e. `htdocs`)
or in your database they will be taken care of by the redirection we've just enforced. However it's better to
replace them with HTTPS URLs. Keep in mind we're talking about your domain's **internal** links,
not external ones.


### Update the links in the template files

So we need to run a "search and replace" command in order to change those HTTP links into HTTPS ones. However if
you change just "http" string to "https" you risk modifying any external link you might have hardcoded in your
website's root folder files. Thus, we'll search for `http://example` and replace that with
`https://example`.

First backup your files:

``` bash
cd /var/www/example.com
```

``` bash
sudo tar chzf /path/to/backup/site-backup.tar.gz htdocs
```

Run "search and replace":

``` bash
sudo find htdocs -type f -print0 | xargs -0 sed -i 's/http\:\/\/example/https\:\/\/example/g'
```

Notice, `:` and `/` symbols in the command above are escaped.

Note, if you're using WordPress and your wp-config.php file is outside of the website's root folder and you have
domain URLs hardcoded there make sure you make them HTTPS too.


### Update the links in the database

Again, all those HTTP internal links hardcoded in the database will be handled by the redirection, but it's
better to switch them to HTTPS.

First, backup your database:

``` bash
mysqldump -u db_username -p db_name > /path/to/backup/db-backup.bak
```

Login to your database:

``` bash
mysql -u db_username -p db_name
```

Run "search and replace" SQL queries. For example if you run your website on WordpRess you would want to perform
"search and replace" in the following destinations:

In the post content:

``` sql
UPDATE wp_posts SET post_content = \
REPLACE (post_content, 'http://example', 'https://example');
```

In the post excerpts:

``` sql
UPDATE wp_posts SET post_excerpt = \
REPLACE (post_excerpt, 'http://example', 'https://example');
```

In the comments:

``` sql
UPDATE wp_comments SET comment_content = \
REPLACE (comment_content, 'http://example', 'https://example');
```

The points is to run "search and replace" through any tables in your database where you might have hardcoded HTTP
internal links.


## "Talk" to Google

Now when the hard work is done you need to "talk" to Google and give it a heads up about the fact that you've
made some crucial changes to your website. More specifically you need to adjust your settings at [Google Search Console](https://www.google.com/webmasters/tools/) (formerly known as Google
Webmaster Tools) and [Google Analytics](https://analytics.google.com/).


### Add new property in Google Search Console

After switching to HTTPS you need to add the HTTPS version of your website as a [brand new property](https://support.google.com/webmasters/answer/34592?hl=en) in Google Search
Console in order to utilize the tools in the console (search appearance, search traffic, Google index, crawl,
security issues, etc.). For example if you've opted to maintain the `non-www` version of your site
now all other versions will redirect to the property `https://example.com`.

`http://` will redirect to `https://`  
`http://www` will redirect to `https://`  
`https://www` will redirect to `https://`

There's no need to immediately delete the old HTTP property in your console. Observe whether all HTTP requests go
to HTTPS before deleting it. You don't even need to delete it at all. It can stay there for historical purposes.


### Submit new sitemap to Google

Assuming you are maintaining a sitemap at your website (as you should), you need to submit a new HTTPS sitemap to
Google, preferably via the new property you've just created in the Google Search Console. Just go to
**Crawl >> Sitemaps** section in Google Search Console and submit your sitemap there.

Alternatively you can ping Google by visiting this URL in your browser:  
`https://google.com/ping?sitemap=https://example.com/sitemap.xml`

Where `example.com` is your domain and `sitemap.xml` is your sitemap.


### Update the Google Analytics profile

Unlike the process in the Google Search Console, here you don't need to submit а new HTTPS version of your
website. All you need to do is [edit the property at Google Analytics](https://support.google.com/analytics/answer/3467852?hl=en) where you'll just change the protocol of the default URL. You want to be
HTTPS now.


### Re-associate Google Analytics with Google Search

Now you need to mutually [connect your
properties](https://support.google.com/analytics/answer/1308621?hl=en) at Google Analytics and Google Search Console. It's the same website so you need these two
tools to exchange data.

Basically you need to go to Google Search console homepage, select your website, and in the property settings
choose the Google Analytics profile you want this website in Google Search Console to be associated with.


## Update the external services

If your site has been long enough on the net the chances are high that you use some external services to boost
your traffic, engage with your visitors, etc. For example you may use a custom Facebook App, or you broadcast
your blog feed via newsletter using [Aweber](https://www.aweber.com/), or you just use a service
which automatically posts new content to Facebook and Twitter, such as [dlvr.it](https://dlvrit.com/).

Typically almost all external services will use your feed URL in order to get updates from your site so you need
to make a list of which external services your website uses and update the feed URL (change the protocol into
HTTPS) respectively in every service you use. That means you need to login in each and every one of them and
update your feed there.


## Extras

The effort here is to erase almost every HTTP occurrence of your website URL that is in your power to edit and
replace it with HTTPS. For example you might have had a custom redirect rules in your **web server
config** or elsewhere (i.e. PHP) that used to redirect one URL to another. Now you need to update
those custom redirects where destination URLs will be with HTTPS protocol in order to avoid multiple
redirections.

You might be also using a custom chron job in WordpPress where you ping your `wp-cron.php` file, let's
say, every 5 minutes. Therefore you need to edit the crontab (`crontab -e`) and use a proper HTTPS
protocol in the URL you ping. Otherwise your cron job might not work.

Think of places where your domain might appear in a HTTP version while you have the power to edit that.

Obviously the inbound links will be all with a HTTP protocol and you can't change that. That's why you have a
redirection in place to remedy that. You can start emailing websites in order to convince the webmasters to
update the links pointing to your website but this practise is not feasible for popular websites since they have
hundreds of thousands of links pointing to them. Anyhow, 301 redirection is more than a solid method for dealing
with the inbound links.

Further more, if for some reason the redirection fails (meaning your site for a brief period of time is
accessible both at HTTP and HTTPS) your [canonical URL](https://support.google.com/webmasters/answer/139066?hl=en) defined for every page in
your content, which will obviously have a HTTPS protocol, will tell Google what's the preferred URL.


## Crawl and fix

What's left to do now is to monitor your website for any errors and watch your inbox for complaints from your
visitors, if any. In order to speed up the monitoring, crawl your website with a spider in order to quickly
discover errors. One popular options is the [Screaming Frog](https://www.screamingfrog.co.uk/seo-spider/pricing/) which is free if your website
has under 500 pages, but I use one ancient piece of work called [Xenu's Link Sleuth](http://home.snafu.de/tilman/xenulink.html).

This way you'll discover if anything's gone wrong, especially with the redirection, and deploy a fix if
necessary. You might even start updating the external links from your website if those websites switched to
HTTPS too.


## Wrap up

Yet another gigantic article (3600+ words), but the process is really easy. It all boils down to enabling your
server to serve HTTPS, replacing the HTTP protocol with HTTPS wherever you can (files, database, services you
use, etc.), and setting up a "HTTP to HTTPS" redirection. That's it.
