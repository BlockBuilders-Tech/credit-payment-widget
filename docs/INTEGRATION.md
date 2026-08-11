# BlockBuilders Checkout — Web Plugin Integration

**Widget version 1.2.0**

After creating a payment request, launch the checkout on the client side.

**There is one integration mode: embedded.** The checkout runs in an iframe on
your page, and reports the outcome to your callbacks. That does not change.

`redirectUrl` is optional and answers exactly one question — **whose success
screen the customer sees when the payment is done.**

| | Without `redirectUrl` | With `redirectUrl` |
|---|---|---|
| Where checkout runs | iframe on your page | iframe on your page |
| Callbacks fire | yes | yes |
| At the end the customer sees | the gateway's receipt | **your page** |
| Outcome on your URL, signed | — | yes |

So adding `redirectUrl` is not switching modes. It replaces our success screen
with yours, and puts the outcome on that page's URL, signed, so your server can
verify it.

The gateway does not follow the URL itself — it runs in the iframe, and going
there from inside would load your success page in a frame. It hands the URL up
and the widget navigates your page. You do not have to do anything for this;
it is what `PaymentWidget.init` already does.

## 1. Script URL

```html
<script src="https://portaltest.qredit.tech/sdk/payment-widget.min.js"></script>
```

Every release is also kept at a pinned path, which never changes once
published:

```html
<script src="https://portaltest.qredit.tech/sdk/v1.2.0/payment-widget.min.js"></script>
```

Pin in production. The unpinned path is updated in place when we release, so a
pinned URL is what protects you from a change you did not plan for.

> The widget is served from our own infrastructure. Earlier documentation
> pointed at a jsDelivr URL (`cdn.jsdelivr.net/gh/BlockBuilders-Tech/…@v1.0.9`).
> That path is no longer maintained — move to the URLs above.

---

## 2. Embedded mode

```html
<div id="payment-widget"></div>
<script src="https://portaltest.qredit.tech/sdk/v1.2.0/payment-widget.min.js"></script>
<script>
  PaymentWidget.init({
    containerId: 'payment-widget',
    ereference:  'NjY1NzM3OTJATVRReQ',
    token:       'YOUR_ACCESS_TOKEN',
    url:         'https://merchant.example.com/api/sign-payment',
    lang:        'en',

    onSuccess: function (data) {
      PaymentWidget.destroy();
      window.location.href = '/order/confirmed?ref=' + data.reference;
    },
    onCancel:  function (data) { PaymentWidget.destroy(); window.location.href = '/cart'; },
    onFail:    function (data) { alert(data.message || 'Payment failed'); },
    onPending: function (data) { /* persist data.reference for reconciliation */ }
  });
</script>
```

### Configuration

| Field | Required | Description |
|---|---|---|
| `containerId` | yes | ID of the element to mount the iframe in |
| `ereference` | yes | Payment request reference |
| `token` | yes | Merchant access token |
| `url` | yes | Your **signing endpoint** — see §4 |
| `redirectUrl` | no | Send the customer here when the payment finishes, instead of showing the gateway's receipt — see §3 |
| `lang` | no | `en` (default) or `ar` |
| `width` | no | iframe width, default `100%` |
| `height` | no | iframe height, default `1000px` |
| `border` | no | iframe CSS border, default `none` |
| `serverUrl` | no | Point at a different gateway deployment |
| `onLoad` | no | Iframe finished loading |
| `onSuccess` | no | Payment authorised and captured |
| `onCancel` | no | Customer cancelled |
| `onFail` | no | Payment attempted and rejected |
| `onPending` | no | Awaiting asynchronous bank settlement |
| `onError` | no | Catch-all: iframe load failures **and** payment failures |

### Callback payload

```js
{
  status:         'success' | 'cancel' | 'error' | 'pending',
  reference:      'NjY1NzM3OTJATVRReQ',
  orderReference: 'ORD_456',
  transactionId:  'TXN_789',
  amount:         '100.00',
  currency:       'USD',
  message:        'Payment completed successfully',
  timestamp:      '2026-05-13T10:30:00Z',
  data:           { … }        // raw processor response, when available
}
```

Fields may be absent depending on channel and status — check before reading.

### When `onSuccess` fires

**The customer decides.** After a successful payment the gateway shows its
receipt inside the iframe, and `onSuccess` fires when they press **Finish**.

> Earlier documentation said the widget waited about five seconds and then
> fired automatically. That timer has been removed: a receipt that hands itself
> back on a stopwatch takes the page away from someone still reading it. There
> is no fixed delay to work around any more, so the `setTimeout` workaround
> that used to be recommended is no longer needed.

`onSuccess` also fires if the iframe is torn down before Finish is pressed, so a
completed payment is never silently dropped.

### Callbacks and what to do

