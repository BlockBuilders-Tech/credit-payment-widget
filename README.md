# Credit Payment Widget

A lightweight, secure payment widget plugin by **[BlockBuilders](https://github.com/BlockBuilders-Tech)**.

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

## ⚙️ Configuration Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `containerId` | string | ✅ Yes | - | ID of the HTML container element |
| `ereference` | string | ✅ Yes | `''` | Your payment reference code |
| `token` | string | ✅ Yes | `''` | Your authentication token |
| `lang` | string | No | `'en'` | Language code (`'en'`, `'ar'`, etc.) |
| `width` | string | No | `'100%'` | Widget width |
| `height` | string | No | `'1000px'` | Widget height |

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

## 📦 CDN Links

| Version | URL |
|---------|-----|
| Latest | `https://cdn.jsdelivr.net/gh/BlockBuilders-Tech/credit-payment-widget@latest/dist/payment-widget.min.js` |
| v1.0.0 | `https://cdn.jsdelivr.net/gh/BlockBuilders-Tech/credit-payment-widget@1.0.0/dist/payment-widget.min.js` |

---

## 📄 License

© 2025 [BlockBuilders](https://github.com/BlockBuilders-Tech). All Rights Reserved.

---

## 🤝 Support

For support, please contact [BlockBuilders](https://github.com/BlockBuilders-Tech).
Website : [BlockBuilders](https://blockbuilders.ps/)
---

Made with ❤️ by **BlockBuilders**