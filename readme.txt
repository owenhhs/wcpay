=== LarkPay for WooCommerce ===
Contributors: LarkPay R&D team
Tags: woocommerce, larkpay, payment, gateway, brazil, latin america
Requires at least: 5.0
Tested up to: 6.4
Requires PHP: 7.2
Stable tag: 1.1.4
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

Integrate LarkPay payment gateway with your WooCommerce store. Support for multiple payment methods including credit cards, bank transfers, and boleto payments across Latin America.

== Description ==

LarkPay for WooCommerce is a payment gateway plugin that integrates LarkPay payment services with your WooCommerce store. This plugin enables merchants to accept payments from customers across Latin America through various payment methods.

= Key Features =

* Multiple Payment Methods
  * Credit card payments
  * Bank transfers
  * Boleto (bank slip) payments
  * Transparent checkout

* Regional Support
  * Brazil (BRA)
  * Mexico (MEX)
  * Chile (CHL)
  * Colombia (COL)
  * Argentina (ARG)
  * Peru (PER)
  * Ecuador (ECU)
  * Bolivia (BOL)

* Advanced Features
  * Sandbox mode for testing
  * IPN (Instant Payment Notification) handling
  * Automatic order status updates
  * Payment logging
  * Multi-language support
  * Debug mode

= Payment Status Mapping =

* SUCCESS → Completed
* REFUND/REFUND_MER/REFUND_PRT → Refunded
* REFUSED → Failed
* CANCEL → Cancelled
* RISK_CONTROLLING → Pending
* DISPUTE → Pending
* REFUNDED → Refunded
* CHARGEBACK → Processing

= Security Features =

* HMAC-SHA256 signature verification for IPN requests
* HTTPS communication for all API requests
* Strict input data validation
* WordPress CSRF protection

== Installation ==

= Automatic Installation =

1. Log in to your WordPress admin panel
2. Navigate to Plugins → Add New
3. Search for "LarkPay for WooCommerce"
4. Click "Install Now"
5. Click "Activate"

= Manual Installation =

1. Download the plugin ZIP file
2. Extract the files
3. Upload the entire folder to `/wp-content/plugins/` directory
4. Activate the plugin through the 'Plugins' menu in WordPress

= Configuration =

1. Go to WooCommerce → Settings → Payments
2. Find "pay" payment method
3. Click "Manage" or "Settings"
4. Enter your LarkPay API credentials:
   * APP ID
   * Secret Key
   * Public Key
5. Configure sandbox credentials if using test mode
6. Enable the payment gateway
7. Save settings

For detailed installation and configuration instructions, please refer to the [Installation Guide](docs/INSTALLATION.md).

== Frequently Asked Questions ==

= Do I need a LarkPay account? =

Yes, you need a valid LarkPay merchant account and API credentials to use this plugin.

= Which countries are supported? =

The plugin supports 8 Latin American countries: Brazil, Mexico, Chile, Colombia, Argentina, Peru, Ecuador, and Bolivia.

= Can I test the plugin before going live? =

Yes, the plugin includes a sandbox mode for testing. Enable it in the payment gateway settings and use test credentials.

= How do I enable debug logging? =

Enable "Debug Log" in the payment gateway settings. Logs can be viewed at WooCommerce → Status → Logs.

= What currencies are supported? =

The plugin supports multiple currencies, primarily focusing on local currencies for each supported region.

= Is SSL required? =

SSL is highly recommended for production environments to ensure secure payment processing.

== Screenshots ==

1. Payment gateway settings page
2. Checkout page with LarkPay payment option
3. Order status after payment

== Changelog ==

= 1.1.4 =
* Current version
* Multi-region payment support
* Improved IPN handling
* Enhanced security features
* Better error handling

= 1.1.0 =
* Initial release
* Basic payment gateway integration
* Support for credit cards, bank transfers, and boleto
* IPN callback handling

== Upgrade Notice ==

= 1.1.4 =
This version includes multi-region support and improved security. Please update your API credentials if needed.

== Support ==

For support, please:
1. Check the [Installation Guide](docs/INSTALLATION.md) for common issues
2. Review the [Technical Documentation](docs/DOCUMENTATION.md)
3. Check debug logs if enabled
4. Contact LarkPay technical support

== Documentation ==

Complete documentation is available in the `docs/` directory:

* [Technical Documentation](docs/DOCUMENTATION.md) - Architecture, API integration, and development guide
* [Installation Guide](docs/INSTALLATION.md) - Step-by-step installation and configuration
* [API Reference](docs/API_REFERENCE.md) - Complete API endpoint documentation
* [Project Summary](docs/PROJECT_SUMMARY.md) - Project overview and documentation index

== Credits ==

* Original Author: Claudio Sanches
* Current Maintainer: LarkPay R&D team
* Based on WooCommerce payment gateway standards

== License ==

This plugin is licensed under the GPL v2 or later.

== Notes ==

This plugin requires:
* WordPress 5.0 or higher
* WooCommerce 3.0 or higher
* PHP 7.2 or higher
* Valid LarkPay merchant account and API credentials

For production use, SSL certificate is highly recommended.
