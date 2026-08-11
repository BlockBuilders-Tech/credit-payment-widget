# 5.1 Web Plugin

After creating a payment request successfully, the merchant can launch the
BlockBuilders Checkout Web Plugin on the client side.

The checkout runs inside an iframe on your page and reports the payment outcome
to your callbacks. Optionally, the customer can land on your own success page at
the end instead of the gateway's receipt — see
[Returning to your own page](#returning-to-your-own-page).

**Widget version:** 1.2.0

## Client-side integration flow

1. Include the hosted widget script in your page.
2. Add a container element where the checkout iframe will be rendered.
3. Call `PaymentWidget.init(...)` with the required configuration.
4. Register the callbacks (`onSuccess`, `onCancel`, `onFail`, `onPending`) to
   handle the payment outcome.
5. The widget loads the hosted checkout page inside an iframe.

## Script URL

```html
<script src="https://portaltest.qredit.tech/sdk/payment-widget.min.js"></script>
```

This path always serves the current version. Updates are published to it
directly, so no change is needed on your side when a new version is released.

## Configuration fields

| Field | Required | Description |
|---|---|---|
| `containerId` | Yes | The HTML container element ID |
| `ereference` | Yes | Payment request reference |
| `token` | Yes | Merchant access/auth token |
| `url` | Yes | Merchant signing endpoint URL |
| `redirectUrl` | No | Send the customer to this page when the payment finishes, instead of showing the gateway's receipt |
| `lang` | No | UI language, default is `en` (`en` or `ar`) |
| `width` | No | iframe width, default `100%` |
| `height` | No | iframe height, default `1000px` |
| `border` | No | iframe CSS border, default `none` |
| `onLoad` | No | Fires once when the iframe has finished loading |
| `onSuccess` | No | Fires on successful payment |
| `onCancel` | No | Fires when the customer cancels |
| `onFail` | No | Fires on payment failure |
| `onPending` | No | Fires when the payment is awaiting async settlement |
| `onError` | No | Catch-all (iframe load failures + payment failures) |

## Callback payload

Every callback (except `onLoad`, and the iframe-load-failure case of `onError`)
receives a single `data` argument:

```js
{
  status:         'success' | 'cancel' | 'error' | 'pending',
  reference:      'NjY1NzM3OTJATVRReQ',     // your ereference, echoed back
  orderReference: 'ORD_456',                // your order reference, if set
  transactionId:  'TXN_789',                // BlockBuilders transaction id
  amount:         '100.00',
  currency:       'USD',
  message:        'Payment completed successfully',
  timestamp:      '2026-05-13T10:30:00Z'    // ISO 8601 UTC
}
```

Some fields may be absent depending on payment method and status — always check
before reading.

## Callback descriptions

| Callback | Fires when | Recommended action |
|---|---|---|
| `onSuccess` | Payment authorized and captured | Destroy the widget, navigate to your thank-you page |
| `onCancel` | Customer cancelled or closed the payment flow | Destroy the widget, return the customer to their cart |
| `onFail` | Payment was attempted but rejected (declined, etc.) | Show an error message; do not destroy — let them retry |
| `onPending` | Payment is awaiting async bank settlement | Persist `transactionId`; do not destroy — the gateway is still showing the customer a "processing" screen |
| `onError` | Iframe failed to load, or a payment failed | Log and report. For payment failures, `data` has the same shape as `onFail` |
| `onLoad` | iframe has finished loading | Hide your own loading spinner, if any |

`onSuccess` fires when the customer presses **Finish** on the gateway's receipt
screen, or immediately if you supplied a `redirectUrl`. It also fires if the
iframe is removed before then, so a completed payment is never lost.

**Important:** browser callbacks are for UX only. Before fulfilling an order,
your backend must verify the payment by looking up `data.reference` against the
BlockBuilders API. Anyone with browser DevTools can fake an `onSuccess` call —
never grant value based on the callback alone.

## Methods

| Method | Description |
|---|---|
| `PaymentWidget.init(config)` | Mounts the iframe and registers callbacks. Calling again automatically tears down the previous instance |
| `PaymentWidget.destroy()` | Removes the iframe and cleans up the event listener. Call this when navigating away |
| `PaymentWidget.readResult()` | On your return page: parses the payment result from the URL, or `null` |
| `PaymentWidget.getVerification()` | On your return page: returns `{ signature, signedFields, signed }` to send to your backend, or `null` |
| `PaymentWidget.handleReturn(config)` | On your return page: reads the result, dispatches it to your callbacks, and clears the URL |
| `PaymentWidget.clearResult()` | Removes the gateway's parameters from the address bar |
| `PaymentWidget.version` | The currently loaded version string (e.g. `'1.2.0'`) |

## Example HTML integration

```html
<div id="payment-widget"></div>
<script src="https://portaltest.qredit.tech/sdk/payment-widget.min.js"></script>
<script>
  PaymentWidget.init({
    containerId: 'payment-widget',
    ereference:  'NjY1NzM3OTJATVRReQ',
    token:       'YOUR_ACCESS_TOKEN',
    url:         'https://merchant.example.com/api/sign-payment',
    lang:        'en',
    width:       '100%',
    height:      '100vh',

    onSuccess: function (data) {
      console.log('Paid:', data);
      PaymentWidget.destroy();
      window.location.href = '/order/confirmed?ref=' + data.orderReference;
    },

    onCancel: function (data) {
      console.log('Cancelled:', data);
      PaymentWidget.destroy();
      window.location.href = '/cart';
    },

    onFail: function (data) {
      console.log('Failed:', data);
      alert('Payment failed: ' + (data.message || 'please try again'));
      // No destroy() — let the customer retry inside the same iframe.
    },

    onPending: function (data) {
      console.log('Pending settlement:', data);
      // Persist transactionId for backend reconciliation.
    }
  });
</script>
```

---

## Returning to your own page

By default the gateway shows its own receipt when the payment completes. To send
the customer to your page instead, add `redirectUrl` to the same `init` call.

```js
PaymentWidget.init({
  containerId: 'payment-widget',
  ereference:  'NjY1NzM3OTJATVRReQ',
  token:       'YOUR_ACCESS_TOKEN',
  url:         'https://merchant.example.com/api/sign-payment',
  redirectUrl: '/payment/return',

  onSuccess: function (data) { /* still fires */ }
});
```

The checkout still runs in the iframe and your callbacks still fire. When the
payment finishes, the widget removes the iframe and navigates your page to
`redirectUrl`, with the payment result appended as query parameters and signed.

`redirectUrl` must be an `http(s)` URL. A relative path is resolved against the
page that called `init`. If your application uses hash routing, include the hash
(`/#/payment/return`) — the result is appended before the fragment, so both
`location.search` and your router work.

### On your return page

```js
// Read the verification payload before handleReturn, which clears the URL.
var verification = PaymentWidget.getVerification();

PaymentWidget.handleReturn({
  onSuccess: function (data) { /* ... */ },
  onCancel:  function (data) { /* ... */ },
  onFail:    function (data) { /* ... */ },
  onPending: function (data) { /* ... */ }
});

if (verification) {
  fetch('/api/verify-payment', {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify(verification)
  });
}
```

`handleReturn` removes the gateway's parameters from the address bar afterwards,
so refreshing the page does not re-fire your callbacks. Your own query
parameters are left untouched.

---

## Signature and verification

### How it works

The signing key is yours and stays on your server. The `url` field in the
configuration is your own signing endpoint.

1. When the payment completes, the gateway builds a string from the payment
   values.
2. It sends that string to your signing endpoint, which returns an HMAC.
3. It appends the values and that signature to your `redirectUrl`.
4. Your server rebuilds the string from the values it received, signs it again,
   and compares the two signatures.

If they match, the values were not altered in transit.

### What is signed

Seven parameters, the same for every payment channel and every outcome:

```
status, reference, orderReference, transactionId, amount, currency, timestamp
```

A value that does not apply — for example a channel with no bank transaction id,
or a cancellation with no amount — arrives as an empty parameter rather than a
missing one. The set never changes, so a single verification routine covers all
cases.

The URL also carries:

| Parameter | Signed | Description |
|---|---|---|
| `signedFields` | No | Comma-separated list of the signed parameter names |
| `signature` | No | The signature over those parameters |
| `message` | No | Display text only |

Any parameters your own `redirectUrl` already contained are passed through
untouched and are not part of the signature.

Order lines are not included on the URL. Read the order from the API using
`reference`.

### Verification algorithm

1. Take the values of the parameters named in `signedFields`.
2. Add your merchant token.
3. Drop every empty value.
4. Sort the remaining values lexicographically, using ordinal (byte or code
   unit) comparison — not a locale-aware sort.
5. Join them with no separator.
6. HMAC-SHA512 with your signing key.
7. Compare the result with `signature`.

Two points determine whether your implementation matches:

- Only the **values** are hashed, not `key=value` pairs.
- The sort must be **ordinal**. A locale-aware sort such as `localeCompare`,
  `Intl.Collator`, or a database collation orders the values differently and
  produces a signature that never matches.

This is the same signing convention used for API requests, so an existing
implementation works unchanged.

### Server-side verification

**Node.js**

```js
const crypto = require('crypto');

function verify({ signature, signedFields, signed }, token, secret) {
  const parts = signedFields
    .map(f => String(signed[f] ?? ''))
    .filter(v => v !== '')
    .concat(token)
    .sort();

  const expected = crypto
    .createHmac('sha512', secret)
    .update(parts.join(''))
    .digest('hex');

  const a = Buffer.from(expected, 'utf8');
  const b = Buffer.from(String(signature), 'utf8');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}
```

**PHP**

```php
<?php
function verify(array $payload, string $token, string $secret): bool {
    $parts = [];
    foreach ($payload['signedFields'] as $f) {
        $v = (string)($payload['signed'][$f] ?? '');
        if ($v !== '') { $parts[] = $v; }
    }
    $parts[] = $token;
    sort($parts, SORT_STRING);
    $expected = hash_hmac('sha512', implode('', $parts), $secret);
    return hash_equals($expected, (string)$payload['signature']);
}
```

### If the signature is missing

If your signing endpoint is unreachable when the payment completes, the customer
is still returned to your page, but without a `signature` parameter.
`getVerification()` returns `null` in that case. Treat the result as unverified
and confirm the payment through the API.

### Verification is not confirmation

A valid signature proves the values reached you unaltered. It does not prove the
payment settled. Before releasing goods:

1. Verify the signature.
2. Look the payment up through the BlockBuilders API using `reference`, and act
   on what the API returns.

Because the convention hashes values rather than key/value pairs, it confirms
the set of values came from the gateway, but not which field each value belongs
to. Comparing the values against your own order record covers this.

---

## Upgrading from v1.0.9

1. Update the script URL to the one above.
2. If you were passing `reference`, rename it to `ereference`.
3. Add the callbacks (`onSuccess`, `onCancel`, `onFail`, `onPending`) to handle
   the payment outcome.
4. Add a `PaymentWidget.destroy()` call when you navigate away or re-initialize.
5. Optionally add `redirectUrl` and the verification step above.

Nothing was removed in 1.2.0 and no callback changed shape — existing
integrations continue to work.

## Notes

- The `url` parameter is the merchant signing API endpoint used by the plugin to
  generate request signatures.
- The signing key must remain on the merchant server side and must never be
  exposed in the browser.
- The hosted checkout page must be served over HTTPS in production.
- Verify the signature on your return page, and confirm every payment through
  the API before fulfilling an order.
- Use a constant-time comparison when checking signatures.
- The customer's name, email and phone are not included on the return URL. Query
  strings are recorded in browser history, server access logs, and the `Referer`
  header sent to third-party scripts. Read customer details from the API.
