---
Title: Preload, Observe and Intersect
Date: 2017-11-17 10:20
Modified: 2017-11-17 10:20
Category: Frontend
Image: images/preload-observe-intersect-720x250.jpg
Slug: preload-observe-intersect
---

![Preload, Observe and Intersect](images/preload-observe-intersect-720x250.jpg "Preload, Observe and Intersect")

When testing your site with [Lighthouse](https://developers.google.com/web/tools/lighthouse/), very
often if not always, amongst the many suggested parameters to fix are the [critical
rendering path](https://developers.google.com/web/fundamentals/performance/critical-rendering-path/) and the [offscreen images](https://developers.google.com/web/tools/lighthouse/audits/offscreen-images).

So, the easiest way to fix this (meaning to speed up your site) or at least to improve the perceived speed in
some browsers, is to preload some of your resources with `rel="preload"` (most usually your CSS,
light scripts, and even fonts), and to use [IntersectionObserver](https://developers.google.com/web/updates/2016/04/intersectionobserver) to
lazy load your images, that is if you have a lot of them on a given page.

[Preload](https://caniuse.com/#search=preload) and [Intersection Observer](https://caniuse.com/#search=IntersectionObserver) are very new to the scene
and WILL NOT work on all browsers.


## Table of Contents:

1. [Preload](#preload)
2. [Intersection Observer](#intersection-observer)


## Preload

`rel="preload"` works in a way where you instruct the browser to fetch let's say the CSS file in the
exact same time with the HTML removing the obstacle it presents later when the browser starts to read and render
the document (HTML). Ordinarily, when the browser gets to the CSS in the document it can't proceed to start
visually displaying the page until it downloads the CSS fully. That way CSS is an effective obstacle in the
rendering path, and that's true for any resource of the similar nature. With `rel="preload"` that
obstacle is removed because the browser already fetches the CSS together with the HTML.

`rel="preload"` can be invoked in several ways:

Directly in the HTML:

``` html
<link rel="preload" href="/style.css" as="style">
```

In the header via PHP for example:

``` php
<?php
header("Link: </style.css>; rel=preload; as=style; nopush", false);
header("Link: </script.js>; rel=preload; as=script; nopush", false);
?>
```

In the header via the server (Nginx in this case):

``` bash
add_header Link "</style.css>; rel=preload; as=style; nopush";
add_header Link "</script.js>; rel=preload; as=script; nopush";
```

Where `nopush` is an optional attribute telling the server not to initiate HTTP/2 server push which is
a bit different operation than `preload`. With the HTTP/2 server push the server alone decides
whether the resource should be prefetched to the client and the file may not be included in the client's cache.

Using any of the directives above doesn't mean you should omit linking the CSS file in the HTML document.
`Preload` makes the assets downloaded and ready. You actually need to refer to them in the document
as you would normally do.

Now, when using `rel="preload"` you're effectively shoving up one more file in the pipe along with the
HTML for the browser to swallow which now has initially two files to fetch simultaneously when it lands on a
page (CSS and HTML). So, it's a trade off, meaning you shouldn't preload too many or/and massive files because
that will have a negative impact. The page will in effect load more slowly than having those assets blocking the
rendering path in the first place. That's why you should test everything.

External CSS files (and other files such as scripts, etc.) are cached locally upon the first use and from there
no longer downloaded from the server, thus they do not hinder the rendering path anymore, except for the first
time visitors. So, they present a "problem" ONLY upon the first use. Since `preload` function with
`nopush` directive will pull the file (if there's one) from the client's cache, you can use these
headers for all the visitors (unique and repeating).

> Conceptually, a preloaded response ought to be committed to the HTTP cache, as it is initiated by the client,
>  and also be available in the memory cache and be re-usable at least once within the lifetime of a fetch
>  group. - [w3.org](https://www.w3.org/TR/preload/#processing).

*Conclusion*: Test whether the first time visitor is better off with rendering path blocked or you should
preload some of the resources. Test whether you should, and what to preload.


## Intersection Observer

In the "old" days there were many solutions for lazy loading the images but all of them were bloated by the
nature of their very design since you we're needed to deploy massive chunks of scripts in order to achieve the
effect, and the effect was mostly visual rather then boosting the performance.

Now with the `IntersectionObserver` the heavy lifting is left to the browser itself. Basically this
neat function is built-in in the newest browsers and all you have to do is provide a small script in order to
employ this feature. There are many suggested solutons across the web but I would suggest [lozad.js](https://github.com/ApoorvSaxena/lozad.js).

All you need to do is to include this script in the HTML. You can download the script and serve it from your
server or from a CDN of your choice, or even inline it.

``` html
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/lozad/dist/lozad.min.js"></script>
```

Then, provide a `class="lozad"` to your images and equal their URLs to `data-src` instead
of `src`. It should look like this:

``` html
<img class="lozad" data-src="image.png" />
```

Finally initiate the lozad script. There are [several
variants](https://github.com/ApoorvSaxena/lozad.js#usage) for initiating depending of what you want to achieve.

``` html
<script>
const observer = lozad();
observer.observe();
</script>
```

The only drawback here is that by using `data-src` instead of `src`, when it comes to your
images, you're effectively hiding them from the web crawlers thus probably making them unindexable which is bad
for searh engine optimization (SEO), that is if you're dependant on an image search traffic.

So the best strategy here is to serve your above the fold images regularly, with `src` and without the
help of `lozad.js`, and the rest with `data-src` and with `lozad.js`, plus you
can reveal all of your images to the crawler bots via the [image schema
mark-up](http://schema.org/image):

``` html
<meta itemprop="image" content="image.jpg">
```

## Wrap up

Don't use `rel="preload"` indiscriminately. Test and see where it actually increases the performances
for the first time visitors. Definitely use `IntersectionObserver` to lazy load your images if you're
heavy on the media.