| Callback | Fires when | Recommended action |
|---|---|---|
| `onSuccess` | Payment authorised and captured | Destroy the widget, go to your thank-you page |
| `onCancel` | Customer cancelled | Destroy the widget, return them to the cart |
| `onFail` | Attempted and rejected | Show the error. **Do not destroy** — let them retry |
| `onPending` | Awaiting settlement | Persist the reference. **Do not destroy** |
| `onError` | Iframe failed to load, or payment failed | Log and report |
| `onLoad` | Iframe loaded | Hide your own spinner |

---

## 3. Sending the customer to your own success page

Add `redirectUrl` to the same `init` call. Nothing else changes.

```js
PaymentWidget.init({
  containerId: 'payment-widget',
  ereference:  'NjY1NzM3OTJATVRReQ',
  token:       'YOUR_ACCESS_TOKEN',
  url:         'https://merchant.example.com/api/sign-payment',
  redirectUrl: '/payment/return',        // relative is fine

  onSuccess: function (data) { /* still fires, just before we leave */ }
});
```

When the payment finishes, the widget tears the iframe down and navigates your
page to `redirectUrl` with the outcome appended and signed. Your callbacks
still fire first, so anything you need to record client-side still runs.

On the page `redirectUrl` points at:

```js
// Take the verification payload BEFORE handleReturn — it cleans the URL.
var verification = PaymentWidget.getVerification();

PaymentWidget.handleReturn({
  onSuccess: function (data) { … },
  onCancel:  function (data) { … },
  onFail:    function (data) { … },
  onPending: function (data) { … }
});

if (verification) {
  fetch('/api/verify-payment', {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify(verification)
  });
}
```

`handleReturn` strips our parameters from the address bar afterwards, so a
refresh cannot re-fire your callbacks and the outcome does not sit in a URL the
customer might share. Your own query parameters are left alone.

If your app uses hash routing, include the hash (`/#/payment/return`). We append
the query **before** the fragment, so both `location.search` and your router
work.

`redirectUrl` must be `http(s)`. A relative path is resolved against the page
that called `init`. Anything else is rejected immediately, because the customer
is handed to this value at the end of a payment.

> `PaymentWidget.redirect()` and `buildUrl()` still exist for the older
> full-page flow and are unchanged. New integrations do not need them — pass
> `redirectUrl` to `init` instead.

## 4. Signatures — how they work

### The idea

**We never hold your signing key.** You do.

`url` in the configuration is *your* signing endpoint. When the gateway needs a
signature it builds a string from the payment values, sends that string to your
endpoint, and your server returns the HMAC. The key stays on your side the whole
time.

So verification is simply: **we send you the values and the signature we got
from you. You rebuild the string the same way, sign it again, and compare.** If
the two match, the values were not altered on the way back.

```
   ┌──────────┐   1. string to sign    ┌────────────────────┐
   │ Gateway  │ ─────────────────────► │ Your /sign endpoint│
   │          │ ◄───────────────────── │  (holds the key)   │
   └────┬─────┘   2. signature         └────────────────────┘
        │
        │ 3. redirect: values + signature
        ▼
   ┌────────────────────┐   4. rebuild the string, sign it again,
   │ Your return page   │      compare with the signature received
   └────────────────────┘
```

### What is signed

Seven parameters. **The same seven for every payment channel and every
outcome** — cards, Sadad Gate, e-SADAD, QR; success, pending, cancel, error:

```
status, reference, orderReference, transactionId, amount, currency, timestamp
```

A value that does not apply — a channel with no bank transaction id, a
cancellation with no amount — arrives as an **empty parameter, not a missing
one**. The shape never changes, so you write one verifier and it holds
everywhere.

The redirect also carries:

| Parameter | Signed | Meaning |
|---|---|---|
| `signedFields` | no | Comma-separated list of the parameters above |
| `signature` | no | The signature over them |
| `message` | **no** | Display wording only |

`message` is not signed and must not be trusted. Neither are any parameters
your own `redirectUrl` already carried — those are passed through untouched.

Order lines are not sent on the redirect. They vary in length, which would make
the signed body a different size for every order. Read the order from our API by
`reference`.

### The algorithm

```
1. Take the values of the parameters named in `signedFields`.
2. Add your merchant token.
3. Drop every empty value.
4. Sort the remaining values lexicographically (ordinal / code-unit order,
   NOT locale-aware).
5. Join them with no separator.
6. HMAC-SHA512 with your signing key.
7. Compare with `signature`.
```

Two details that decide whether your implementation matches ours:

- **Values only, not `key=value` pairs.** Only the values go into the string.
- **Ordinal sort.** Use a plain byte/code-unit comparison. A locale-aware sort
  (`localeCompare`, `Collator`, some `ORDER BY` collations) will order strings
  differently and produce a signature that never matches.

