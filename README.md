# Credit Payment Widget

A lightweight, secure payment widget plugin by **[BlockBuilders](https://blockbuilders.ps/)**.

---

## 🚀 Installation

Add the script to your HTML page:

```html
<script src="https://cdn.jsdelivr.net/gh/BlockBuilders-Tech/credit-payment-widget@1.0.0/dist/payment-widget.min.js"></script>
```

Or use the latest version:

```html
<script src="https://cdn.jsdelivr.net/gh/BlockBuilders-Tech/credit-payment-widget@latest/dist/payment-widget.min.js"></script>
```

---

## 📖 Quick Start

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Page</title>
  <style>
    #payment-widget {
      width: 100%;
      max-width: 600px;
      height: 700px;
      margin: 0 auto;
    }
  </style>
</head>
<body>

  <div id="payment-widget"></div>

  <script src="https://cdn.jsdelivr.net/gh/BlockBuilders-Tech/credit-payment-widget@1.0.0/dist/payment-widget.min.js"></script>
  <script>
    PaymentWidget.init({
      containerId: 'payment-widget',
      ereference: 'YOUR_REFERENCE',
      token: 'YOUR_TOKEN',
      lang: 'en'
    });
  </script>

</body>
</html>
```

---

## 🔀 Two Integration Modes

| | Embedded | Redirect |
|---|---|---|
| Method | `PaymentWidget.init()` | `PaymentWidget.redirect()` |
| Where checkout runs | iframe on your page | the gateway's own page |
| How you get the result | `onSuccess` / `onCancel` / `onFail` / `onPending` | query params on your `redirectUrl` |
| Your page navigates away | No | Yes |
| Best for | single-page checkouts | server-side confirmation |

Pick redirect mode when the outcome needs to reach your **backend** — the
gateway returns the browser to a URL you control, so your server sees it
without relying on JavaScript.

---

## ⚙️ Configuration Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `containerId` | string | ✅ Embedded only | - | ID of the HTML container element |
| `redirectUrl` | string | ✅ Redirect only | - | Where the gateway returns the browser after payment |
| `ereference` | string | ✅ Yes | `''` | Your payment reference code |
| `token` | string | ✅ Yes | `''` | Your authentication token |
| `url` | string | ✅ Yes | `''` | Your signing API base URL |
| `lang` | string | No | `'en'` | Language code (`'en'`, `'ar'`) |
| `width` | string | No | `'100%'` | Widget width (embedded only) |
| `height` | string | No | `'1000px'` | Widget height (embedded only) |
| `serverUrl` | string | No | production | Gateway deployment to target — set this to test against staging |

---

## 🔔 Callbacks

Both modes report through the **same four callbacks**, so you write one set of
handlers regardless of which you use:

| Callback | Fires when |
|---|---|
| `onSuccess(result)` | Payment completed |
| `onCancel(result)` | Payer backed out |
| `onFail(result)` | Payment failed or was declined |
| `onPending(result)` | Accepted, settling later (e-SADAD, QR) |
| `onLoad()` | Embedded only — the iframe finished loading |
| `onError(err)` | Embedded only — the iframe itself failed to load |

Every `result` has the same shape:

```js
{
  status:         'success' | 'cancel' | 'error' | 'pending',
  reference:      '87253018',
  orderReference: '9503319853',
  transactionId:  '0602MCC603474',
  amount:         '10.00',
  currency:       'ILS',
  message:        'Payment completed successfully',
  timestamp:      '2026-08-09T15:32:41.000Z'
}
```

`pending` is not a failure. e-SADAD and QR are completed in the payer's banking
app, so the gateway reports what it knows and the bank confirms later — treat it
as "awaiting settlement", not "declined".

---

## ↩️ How redirect mode works

Three steps, and the middle one happens on the gateway.

**1. Send the payer** — your page calls `redirect()`, the browser leaves your
site:

```javascript
PaymentWidget.redirect({
  ereference:  'YOUR_REFERENCE',
  token:       'YOUR_TOKEN',
  url:         'https://your-api.example.com',
  redirectUrl: 'https://your-shop.example.com/payment/complete',
  lang:        'en'
});
```

**2. They pay** on the gateway — cards, Sadad Gate, e-SADAD or QR.

**3. The gateway sends them back** to your `redirectUrl`, with the outcome
appended:

```
https://your-shop.example.com/payment/complete
    ?status=success&reference=87253018&orderReference=9503319853
    &transactionId=0602MCC603474&amount=10.00&currency=ILS
    &message=Payment%20completed%20successfully&timestamp=2026-08-09T15:32:41.000Z
