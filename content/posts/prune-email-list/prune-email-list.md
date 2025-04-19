---
Title: Prune Your Email List
Date: 2017-11-03 10:20
Modified: 2017-11-03 10:20
Category: Frontend
Image: images/prune-email-list-720x250.jpg
Slug: prune-email-list
---

![Prune Your Email List](images/prune-email-list-720x250.jpg "Prune Your Email List")

If you're at least semi-serious about your online business the chances are high that you collect e-mail addresses
from your visitors for the purpose of sending them newsletters. It's a very efficient way to connect with your
loyal base in a very direct manner. Surprisingly, despite the existence of new messaging technologies and
different communication apps, e-mail continued to be one of the most used means for communication. People love
their e-mail.


However, you need to keep that mailing list healthy. You don't want, after a year, the list to be bloated with
inactive subscribers who didn't open the newsletter for five months, let alone clicked something, and yet you
pay for them. And there comes the pruning.


As your online business (or hobby) grows you'll probably rack up thousands of e-mail subscribers and you'll end
up using one of the email marketing software solutions, like [AWeber](https://www.aweber.com/index.htm), [MailChimp](https://mailchimp.com/), [GetResponse](https://www.getresponse.com/), to name a few. Of course you can build, maintain and
grow your mailing list "manually" by storing the contacts in a database (locally or elsewhere) and use
transactional e-mail services, like [SendGrid](https://sendgrid.com/), [Amazon SES](https://aws.amazon.com/ses/), etc. to send your newsletters. This solution it's
cheaper, around 50% cheaper, but you won't have such a granular control as with the first option.


Anyhow, whichever solution you use to send your newsletters you'll need tight control over your mailing list to
achieve what we're going to talk about here in terms of compiling particular segments from your mailing list and
targeting emails to those segments.


## In this article:

1. [Segment](#segment)
2. [Reminder](#reminder)
3. [Unsubscribers](#unsubscribers)


## Segment

That being said, the first thing you need to do is to create a segment which will contain subscribers added to
your mailing list before a certain date in the past (usually 3-4 months in the past, depending on how often you
send newsletters).

For example if today is 12/18/2017 then we want subscribers in this segment that were added to the mailing list
before 8/18/2017 to make sure the segment does not contain relatively recent subscribers. Now we'll apply one
more condition to that segment. We specifically want subscribers that didn't open the newsletter since that same
date (8/18/2017). We're practically creating a segment of INACTIVE "older" subscribers.

Now, since we've identified who's not interested in our newsletter anymore we need to get rid of those contacts
because they cost money laying around in our mailing list. The services I've mentioned above will charge you for
storing their email addresses and sending emails to them. Plus keeping them will increase the overall bounce
rate of the list, and that's not good for you reputation as a sender.

If you're lazy, you can now remove all subscribers in this segment from your mailing list. But it's worth to send
them a reminder.


## Reminder

Since we've identified our inactive subscribers we'll remind them that they're still subscribed, and that they
will be queued for deletion if they don't reconfirm their subscription. You need to craft a polite broadcast in
which you'll give two options to those subscribers:

1. To reconfirm their subscription by clicking a prominent custom link - that can be your domain followed by
a string, for example: `https:example.com/?reminder`, or
2. To unsubscribe instantly from the service.

After sending the broadcast ONLY to this segment of inactive subscribers, you need to wait for a few days. Then,
you can remove/delete the subscribers in this segment who DIDN'T click the reminder link. You'll have this
granular control over your mailing list to find out who clicked, or not, a certain link in a broadcast in the
services I've mentioned above.


## Unsubscribers

Also while doing this ritual, usually before your payment to these mailing services is due, you need to delete
 the unsubscribers too - the people who literally unsubscribed. They're not automatically removed from your
 mailing list. The mailing service assumes you would want to do something with them and you'll be charged for
 keeping them.


## Wrap up

That's it. Usually near the end of the month create a segment of inactive subscribers, send them e reminder, wait
for a few days, and what's left in the segment remove it from the mailing list. Worth to mention that this
process can be automated/scheduled to a certain degree. Don't forget to delete the unsubscribers too. This way
you'll have a vibrant, engaged mailing list, with double less bounce rate and complaints, plus you'll pay less.
 
**Bonus tip**: To lower the bounce and complain rate even more, when sending your regular newsletter
offer the unsubscribe option at the beginning of the newsletter instead of just at the end.
