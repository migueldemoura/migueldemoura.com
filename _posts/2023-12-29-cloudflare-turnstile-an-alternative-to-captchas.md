---
layout: post
title: "Cloudflare Turnstile - a CAPTCHA alternative"
description: "A user-friendly, accessible, privacy-preserving alternative to CAPTCHAs."
thumb_image: "cloudflare-3/main.png"
external: true
tags: [security, bots]
---

A few years ago, I changed from the [Web Application Firewall (WAF)](https://en.wikipedia.org/wiki/Web_application_firewall) team at Cloudflare to the (No)CAPTCHA team, where I've been working on ways to detect [bots](https://en.wikipedia.org/wiki/Internet_bot) without using [CAPTCHAs](https://en.wikipedia.org/wiki/CAPTCHA), the visual and/or audio puzzles we have to solve all over the Web to prove we're not robots.

These have been the classical way to solve this problem, but they are universally disliked, cause users to leave websites, and [bots are better than humans at solving them](https://arxiv.org/pdf/2307.12108.pdf) anyway.

To avoid this, Cloudflare announced Turnstile a bit over a year ago. It's a free, user-friendly, accessible and privacy-preserving alternative to CAPTCHAs.

{% include image.html path="cloudflare-3/main.png"
   alt="Cloudflare Turnstile widget. Click the button and you're done!" caption-no="1" caption="Cloudflare Turnstile widget. Click the button and you're done!"
%}

I'm quite proud of the product. The underlying technical challenges are quite challenging, and the never ending cat-and-mouse game makes it always interesting.

For more details, the team has written about Turnstile and how we detect bots in a few blog posts:

[blog.cloudflare.com - Announcing Turnstile, a user-friendly, privacy-preserving alternative to CAPTCHA](https://blog.cloudflare.com/turnstile-private-captcha-alternative/)

[blog.cloudflare.com - Cloudflare is free of CAPTCHAs; Turnstile is free for everyone](https://blog.cloudflare.com/turnstile-ga/)

[blog.cloudflare.com - Integrating Turnstile with the Cloudflare WAF to challenge fetch requests](https://blog.cloudflare.com/integrating-turnstile-with-the-cloudflare-waf-to-challenge-fetch-requests/)
