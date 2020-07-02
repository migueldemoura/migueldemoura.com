---
layout: post
title: "Making the Cloudflare WAF 40% faster"
description: "Part 2/2 - Arbitrary Account Takeover, PII Leaks (NIF + Phone Number), Reflected XSS"
thumb_image: "finance-tax-portal-2/main.png"
external: true
tags: [security, performance]
---

> **Part 2/2** of the [Portuguese Finance & Tax Portal](https://www.portaldasfinancas.gov.pt) security disclosure.
> Reading the [first part]({{ '/posts/deeply-vulnerable-legacy-code-portuguese-government-finance-tax-portal' | relative_url }}) is recommended.
>
> **Summary**: I found a very serious vulnerability in the Portuguese Government's Finance & Tax Portal which allowed anyone to access, in just a couple of seconds, any citizen's account. Corporations and any other entity with a tax number were also affected. A video demonstration is included at the end of the article.

In this post I will take a look at the [Portuguese Finance Portal Central Authentication System](https://www.acesso.gov.pt), specifically at the most common authentication method - tax number (NIF) and password.

Like the previous post, please note this isn't an extensive analysis of the authentication system. It is clear to me that with more time and perhaps access to the source code, I would find a lot more design and logic flaws. I also didn't include account DOS vulnerabilities or most bruteforce attacks.

{% include image.html path="finance-tax-portal-2/main.png"
   alt="Main authentication page." caption-no="1" caption="Main authentication page."
%}


## NIF Account Status Enumeration

Clicking the `Novo Utilizador` (New user) link in the first figure will redirect the user to the following page:

{% include image.html path="finance-tax-portal-2/new-user.png"
   alt="New user page." caption-no="2" caption="New user page."
%}

If we input a valid NIF and random values for all other fields and then submit the form, we can get one of two results:

* Some data field is incorrect or doesn't correspond to the information the Government has on record
* NIF is already registered

The submit request is:

``` shell
curl -X POST \
  https://www.acesso.gov.pt/unauthed/novoUtilizadorForm \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'cookie: autentica_JSessionID=VALID_SESSION' \
  -d 'nif=VALID_NIF&partID=PFAP&_csrf=VALID_XSRF_TOKEN'
```

And the second message looks like this:

{% include image.html path="finance-tax-portal-2/accountstatus.png"
   alt="NIF is already registered." caption-no="3" caption="NIF is already registered."
%}

By parsing the HTML response and repeating the request for every valid NIF, it is possible to obtain a list of all registered NIFs.


## NIF + Partial Phone Number & Account Data Enumeration

Now let's go back to the initial page and through with the reset password flow. Clicking the `Recuperar senha` (Recover password) link will redirect the user to the following page:

{% include image.html path="finance-tax-portal-2/recover-password.png"
   alt="Recover password page." caption-no="4" caption="Recover password page - Step 1."
%}

After typing 9 digits on the NIF field, a XHR is sent so the website can get more information regarding the provided value, and to show the next step.

The request in question is the following:

``` shell
curl -X POST \
  https://www.acesso.gov.pt/unauthed/verificarNif \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'cookie: autentica_JSessionID=VALID_SESSION' \
  -d 'nif=NIF&partID=PFAP&_csrf=VALID_XSRF_TOKEN'
```

The response always has the same format, and in case the provided NIF has a phone number associated, the JSON field `phoneNumber` will contain the last 3 digits:

``` javascript
{
  "isSuspendedUser": "false",
  "phoneNumber": "******123",
  "isCanceledUser": "false"
}
```

{% include image.html path="finance-tax-portal-2/accountdata-partial-phone.png"
   alt="NIF with phone number associated." caption-no="5" caption="NIF with phone number associated."
%}

This endpoint does not have any access or bruteforce restrictions, only a valid session and XSRF token are required (and can be reused during the attack). Therefore, it is possible to enumerate the response data for all valid NIFs.


## NIF + Phone Number Enumeration & Security Question Bypass (+ Bonus XSS)

The next field one must fill in is the loathed security question. "Loathed" because it is a deeply flawed piece of security apparatus that should have been eradicated long ago. Not only is it insecure, but I will show how it is essentially useless in this case (granted, not due to its nature per se, but I digress).

When submitting the above form, the following request is sent:

``` shell
curl -X POST \
  https://www.acesso.gov.pt/unauthed/inserirCodigoForm \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'cookie: autentica_JSessionID=VALID_SESSION' \
  -d 'nif=NIF&partID=PFAP&recoveryMode=sms&phone=PHONE_NUMBER&page=recoverPassword&questionID=QUESTION_ID&answer=QUESTION_ANSWER&_csrf=VALID_XSRF_TOKEN'
```

After messing around with the request, I found that by adding random characters to the `page` parameter, it wouldn't validate the security question or the phone number and jump straight into the next step (Wild bonus XSS appears: the parameters `answer` and `phone` are also injectable).

One example of such request is:

``` shell
curl -X POST \
  https://www.acesso.gov.pt/unauthed/inserirCodigoForm \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'cookie: autentica_JSessionID=VALID_SESSION' \
  -d 'nif=NIF&partID=PFAP&recoveryMode=sms&page=recoverPassword"&_csrf=VALID_XSRF_TOKEN'
```

Notice the quote at the end of the parameter. This seems to trigger some state mutation that skips the data checks. Any value that isn't `recoverPassword` will work. I'm willing to guess this is a case of not following the "Fail securely" principle.

Not only did we bypass the security question, but we also managed to get all digits of the associated phone number, readily displayed in the next step.

{% include image.html path="finance-tax-portal-2/full-phone.png"
   alt="Phone number associated with provided NIF." caption-no="6" caption="Phone number associated with provided NIF."
%}


## Arbitrary Account Takeover via NIF

The final flaw is the worst of the bunch. Essentially, it allows an attacker to change the password of any account knowing just its NIF.

If we complete the previous recovery steps with our own NIF, we will get back to the page that asks for the SMS code that was sent to our phone number. Entering those 6 digits and submitting the form will get us to the final step.

The submit request is:

``` shell
curl -X POST \
  https://www.acesso.gov.pt/alterarSenhaForm \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'cookie: autentica_JSessionID=VALID_SESSION' \
  -d 'nif=NIF&partID=PFAP&smsCode=SMS_CODE&phone=PHONE&page=insertCode&_csrf=VALID_XSRF_TOKEN'
```

I fuzzed those parameters, but wasn't able to bypass the need for a valid SMS code. It seems that they check the `nif`+`smsCode` pair, so you always need to provide it.

The need to send a `NIF` parameter with the request is also a bad sign, since it hints at the possibility that session flow mechanisms aren't being used properly.

The change password page is the following:

{% include image.html path="finance-tax-portal-2/change-password.png"
   alt="Change password page." caption-no="7" caption="Change password page."
%}

For some reason, the previous request logs the user in, which may open some other attack vectors.

Finally, and after choosing a new password, the user can click submit. The associated request is:

``` shell
curl -X POST \
  https://www.acesso.gov.pt/alterarSenhaForm \
  -H 'content-type: application/x-www-form-urlencoded' \
  -H 'cookie: autentica_JSessionID=VALID_SESSION' \
  -d 'nif=NIF&partID=PFAP&changePassword=on&newPassword=NEW_PASSWORD&newPasswordConfirmation=NEW_PASSWORD&recoverPassword=true&submitButton=Alterar&_csrf=VALID_XSRF_TOKEN'
```

Since we've hit the end of the flow, it is pretty obvious that the flaw lies on that last request. And in case you've guessed what the flaw is but you're thinking that there is no way that such mistake was made, you're wrong. **By modifying the `nif` parameter we're able to change the account password of any NIF**.

`Don't trust user input` strikes again. Just changing 9 digits allows anyone to **access any of millions of accounts, from individual citizens, to any kind of entity with a tax number**. The target doesn't even need to have a phone number associated with the account. It also works when the account is suspended after the maximum number of password attempts has been reached.

I also attempted this with the `change password` page inside the account, but changing the NIF on that form wouldn't work as a HTTP 400 is returned.

To get a grip of how trivial this is, take a look at the 27-second demonstration below:

{% include video.html path="finance-tax-portal-2/demo.mp4" frame="finance-tax-portal-2/demo.png"
   alt="Attack demonstration."
%}

The demo is structured as follows:

1. Try to access the target NIF account (`600084779`) with a random password (`migueldemoura`) - **Failure**
2. Start proof of concept (PoC), enter target NIF (`600084779`) and new password (`migueldemoura`)
3. SMS code is sent to the attacker's phone
4. Insert received SMS code, changing target NIF account's password
5. Try to access the target account with the same credentials (`migueldemoura`) - **Success**

The Python PoC/exploit used is only ~100 lines, and simply executes these requests. The demo browser contains one [userscript](https://github.com/migueldemoura/migueldemoura.com/tree/master/_pocs/finance-tax-portal-2/userscript.js) that swaps my NIF and name with the Portuguese entity responsible for the Finance Portal.


## Timeline

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
| 2018-08-17              | Public disclosure (Part 2/2).
