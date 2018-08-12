---
layout: post
title: "Harder to Report than to Find Security Vulnerabilities - Portuguese Government"
description: "Part 1/2 - Portuguese National Health Service Web Services Security Disclosure"
thumb_image: "sns-1/main.png"
tags: [security, disclosure, web]
---

> **Part 1/2** of the [Portuguese Health Service Portal](https://www.sns.gov.pt) security disclosure.
>
> **Summary**: It was significantly **harder to report the flaws than to find them**. This is easily the worst experience I've had, and I understand why some opt to just let it go.

After having analysed web portals/apps from the private [Energy](/posts/edp-vulnerability-disclosure/) and [Health](/posts/cuf-vulnerability-disclosure/) sectors, it is time to delve into a public service instead - the [Portuguese Health Service](https://www.sns.gov.pt) (*Serviço Nacional de Saúde* - SNS). The [SNS Portal](https://servicos.min-saude.pt/utente/) allows Portuguese citizens to view their medical history including, but not limited to, appointments, prescriptions, emergencies, medication, allergies, diseases and vaccines, as well as a considerable amount of personal data.

Some issues were the first ones I had ever stumbled upon, leaving me excited to reach out and have them fixed. This past year, however, has taught me that **reporting security vulnerabilities can be a very unpleasant task**.

{% include image.html path="sns-1/main.png"
   alt="Main SNS page." caption-no="1" caption="Main SNS page."
%}


### Security is Hard to Put in Layman's Terms

It all started July of last year. While trying to register on the web portal, I noticed that the bits of data necessary for registration amounted to my name, birth date and health number. Knowing these, you could register as another person and access their personal information. Not only are most of these readily available from social media, but they are also imprinted on every Portuguese ID card.

So I emailed and called the SNS government services (SPMS) to explain the situation. Perhaps unsurprisingly, the person who answered the phone continuously dismissed my claims, arguing that a few digits inscribed on a card were personal and private, and that it was the **owner's responsibility to prevent anyone from reading them**. This is preposterous for several reasons, one of them being that we are constantly required by government agencies to *scan* our ID card and send it via insecure methods to prove our identity. To affirm that such details are private and equatable to a password is ingenuous, complete nonsense and miss the impracticalities involved. **ID numbers provide identification, not authentication**!

{% include image.html path="sns-1/report-contact.png"
   alt="SNS Report contacts page." caption-no="2" caption="SNS Report contacts page."
%}

Not too happy with the response, I went back to the web portal and started poking for more authentication-logic flaws. A few moments later I found some obvious mistakes that were easier to demonstrate and model, and sure enough, the person on the other side agreed and opened a support ticket.

As I've said previously, this was the first time I'd reached out to an entity to report a security flaw. I expected them to forward the information to the appropriate department and get a response quickly with an [ETA](https://en.wikipedia.org/wiki/Estimated_time_of_arrival) for a fix. Suffice to say, things didn't go quite as I envisioned.


### Finding a Contact Email via an Android App Package

I called, I emailed and I waited. One month went by. Tired of waiting, I decided to try to find a different point of contact; clearly the support line wasn't going to cut it. Having had decompiled their android apps searching for some useful endpoints, I figured maybe they left a developer's email somewhere in the metadata.

One of the endpoints was a self-hosted [Sentry](https://sentry.io) instance, an error tracker and monitoring tool for developers. When I tried accessing its home page, I was presented with a login form. Luckily enough, registrations were left wide open, allowing me to register a dummy account with a disposable email. After logging-in, I navigated to the members tab when, lo and behold, I found 2 emails of real people!

{% include image.html path="sns-1/sentry.png"
   alt="Sentry - Member page." caption-no="3" caption="Sentry - Member page."
%}


### Real People; no Real Progress

After finding these precious addresses, I emailed them both right away with the details. I got a great response the next day, provided the full disclosure and was told it had been forwarded to the security team. And I left it there, although with a very rewarding feeling of mission accomplished. But things didn't go as planned, again.

Four and a half months later, already in 2018 and without any news, I emailed the same person back and asked for an update. Again a response landed swiftly on my mailbox, but without an update since they weren't in direct contact with the security team. I was assured they were on it, however.

Yet, I was still left with a bitter taste on my mouth since **feature updates were constantly being rolled out, yet not even a patch to disable the vulnerable functionality had been issued.**

{% include image.html path="sns-1/main-portal.png"
   alt="Main SNS Portal page - new features." caption-no="4" caption="Main SNS Portal page - new features."
%}


### Maybe the Data Protection Authority will Help

At this point, I had discovered a very serious vulnerability on another Portuguese Government web service (not disclosed yet). Wary of how difficult reports had been to public entities, I started searching for alternative ways to follow through and get things fixed.
A couple web queries later, I learned that each European country has a Data Protection Authority (DPA) who is responsible for, among other duties, conducting investigations on security issues that can lead to disclosure of [PII](https://en.wikipedia.org/wiki/Personally_identifiable_information). The flaws I had found followed every requirement, which meant I was able to ask the Portuguese DPA, [CNPD](https://www.cnpd.pt), to evaluate the case.

One month and a half later I got a call confirming I could move forward with a complaint, which I promptly did.

{% include image.html path="sns-1/cnpd-report.png"
   alt="CNPD Report page." caption-no="5" caption="CNPD Report page."
%}


### Maybe the GDPR will Help

After submitting the complaint, I went back to my only reliable contact. Seeing that no update had been given since my last interaction, I asked for a direct address to the security team to ease things up. Unfortunately, I got no response to that message and the following one. Time to try something different.

During 2017, I participated in an entrepreneurship competition hosted by Microsoft Portugal - [Microsoft OneMind](https://www.microsoft.com/pt-pt/windowsestudantes/educacao.aspx). As a prize for winning the challenge, my team was awarded a 3-month internship at the Lisbon offices. I worked with a new regulation I hadn't previously heard about - the [GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/oj).

Security and privacy are two passions of mine so I was naturally bound to enjoy learning about GDPR's implications and the complex paradigm shift about to be felt by businesses. One thing that stood out the most from my interactions and research was that the ones aware of it were visibly scared, presumably by how most infographics highlighted the substantial fines in a thick font. It's almost as if they had PTSD.

{% include image.html path="sns-1/gdpr.png"
   alt="Portuguese Government bulletin on GDPR." caption-no="6" caption="Portuguese Government bulletin on GDPR."
%}

*This may help*, I thought. We were one week away from GDPR's D-Day - May 25th. The regulation was clear, so I opened a new ticket with SPMS detailing the report timeline and informing them that I intended to publish the flaws right after GDPR came into effect if I didn't get a meaningful response back.

I got a response afterwards and provided, yet again, all the details. Since then, one minor flaw has been fixed and the major one can't be exploited.


### Maybe Public Visibility will Help

We are now 3 days away from a **full year of waiting**. At this precise moment, all my SNS/SPMS tickets are either closed without having been properly addressed, or left to rot in a backlog.

Two weeks ago I called the CNPD for a status update on my complaint and was asked to submit a new one - **they couldn't find it** following a migration to their new post-GDPR report system!

All my attempts to get the vulnerabilities fixed have failed, and I've exhausted my options. Since the authentication mechanism through which the worst vulnerability could be exploited is currently broken, I have decided to release this information.

Unlike a common industry practice of waiting just a few months before doing a full disclosure, I gave it 1 year. In retrospective, perhaps that was a naive decision, but I felt I'd be doing a disservice to the same people I wanted to help if I published it.


### Technical Details

The second part of this disclosure will detail every flaw. I'll update this one with a link once it's published.

**Maybe there will be no need for another *Maybe*...**


### Timeline

| Date                    | Activity
|-------------------------|------------------------------------------------------------------------------
| 2017-07-17              | Contacted the SPMS at `secretariado@spms.min-saude.pt`.
| 2017-07-20              | Contacted the support line. Opened a new ticket with `servicedesk@spms.min-saude.pt`.
| 2017-07-20 - 2017-08-01 | Contacted the support line multiple times.
| 2017-08-01              | Ticket labeled as "urgent".
| 2017-08-11              | Reversed the Android app, found 2 personal emails and contacted them both.
| 2017-08-15              | Contacted the SPMS at `nma@spms.min-saude.pt`.
| 2017-08-16              | Got a response from one of the personal emails requesting vulnerability details.
| 2017-08-16              | Provided complete details to SNS.
| 2017-08-16              | SNS acknowledges the report. Details sent to the security team.
| 2018-01-02              | Requested a status update.
| 2018-01-03              | SNS says the security team should be working on it. Contact doesn't have any update, however.
| 2018-01-15              | Contacted the Portuguese Data Protection Authority.
| 2018-02-04              | Requested a direct contact to the security team of SNS.
| 2018-03-02 - 2018-03-04 | Major service maintenance. All exploits still working.
| 2018-03-04              | Filled a complaint to the Portuguese Data Protection Authority.
| 2018-04-10              | Requested a status update.
| 2018-05-14              | Contacted the support line. Opened a new ticket with `servicedesk@spms.min-saude.pt`. Informed SNS that I intended to publish a full disclosure when GDPR came into effect.
| 2018-05-14 - 2018-06-22 | SNS fixes the DOM Based XSS (HTTP GET).
| 2018-06-22              | Downtime for auth flow improvements. Major authentication flaw doesn't seem exploitable anymore.
| 2018-06-25              | Contacted the Portuguese Data Protection Authority to get a status update.
| 2018-07-14              | Public disclosure.