This is the same convention the gateway already uses to sign its API calls to
you, so an existing signing implementation works unchanged.

### Server-side verification

```js
// Node.js
const crypto = require('crypto');

function verify({ signature, signedFields, signed }, token, secret) {
  const parts = signedFields
    .map(f => String(signed[f] ?? ''))
    .filter(v => v !== '')
    .concat(token)
    .sort();                                   // ordinal by default in JS

  const expected = crypto
    .createHmac('sha512', secret)
    .update(parts.join(''))
    .digest('hex');

  // Constant-time compare: a plain === leaks timing information.
  const a = Buffer.from(expected, 'utf8');
  const b = Buffer.from(String(signature), 'utf8');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}
```

```php
<?php // PHP
function verify(array $payload, string $token, string $secret): bool {
    $parts = [];
    foreach ($payload['signedFields'] as $f) {
        $v = (string)($payload['signed'][$f] ?? '');
        if ($v !== '') { $parts[] = $v; }
    }
    $parts[] = $token;
    sort($parts, SORT_STRING);                  // SORT_STRING = ordinal
    $expected = hash_hmac('sha512', implode('', $parts), $secret);
    return hash_equals($expected, (string)$payload['signature']);
}
```

### A signature is not proof of payment

It proves the values reached you unaltered. It does not prove the payment
settled. Before releasing goods:

1. Verify the signature.
2. **Look the payment up through our API by `reference`** and act on what the
   API says.

The convention hashes values rather than key/value pairs, so it proves the
*set* of values came from us — not which field each one belongs to. Checking
the values against your own order record closes that gap, and you have the
record already.

### If `signature` is missing

A redirect can arrive unsigned when your signing endpoint was unreachable at the
moment the payment completed. The customer is still returned — the payment
already happened, and stranding them protects nobody.

`PaymentWidget.getVerification()` returns `null` in that case. Treat the result
as **untrusted** and fall back to the API lookup. Never accept an unsigned
redirect just because it arrived.

### Callbacks are never signed — only the URL is

The `postMessage` payload that reaches your callbacks carries **no signature**,
and it cannot: anyone with DevTools can call your `onSuccess` by hand.

The signature exists only on the `redirectUrl` you are sent to, which is why
that is the one worth verifying. Without `redirectUrl` there is nothing signed
to check, and your only verification is the API lookup.

Either way, browser callbacks are **UX only**. Confirm every payment
server-side by `reference` before fulfilling an order.

---

## 5. Methods

| Method | Description |
|---|---|
| `PaymentWidget.init(config)` | Mount the iframe. Calling again tears down the previous instance |
| `PaymentWidget.destroy()` | Remove the iframe and its listener |
| `PaymentWidget.redirect(config)` | Leave the page for the hosted checkout |
| `PaymentWidget.buildUrl(config)` | The redirect URL, without navigating |
| `PaymentWidget.readResult([opts])` | Parse the return URL; `null` if there is no result |
| `PaymentWidget.getVerification([opts])` | `{ signature, signedFields, signed }` for your backend, or `null` |
| `PaymentWidget.handleReturn(config)` | Read, dispatch to callbacks, and clean the URL |
| `PaymentWidget.clearResult()` | Remove our parameters from the address bar |
| `PaymentWidget.version` | Loaded version string, e.g. `'1.2.0'` |

---

## 6. Upgrading

### From 1.1.x to 1.2.0

- Redirect results are now signed. Add the server-side check in §4.
- `readResult()` gained `signature`, `signedFields` and `signed`.
- `getVerification()` is new.
- `clearResult()` now also removes `signature` and `signedFields`, which 1.1.0
  left behind in the address bar.
- Order lines are no longer sent on the redirect — read the order from the API.
- Nothing was removed and no callback changed shape. Existing integrations keep
  working; they simply do not verify anything until you add §4.

### From 1.0.x

- Change the script URL to the self-hosted one in §1.
- Rename `reference` to `ereference`.
- Add `onSuccess` / `onCancel` / `onFail` / `onPending`. In 1.0.1 the
  integration ended once the widget loaded.
- Call `PaymentWidget.destroy()` when navigating away or re-initialising.
- Remove any `setTimeout` added to work around the old five-second delay before
  `onSuccess` — there is no delay now.

---

## 7. Security checklist

- Serve your checkout page over **HTTPS** in production.
- Keep the signing key on your server. It must never appear in browser code.
- Verify the signature on redirect returns, and **look the payment up through
  our API before releasing goods** — in both modes.
- Treat `message` and any unsigned parameter as display text.
- Use a constant-time comparison for signatures.
- We deliberately do not put the payer's name, email or phone on the redirect
  URL. Query strings are recorded in browser history, proxy and server access
  logs, and the `Referer` header sent to third-party scripts on your page. Read
  customer details from the API instead.
