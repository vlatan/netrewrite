---
Title: Backup Your Site... Properly
Date: 2017-10-30 10:20
Modified: 2017-10-30 10:20
Category: Backend
Image: images/backup-site-properly-720x250.jpg
Slug: backup-site-properly
---

![Backup Your Site... Properly](images/backup-site-properly-720x250.jpg "Backup Your Site... Properly")

Assumptions:

* You run your website on a server with Ubuntu installed.  
* You operate as a non-root user with sudo privileges (as you should).  
* You want to use AWS as an offsite backup destination.

It goes without a saying if you have a valuable web asset you need to
maintain a secure backup because of several reasons:

* To have a log of the changes you've made in the past.
* To have a copy of your website if you want to restore it.
* To sleep well at night because even if there's a major hack,
hardware failure or even a natural disaster your web asset is not
lost and you can easily respawn it.

## In this tutorial:

1. [Amazon Web Services (AWS) setup](#aws-setup)
2. [Install and configure the AWS CLI on your server](#install-and-configure-the-aws-cli-on-your-server)
3. [Create .my.cnf file](#create-my-cnf-file)
4. [Create backup scripts](#create-backup-scripts)
5. [Test and create cron jobs](#test-and-create-cron-jobs)


## AWS setup

Follow the links and read the content there carefully.

1. [Sign up for an AWS account](https://aws.amazon.com/s3/) if you already don't have one.
2. [Create S3 bucket](http://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html). Make
sure it's not public.
3. [Create an IAM user](/posts/static-site-hugo-aws/#create-an-iam-user) with "programmatic access"
to your bucket.

Later we'll need this IAM user to access the backup folder behind the scene and automatically sync our files with
the origin.


## Install and configure the AWS CLI on your server

It's a fairly simple process. Practically we're enabling [specific Command
Line Interface](https://aws.amazon.com/cli/) which Amazon uses as means for communication between machines. Read here on [how to install it on your server](/posts/static-site-hugo-aws/#install-and-configure-aws-cli).


## Create .my.cnf file

Assuming you have a database to dump during your backup you'll need `~/.my.cnf` file, which will store
your database password, so you don't have to hardcode the password in the backup scripts. Of course you'll still
have to hardcode your db password but now in `~/.my.cnf` which is arguably a more secure method.

``` bash
nano ~/.my.cnf
```

Paste the following, so you don't have to use a username/password
every time you perform `mysqldump`:

``` bash
[client]
user="your-db-username-here"
password="your-db-password-here"
# optionally you can define the host if you decide to use 
# 'skip-name-resolve' setting at /etc/mysql/my.cnf
host="127.0.0.1"
```

Exit `CTRL+X`, save `y`.

Restrict access to this file:

``` bash
chmod 600 ~/.my.cnf
```


## Create backup scripts

You don't want to store your backups on your server.
If it's compromised it's likely that your backups will be
compromised too and we don't want that. Therefore we will immediately
move every backup at **s3** once we're done creating it.

So create a bucket at **s3**, and within that bucket create three folders:
`daily`, `weekly` and `monthly` because we're going to maintain
daily, weekly and monthly backups.
 
Now, we'll need three custom shell scripts `daily-backup`, `weekly-backup`
and `monthly-backup` respectively.

Create and open for editing the first shell script:

``` bash
nano ~/.local/bin/daily-backup
```

Now we'll construct the script step by step.

Record the date at the time this script runs. This is needed to
append a timestamp to the backup files which the script is going to create:

``` bash
# save the date (day, month, year, hour, minutes)
THEDATE=`date +%d%m%y%H%M`
```

Save the path to the root of your website in a variable.
Notice there's no forward slash in the path stored in this variable,
because I find it more syntactically appropriate to use it that way
in the rest of the script.

``` bash
# path
WEBSITE="var/www/example.com"
```

Dump the database:

``` bash
# dump the website's database
# you need [client] credentials in '/home/<user>/.my.cnf' 
# for this to work in the script
mysqldump db_name > db-backup.bak
```

`db_name` is the name of the database you want to dump.

Tar and gzip the website's root directory (`htdocs` in this case,
yours may be different), along with the database we've dumped.
You can include as many different folders and/or files as you want
here. Practically everything you think you want to back up.

``` bash
# tar/gzip the needed files/folders
# into one file `sitebackup$THEDATE.tar.gz`
tar chzfP sitebackup$THEDATE.tar.gz \
/home/<user>/db-backup.bak /$WEBSITE/htdocs \
/$WEBSITE/some/other/file.log /etc/nginx/some/other/folder
```

Where [tar syntax](https://www.computerhope.com/unix/utar.htm) is:

`c` - create.  
`h` - follow symlinks.
 
If you have symlinks in your backup files and you do not follow them during tar the script might produce a
warning. This will not stop the script from functioning but the server will throw an email notification every
time the script runs, which is everyday in this case and we don't want that.

`z` - read/write through gzip.  
`f` - create archive file.  
`P` - don't strip the leading `'/'` from file names.
 
The next step is to remove the database we've dumped.
We don't need it anymore, since now it's already bundled
and gzipped together with the rest of the backup files/folders.

``` bash
# clean up
rm db-backup.bak
```

At this point our gzipped backup file is ready to be moved to our **s3** bucket:

``` bash
# move the backup we just created to s3
aws s3 mv sitebackup$THEDATE.tar.gz \
s3://your-backup-bucket/daily/sitebackup$THEDATE.tar.gz \
--storage-class STANDARD_IA --quiet
```

**Note**: You might have to use the full path to **aws**
in the command above so the cron job we're going to create later on
can successfully call it. You can see the full path to **aws** with
this command:

``` bash
which aws
```

The output might be something similar to this:

``` bash
/usr/local/bin/aws
```

So, the `aws s3 mv` command will look like this:

``` bash
# move the backup we just created to s3
/usr/local/bin/aws s3 mv sitebackup$THEDATE.tar.gz \
s3://your-backup-bucket/daily/sitebackup$THEDATE.tar.gz \
--storage-class STANDARD_IA --quiet
```

Where `aws s3 mv` [syntax](https://docs.aws.amazon.com/cli/latest/reference/s3/mv.html) is:
 
`--storage-class STANDARD_IA` - store as a standard infrequently accessed file.  
`--quiet` - run the command quietly without verbose output.
 
That completes the script and it should look like this:

``` bash
#!/bin/sh

# save the date (day, month, year, hour, minutes)
THEDATE=`date +%d%m%y%H%M`

# path
WEBSITE="var/www/example.com"

# dump the website's database
# you need [client] credentials in '/home/<user>/.my.cnf' 
# for this to work in the script
mysqldump db_name > db-backup.bak

# tar/gzip the needed files/folders
# into one file `sitebackup$THEDATE.tar.gz`.
# use full paths to files/folders
tar chzfP sitebackup$THEDATE.tar.gz \
/home/<user>/db-backup.bak /$WEBSITE/htdocs \
/$WEBSITE/some/other/file.log /etc/nginx/some/other/folder

# clean up
rm db-backup.bak

# move the backup we just created to s3
/usr/local/bin/aws s3 mv sitebackup$THEDATE.tar.gz \
s3://your-backup-bucket/daily/sitebackup$THEDATE.tar.gz \
--storage-class STANDARD_IA --quiet
```

Exit `Ctrl + x`, save `y`.

Make the script executable:

``` bash
chmod 700 ~/.local/bin/daily-backup
```

After this you need to set
[lifecycle rules](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-lifecycle.html)
for the folders (`daily`, `weekly` and `monthly`) in your
**s3** bucket because we don't want to indefinitely increase the
size of that bucket. For example we want to just keep the last 15 backups
in each folder.

So, because our scripts will run every day, every first day of the week
and every first day of the month we want to respectively set the lifecycle rules
like this:

Expire objects older than 15 days in `daily`.  
Expire objects older than 15 weeks (105 days) in `weekly`.  
Expire objects older than 15 months (450 days) in `monthly`.

We also don't want to keep the previous versions of the objects after
the expiration, nor we want to transition the expired objects to a different storage
class. We just want to permanently remove the expired objects,
unless you want to do it differently.


## Test and create cron jobs

Test the script via the command line and check whether it places
a backup in your `daily` folder in the **s3** bucket:

``` bash
daily-backup
```

Create a cron job for this script:

``` bash
crontab -e
```

Optionally you might want to log the behavior of the script.

``` bash
# The backup script is in ~/.local/bin/
# Run daily backup (everyday at 06:00)
0 6 * * * /home/<user>/.local/bin/daily-backup >> \
/path/to/logs/site-backup.log
```

Exit the crontab: `Ctrl + x`. It will automatically save the changes.

See how the script behaves when executed via cron.
If it doesn't create backups in your **s3** bucket find the problem.
Make sure you use the full path to **aws** in your backup script.

Finally, make copies of the script we made and change the word
**daily** to **weekly** and **monthly** respectively in the
scripts' NAME and in the scripts' CONTENT.

``` bash
cd ~/.local/bin

cp daily-backup weekly-backup
cp daily-backup monthly-backup

sed -i 's/daily/weekly/g' weekly-backup
sed -i 's/daily/monthly/g' monthly-backup
```

Also, you might want to change the storage class to `GLACIER`
in your weekly and monthly backup scripts because you will almost never access
those archives. Keep in mind, if you want to access them though it can take hours
because of the nature of the `GLACIER` archive which is way cheaper but
not instantly accessible.

``` bash
sed -i 's/STANDARD_IA/GLACIER/g' weekly-backup
sed -i 's/STANDARD_IA/GLACIER/g' monthly-backup
```

Next, you want to create two additional cron jobs:

``` bash
# Run weekly backup (every Monday at 07:00)
0 7 * * 1 /home/<user>/.local/bin/weekly-backup >> \
/path/to/logs/site-backup.log

# Run monthly backup (on the 1st day of every month at 08:00)
0 8 1 * * /home/<user>/.local/bin/monthly-backup >> \
/path/to/logs/site-backup.log
```


## Wrap up

To conclude, you will end up with three scripts which will
produce gzipped backups of your files and your database
every day, every first day of the week and every first day of the month.
In time you'll always have 15 daily, 15 weekly and 15 monthly (total 45)
backup versions (restore points) of your website.

Now you might think the storage of these backups will probably
cost a fortune. Not at all. Storing these backups at AWS will
cost you pennies.

So you're all set.
