---
Title: Setup Secure Mail Server
Date: 2017-11-14 10:20
Modified: 2017-11-14 10:20
Category: Backend
Image: images/setup-secure-mail-server-720x250.jpg
Slug: setup-secure-mail-server
---

![Setup Secure Mail Server](images/setup-secure-mail-server-720x250.jpg "Setup Secure Mail Server")

You want to turn your server into an email-sending-monster-machine with a limit of 100 emails per day, without
any consequences upon the server's IP reputation and yet 99.99% deliverability, and not getting your hands too
"dirty" along the process? You want your server/root to be able to send several thousands of emails per month
without almost none of them getting into someone's spam folder, and all that for FREE? If so, keep reading.


## In this article:

1. [Get a SendGrid account and whitelabel your domain](#get-a-sendgrid-account-and-whitelabel-your-domain)
2. [Install and configure Postfix](#install-and-configure-postfix)
3. [Test the mail server](#test-the-mail-server)


## Get a SendGrid account and whitelabel your domain

Sign up for a [FREE SendGrid account](https://sendgrid.com/free/). Then [whitelabel your
domain](https://sendgrid.com/docs/Classroom/Basics/Whitelabel/setup_domain_whitelabel.html). Whitelabeling is e fancy term for letting SendGrid handle SPF and DKIM records for you.

Think off one subdomain of your domain (don't choose mail.example.com), let's say `em.example.com`,
and specify that subdomain at SendGrid as instructed in their documentation. If you choose to use "Automated
Security" (as you should) SendGrid will give you three CNAME records for you to set at your domain's DNS
registrar.

Example:

``` bash
CNAME  em.example.com             uxxx.wxxx.sendgrid.net
CNAME  s1._domainkey.example.com  s1.domainkey.uxxx.wxxx.sendgrid.net
CNAME  s2._domainkey.example.com  s2.domainkey.uxxx.wxxx.sendgrid.net
```

After you've set those CNAME's at your DNS registrar, validate them at SendGrid.

Then [create an API key](https://sendgrid.com/docs/User_Guide/Settings/api_keys.html#-Creating-an-API-key) where you'll set a "restricted access" and give ONLY **Email Send** permission, and
take a note of the key.


## Install and configure Postfix

Run the command:

``` bash
sudo apt-get install postfix
```

You'll be prompted to configure Postfix. Set the following values:

**General type of mail configuration?** : `Internet Site`.  
**System mail name**: `example.com` (your domain).

Open the Postfix config file:

``` bash
sudo nano  /etc/postfix/main.cf
```

Paste the following:

``` bash
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
smtp_tls_security_level = encrypt
header_size_limit = 4096000
relayhost = [smtp.sendgrid.net]:587
```

Exit `CTRL+X`, save `y`.  
Create a separate password file:

``` bash
sudo nano /etc/postfix/sasl/sasl_passwd
```

Paste the following:

``` bash
# SendGrid API Key for sending mail
[smtp.sendgrid.net]:587 apikey:your-sendgrid-api-key-here
```

Exit `CTRL+X`, save `y`.  
Notice above you have to use the API key you've generated at SendGrid.

Restrict access to the password file:

``` bash
sudo chmod 600 /etc/postfix/sasl/sasl_passwd
```

Run `postmap` command:

``` bash
sudo postmap /etc/postfix/sasl/sasl_passwd
```

The command above will create hash db file, which you have to make sure it's protected too:

``` bash
sudo chmod 600 /etc/postfix/sasl/sasl_passwd.db
```

Restart Postfix:

``` bash
sudo service postfix restart
```


## Test the mail server

Use `sendmail`:

``` bash
sendmail someone@mail.com
```

Construct the email:

``` bash
From: you@example.com
Subject: Just testing the email
Enter something here
.
```

If `someone@mail.com` receives the email you're good to go.


## Wrap up

Whenever your server sends an email (whether that bee the root, cron, fail2ban, or even WordPress) rest assured
it will be certainly delivered with SPF and DKIM aligned. Your server wouldn't even technically send it. It will
just instruct SendGrid to send it. And SendGrid knows how to really deliver emails.