```

On that page, call `handleReturn` and you get the same callbacks as embedded
mode:

```javascript
PaymentWidget.handleReturn({
  onSuccess: r => showReceipt(r.reference, r.transactionId),
  onCancel:  r => backToCart(),
  onFail:    r => showError(r.message),
  onPending: r => showAwaitingSettlement(r.reference)
});
```

It returns `null` when the URL carries no `status`, so it's safe to call on
every page load — a normal visit just gets `null`.

It also **strips the result parameters from the address bar** afterwards. Without
that, a refresh re-fires your callbacks and the outcome sits in a URL that can be
shared, bookmarked, or picked up by analytics. Pass `clean: false` to keep them.

### Just reading the values

```javascript
const result = PaymentWidget.readResult();
if (result && result.status === 'success') { /* … */ }
```

### Which mode to choose

| | Embedded | Redirect |
|---|---|---|
| Payer stays on your page | ✅ | ❌ |
| Result reaches your **server** | ❌ not directly | ✅ on the return URL |
| Survives the tab closing mid-payment | ❌ | ✅ |
| Works with strict CSP / no iframes | ❌ | ✅ |

> ⚠️ **The query string is a notification, not proof.** It is visible and
> editable by the payer. Before releasing goods, look the payment up through
> your own API using `reference`. This applies to embedded mode too — a
> postMessage is only as trustworthy as the page that sent it.

---

## 📚 API Methods

### `PaymentWidget.init(config)`

Initialize the payment widget.

```javascript
PaymentWidget.init({
  containerId: 'payment-widget',
  ereference: 'YOUR_REFERENCE',
  token: 'YOUR_TOKEN',
  lang: 'en',
  width: '100%',
  height: '600px'
});
```

### `PaymentWidget.redirect(config)`

Leave your site for the gateway; it returns the browser to `redirectUrl` with
the result appended. Navigates away, so nothing after it runs.

```javascript
PaymentWidget.redirect({
  ereference: 'YOUR_REFERENCE',
  token: 'YOUR_TOKEN',
  url: 'https://your-api.example.com',
  redirectUrl: 'https://your-shop.example.com/payment/complete'
});
```

### `PaymentWidget.buildUrl(config)`

Build the redirect-mode URL without navigating — for rendering a real link, or
handing the URL to your backend.

### `PaymentWidget.handleReturn(config)`

Read the result off the return URL and dispatch it to your callbacks. Returns
the result, or `null` when there is none. Cleans the address bar unless you pass
`clean: false`.

### `PaymentWidget.readResult(options)`

Return the result as a plain object without firing anything. `null` when the URL
carries no `status`.

### `PaymentWidget.clearResult()`

Remove the gateway's parameters from the address bar, leaving your own intact.
Uses `replaceState`, so the back button is unaffected.

### `PaymentWidget.destroy()`

Remove the widget and clean up.

```javascript
PaymentWidget.destroy();
```

### `PaymentWidget.version`

Get the current version.

```javascript
console.log(PaymentWidget.version); // "1.0.0"
```

---

## 🌐 Supported Languages

| Code | Language |
|------|----------|
| `en` | English |
| `ar` | Arabic |

---

## 💡 Examples

### Basic Usage

```html
<div id="payment-widget"></div>

<script src="https://cdn.jsdelivr.net/gh/BlockBuilders-Tech/credit-payment-widget@1.0.0/dist/payment-widget.min.js"></script>
<script>
  PaymentWidget.init({
    containerId: 'payment-widget',
    ereference: 'MDM2ODE0NjVATmc9PQ',
    token: 'XYZ',
    lang: 'en'
  });
</script>
```

### Full Page Widget

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { height: 100%; width: 100%; overflow: hidden; }
    #payment-widget { width: 100%; height: 100vh; }
  </style>
</head>
<body>
  <div id="payment-widget"></div>

  <script src="https://cdn.jsdelivr.net/gh/BlockBuilders-Tech/credit-payment-widget@1.0.0/dist/payment-widget.min.js"></script>
  <script>
    PaymentWidget.init({
      containerId: 'payment-widget',
      ereference: 'MDM2ODE0NjVATmc9PQ',
      token: 'XYZ',
      lang: 'en',
      width: '100%',
      height: '100vh'
    });
  </script>
</body>
</html>
```

### Custom Size Widget

```html
<div id="payment-widget"></div>

<script src="https://cdn.jsdelivr.net/gh/BlockBuilders-Tech/credit-payment-widget@1.0.0/dist/payment-widget.min.js"></script>
<script>
  PaymentWidget.init({
    containerId: 'payment-widget',
    ereference: 'MDM2ODE0NjVATmc9PQ',
    token: 'XYZ',
    lang: 'en',
    width: '500px',
    height: '800px'
  });
</script>
```

---

## 🔧 Browser Support

| Browser | Supported |
|---------|-----------|
| Chrome | ✅ |
| Firefox | ✅ |
| Safari | ✅ |
| Edge | ✅ |

---

## 📦 Script URL

The widget is served from our own infrastructure, alongside the gateway:

```html
<script src="https://portal.qredit.tech/sdk/payment-widget.min.js"></script>
```

There is one live path and it always serves the current release — no version
to pin, and no action needed on your side when we ship a fix. It is cached for
5 minutes, so updates reach you within minutes of release.

### Publishing (maintainers)

```bash
./deploy/publish.sh
```

Builds, checks the bundle parses, then uploads to `/usr/share/nginx/html/sdk/`
plus a pinned `v<version>/` copy for rollback. The nginx snippet that adds the
required CORS headers lives in `deploy/payment-widget.nginx.conf`.

---

## 📄 License

© 2025 [BlockBuilders](https://github.com/BlockBuilders-Tech). All Rights Reserved.

---

## 🤝 Support

For support, please contact [BlockBuilders](https://github.com/BlockBuilders-Tech).
Website : [BlockBuilders](https://blockbuilders.ps/)
---

Made with ❤️ by **BlockBuilders**