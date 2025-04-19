---
Title: The Only SEO Strategy You Need
Date: 2018-01-02 10:20
Modified: 2018-01-02 10:20
Category: Frontend
Image: images/seo-strategy-720x250.jpg
Slug: seo-strategy
---

![The Only SEO Strategy You Need](images/seo-strategy-720x250.jpg "The Only SEO Strategy You Need")

Search engine optimization (SEO) is probably the most "esoteric" term when it comes to web development. The web
is literally littered with SEO tips. Almost everyone is claiming to be an "expert" these days. There are even
hundreds of books written on this topic. However, in my opinion, there's no need for overcomplicating things.
There are only several key points to implement:

1. [Content](#content)
2. [Technicality](#technicality)
3. [Maintenance](#maintenance)

All three parts are important, but I think the last one is crucial in a long run. The first two are instantly
implementable but the third one is doable after *you have had your site for a year or two, and you already
have hundreds if not thousands of live pages on it*.


## Content

You've probably already heard the phrase "the content is king" and it is true. It means you need to publish
really good content if you plan to rank higher in Google search. Good content constitutes thorough, original,
useful, linkable, likable and sharable piece of information. Google has its own way of determining what's good
content by measuring thousands of signals your page sends, and you can't possibly know all those signals or to
pretend to know how they work. What's in your power is to creatively produce useful information on the web.

Some people get bogged down in calculating the keyword density in their articles and/or employing other tactics
in order to "game" the system, but I will strongly advice against that. No one knows the right keyword density,
no one knows how many times your subject needs to be mentioned in the article, no one knows if you need to make
certain words in bold or not, etc. In my opinion that's ALL guesswork by people who pretend to know the inner
workings of Google, but in reality they don't. Like I said, you need to concentrate on your writing and a few
other technical aspects and that's it.


## Technicality

Along with the content your website needs to be technically set up. Your good content will go to waste if your
website is slow for example. So, roughly you need to pay attention to the following:

* Use [HTTPS protocol](/posts/migrate-http-https/),
* Make sure your website is loading [really fast](https://developers.google.com/speed/docs/insights/rules),
* Have a good, clickable [title tags and meta descriptions](https://support.google.com/webmasters/answer/35624?hl=en),
* Put [alt text](https://support.google.com/webmasters/answer/114016?hl=en) on your images,
* Set up simple and human readable [URL structure](https://support.google.com/webmasters/answer/76329?hl=en),
* Provide a [robots.txt](https://support.google.com/webmasters/answer/6062608?hl=en) file,
* Have a [sitemap.xml](https://support.google.com/webmasters/answer/156184?hl=en) file,
* Use H1, H2, H3… headings appropriately,
* Use [schema.org structured data](http://schema.org/docs/gs.html) if appropriate,
* Make use of [rel="canonical"](https://support.google.com/webmasters/answer/139066?hl=en) URL,
* Use [responsive design](https://developers.google.com/web/fundamentals/design-and-ux/responsive/) (your site needs to look awesome on any device),
* Set up an [AMP version](https://www.ampproject.org/) of your website,
* Make sure there are no funny redirections and/or errors.

If I start to write about all these in details this article will turn into a book, so you need to follow the
links and do a bit of research on your own. Like I said the web is littered with SEO info, especially the
technical aspect of it.


## Maintenance

This part is about watching your website's performance and acting accordingly. I have to note that what I'm about
to describe I am personally implementing it every six months on a high traffic website (around 2 million
pageviews per month) with 3000+ pages of content. The result is a noticeable increase in search traffic. Now,
this might seem as an anecdotal evidence, but nothing will cost you to experiment a bit.

The very logic of this process is something similar to [pruning your e-mal subscribers](/posts/prune-email-list/) or even [balancing your ads](/posts/proper-adsense-ad-balance/) but instead of pruning subscribers or getting rid of junk ads you need to occasionally prune the rubbish pages from your website.

Not all pages are created equal, so some of your pages will be good, some will be subpar, some really awesome and
some will be total rubbish in the eyes of Google. In the pre-2011 era webmasters were allowed to have junk pages
on their websites and that didn't affect the whole website. But the game has changed a long time ago and now if
you have a sufficient number of low quality pages on your website that will ultimately drag the whole website
down and it'll affect your awesome pages too.

And there comes the maintenance. First you need to identify the pages that don't perform well in Google search
and do something about it. You have three options: you can rewrite them and try to re-promote them, noindex
them, or delete them.


### Identify the low quality pages

Assuming you have a list of all pages/URLs on your website (extract the list of URLs from your sitemap to an
excel - xlsx file) you need to remove from that list the pages that were added to the website during the last
year.

Then, go to your Google Analytics, set the timeframe for the last year (last 365 days) and hit:
**Acquisition >> All Traffic >> Source/Medium >> google/organic**. Now, as an
additional primary dimension add **Landing Page**.

Since [*sessions* correspond to *entrances*](https://support.google.com/analytics/answer/2934985?hl=en) when you combine *sessions* with a page level dimension the result will be a list of landing pages ordered by the volume of Google traffic (entrances from Google search). However, the data in this report will be [definitely sampled](https://support.google.com/analytics/answer/2637192), meaning wildly inaccurate and misleading for our purpose.

The obvious remedy here is to [increase the report's precision](https://support.google.com/analytics/answer/1733979), but that wouldn't be enough. My experience tells me that in order to achieve 100% precision,
that's 100% of the sessions in this type of report, you need to decrease the timeframe to around 15 days
(instead of 365). That means you need to export around 25 excel (xlsx) reports from Google Analytics for the
last year.

Now, you need to place all those 25 reports in an excel workbook and the values inside each one of them should be
added up for each URL, so each URL in our list derived from our sitemap can have the total number of Google
sessions (entrances) for the last year. Assuming your excel-kung-fu is very strong, by using few excel formulas
you can automate this process, otherwise it'll be a very hard labour.

It's a hard work, nevertheless very interesting, but now you have a list of pages (minus the pages that were
added during the last year) ordered by the volume of Google traffic they've received in the last year. By
further usage of excel wizardry you can show percentages in this list, meaning how many percent each URL
contributes to the total website's Google traffic.

In my work I've found a staggering result that the 300 least visited pages on the site contributed to only 1% of
the total website's Google traffic, and even more staggering result that the 1500 least visited pages (half of
the total pages) contributed to only 5% of the total website's Google traffic. Practically Google thinks that
around half of your pages are rubbish and don't deserve to rank relatively high even for a long-tail keywords.

To be even more sure you can repeat this whole procedure for a timeframe of the last six months, which will be
not that hard since you already have the reports, and compare the two final results. If a page is in the last 1%
in both two findings that's definitely a bad page. By doing this you will reduce the number of pages that fit in
the last 1%, because some pages were doing really bad for the whole last year on average, but they were doing
not that bad in the last 6 months, so you can't find them in the both bottom 1% for the last 6 and 12 months.


### Eliminate the low quality pages

As I've said you can rewrite these pages and try to re-promote them, noindex them, or delete them.

If the number of pages you want to eliminate is very high rewriting them isn't an option. Even if you do it, it
is not guaranteed that they will move through the ranks. You can delete them, but some of them are already
shared, liked, retweeted, linked, etc. so you will end up with a lot of dead ends on your site.

One sub-solution here is to redirect them to similar pages, and that's a good option which will require a lot of
work. The redirection needs to be done very carefully. I suggest 302 (temporary) redirection. Do not redirect to
your homepage or some other generic page but every redirection needs to be done carefully, pointing to a page
that has a lot in common to the page that's being redirected.

Or you can nonindex these pages, meaning instruct the googlebot to remove them from the Google index:

``` html
<meta name="googlebot" content="noindex">
```

This is the least painful solution and the most practical. In addition to noindexing you need to make sure these
pages are not linked from prominent places on the website, like the related content below each post, the
homepage, sidebar, etc. not to disrupt the googlebot, and paint a broken picture of your website.

After noindexing you can monitor the website for the next 3-6 months and see what's happening. If the results are
bad (you've lost more than 1% of your Google search traffic due to this move) you can always reindex the pages
and somewhat restore the traffic. If there are positive results you can move on to redirection which can be also
reversed if something ultimately goes wrong since it's a 302 (temporary) redirection.

Finally, if you want to proceed with deletion of so many pages you need to be cautious since that's a point of no
return, unless you decide to restore a [backup of your website](/posts/backup-site-properly/).


## Wrap up

I think this is the most "laborious" tutorial so far, even if it's not that long in writing. In order to
implement this you'll need days of hard work, if not weeks.


