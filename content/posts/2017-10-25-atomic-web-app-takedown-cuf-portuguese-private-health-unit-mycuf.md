+++
title = "Atomic Web App Takedown - CUF - Portuguese Private Health Unit (MyCUF)"
description = "Application DOS, Authenticated, Stored XSS and Email HTML Injection"
updated = "2024-12-29"
[extra]
thumb_image = "images/cuf/normal.png"
+++

> **Update**: A CUF representative reached out a few hours after publication and assured me that their team was quickly solving all issues. At the time of writing (28/10/2017), all vulnerabilities described in this disclosure have been fixed.

CUF is the largest private health unit in Portugal. It has strived to improve its technological offerings, mostly in the form of [MyCUF](https://www.saudecuf.pt/mycuf) - a web portal that allows for a quick glance at a patient's records and easy scheduling of appointments. Although not as a native app, it is also available on Android and iOS, following the model of reusing web code to run on mobile OSes.

{{ image(
    path="images/cuf/normal.png",
    alt="MyCUF homepage.",
    caption_no="1",
    caption="MyCUF homepage."
) }}

Unfortunately, such efforts lacked proper security auditing, resulting in several flaws that compromise the service.

### Questionable Design

After a first inspection, I registered an account with a random fiscal number and noticed that my session expired after refreshing the page, something I had to do given the slow loading times and the occasional freeze. Upon a quick verification, I noticed that the session data was stored in JavaScript objects, hence the reset upon reload.

I can see the argument for this approach as it should safeguard those less technical from prying eyes after forgetting to log out. It also makes XSRF attacks impossible and eliminates other cookie-related vectors. But one really has to wonder why there is no button to toggle this state, the common "remember me" option (guess what, there's a setting deep in the code to do exactly this - but it's disabled). I would argue that the terrible UX tradeoff isn't worth it.

### Application Denial of Service (DOS)

Now that we've established that the app is poorly designed, allow me to guide you through one of the worst design decisions in a web product that I've ever seen.

Right after opening up the page, the following XHR is sent:

``` sh
curl -X POST \
  https://www.saudecuf.pt/mycuf/gateway.aspx \
  -H 'content-type: text/plain' \
  -H 'more-control: |11.1708171500|1appVersion|110.3|1version|1login|1method|1process|1service|D4' \
  -d '|0|0|0|1deviceUUID|0|1encoder.compress|0|1encoder.maxsize|1STRIPPED||STRIPPED|1modelKey|1STRIPPED||||STRIPPED|1userAgent|11.1708171500|1appVersion|110.3|1version|STRIPPED|1key|314|1channel|10||true||3||10|1timezone|1en|1language|1vidaguest|1group|1vidamyapp|1orgunit|1vidacare|1password|1vidacare|1user|D15|L1|30|L4'
```

I stripped most headers and trimmed the data string to keep it compact. As you may have noticed, there's a user, `vidacare`, and password, `vidacare`, being sent via this request. These appear to be part of a guest group, `vidaguest`, which I'm guessing is the default account for non-logged-in users. I also noticed that without this request, the page wouldn't load. Effectively, they are authenticating a guest user client-side, providing its credentials (you can use them to log in as well), instead of doing so server-side and sending only the result to the client. They are going all in with the [SPA](https://en.wikipedia.org/wiki/Single-page_application) craze and forgot about the simple things.

At this point, and if we think alike, you're wondering whether there is a way to change the guest password and make the request fail, therefore locking the application.

Since the guest account has a limited control panel compared to the normal accounts, the first thing that occurred to me was to create a new normal account, go to the profile page and change its password. That way I'd get the request that executed such action and I could try to apply it to the guest account. Unfortunately that didn't work, and neither did any of the normal account requests, as would be expected. This is usually an effective attack method for many SPAs, though, as they hide functionality, rely on client-side verification and don't check requests to their APIs on their backends, failing the most important web security principle - **never trust the user**!

After that, I remembered that when creating the account a temporary password was sent to my email, and upon the first login, a password change was required.

{{ image(
    path="images/cuf/tmp-password.png",
    alt="Temporary password dialog.",
    caption_no="2",
    caption="Temporary password dialog."
) }}

Taking aside that this is bad practice (send a link instead and allow the user to define his own password), I realized that it could be used to **change my account's password without needing the current one**, as this request would succeed even after changing the temporary password. This is a flaw by itself, but it wasn't what caught my attention - by executing this request on the guest account, the password was changed - it worked! The following request performs the password change:

``` sh
curl -X POST \
  https://www.saudecuf.pt/mycuf/gateway.aspx \
  -H 'content-type: text/plain' \
  -H 'more-control: |51|1execute|11503244735955|1callId|1SESSION_TOKEN|1session|1executeFlow|1method|1process|1service|D5' \
  -d '|1vde915a2bb|1flow|0|1kernel|D2|0|50|1advertisementNotification|50|1emailNotification|50|1smsNotification|1NEW_PASSWORD|1confirmationPassword|1NEW_PASSWORD|1password|D5|1clientInfo|D1|L1|30|L4'
```

As a result, and since this code is used for both the web and app versions, it brought the whole service down, as can be seen, for example, in the web version below:

{{ image(
    path="images/cuf/dos.png",
    alt="Broken MyCUF homepage.",
    caption_no="3",
    caption="Broken MyCUF homepage."
) }}

Clicking the OK button would simply reload the page, resulting in an infinite loop of "User or password is invalid" errors.

I wasn't able to test this on the clinic/hospital's terminals, unfortunately. Since I'm not willing to provide my own info, I wasn't able to gather more information about the registration process either, which is an interesting vector to explore for privilege escalation vulnerabilities (further medical info is provided to those that validate their account ID card).

### Authenticated, Stored XSS

When creating the account, I entered the usual `'';!--"<XSS>=&{()}` on the name field, the only one that isn't properly checked, logged in, went to the profile page and found the XSS (code inserted in 2 locations). For obvious reasons, this bypasses the XSS auditors, though it isn't very interesting given how the sessions are handled. It can still be exploited, but with some added challenges.

{{ image(
    path="images/cuf/xss.png",
    alt="User account XSS example.",
    caption_no="4",
    caption="User account XSS example."
) }}

### Email HTML Injection

As the XSS, inserting HTML code on the name field will allow for code injection on all emails that output the patient name, like the account registration one, opening a path for successful phishing campaigns.

{{ image(
    path="images/cuf/email-html-injection.png",
    alt="Simple HTML injection example on a CUF email.",
    caption_no="5",
    caption="Simple HTML injection example on a CUF email."
) }}

### Final Thoughts

This disclosure comes after 3 months of trying to contact the above entity, reaching through and exhausting all methods of communication. I got no response to my emails/form fillings and when I approached staff at one of the hospitals, the same unresponsive addresses were given as the only means of reporting the issue. Since the vulnerabilities have trivial fixes and don't directly or easily expose user information, I decided to provide a full disclosure.
