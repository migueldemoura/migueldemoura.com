+++
title = "Making the Cloudflare WAF 40% faster"
description = "Improving the Cloudflare WAF performance, decreasing latency and CPU consumption."
updated = "2024-12-29"
[extra]
thumb_image = "images/cloudflare-1/main.png"
external = true
+++

I've been at [Cloudflare](https://www.cloudflare.com) working as a Systems Engineer in the [Web Application Firewall (WAF)](https://en.wikipedia.org/wiki/Web_application_firewall) team for around 1 and half years now.

At Cloudflare we always strive to deliver security and performance without compromising either, so I spent some time the last few weeks working on potential WAF performance optimizations.

Following the rollout of this piece of work, we observed a decrease of `40%` in the average time the WAF takes to process an HTTP request and a `4.3%` drop in CPU consumption at the edge.

{{ image(
    path="images/cloudflare-1/main.png",
    alt="Decrease in average time to process an HTTP request by the WAF.",
    caption_no="1",
    caption="Decrease in average time to process an HTTP request by the WAF."
) }}

I've written about these optimizations, the regex engine migration we did back in July of 2019 and our ongoing engine migration here: [blog.cloudflare.com - Making the Cloudflare WAF 40% faster](https://blog.cloudflare.com/making-the-waf-40-faster/).
