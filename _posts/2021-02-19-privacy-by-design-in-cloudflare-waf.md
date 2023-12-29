---
layout: post
title: "Privacy by Design in Cloudflare's WAF"
description: "Adding better logging capabilities to Cloudflare's WAF while preserving privacy."
thumb_image: "cloudflare-2/main.png"
external: true
tags: [security, privacy]
---

When using a [Web Application Firewall (WAF)](https://en.wikipedia.org/wiki/Web_application_firewall) to protect your web application from malicious traffic, you're usually offered a set of rules maintained by the vendor and the ability to make your own.

During normal operation and monitoring, it is common for analysts to try to understand why a rule matched on a specific request, either to figure out if it was a false positive, or to inspect the malicious payload being sent.

To achieve this, WAFs usually log the HTTP request (or parts of it) alongside the ID of the rule that matched. This is widely done in a way where the request's contents are available to both the vendor and customer in logs. As rules can match on any kind of traffic, there will inevitably be times when that will happen on sensitive data.

Since at [Cloudflare](https://www.cloudflare.com) we believe in privacy by design and that data is toxic, I recently implemented this feature using public-key encryption and an emerging standard named HPKE. This means that when the HTTP request that matched a WAF rule is logged, it is encrypted with a private key that only the customer has, so Cloudflare can't decrypt it. Note that even the UI never sends the private key to Cloudflare, key generation and decryption is all done client-side.

The WAF backend, UI (WebAssembly) and a customer command-line-interface (CLI) are all written in Rust which alongside the [great Rust HPKE library by Michael Rosenberg](https://github.com/rozbb/rust-hpke) made implementation considerably quicker.

{% include image.html path="cloudflare-2/main.png"
   alt="Cloudflare TV segment." caption-no="1" caption="Cloudflare TV segment."
%}

You can read more about HPKE, the WAF implementation and more background details here: [blog.cloudflare.com - Using HPKE to Encrypt Request Payloads](https://blog.cloudflare.com/using-hpke-to-encrypt-request-payloads/). There is also a Cloudflare TV segment discussing the feature at the end of the blog post.
