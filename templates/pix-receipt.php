<?php
/**
 * PIX Receipt Page Template
 *
 * @package WooCommerce_pay/Templates
 * @version 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * @var WC_Order $order
 * @var string   $qr_code
 * @var string   $payment_link
 * @var array    $response
 */

?>

<div class="woocommerce-pix-receipt">
    <h2><?php esc_html_e( 'PIX Payment Instructions', 'woocommerce-pay' ); ?></h2>

    <?php if ( $order->get_status() === 'completed' || $order->get_status() === 'processing' ) : ?>
        <div class="pix-payment-success">
            <p class="success-message">
                <?php esc_html_e( 'Your payment has been successfully processed!', 'woocommerce-pay' ); ?>
            </p>
        </div>
    <?php elseif ( $order->get_status() === 'pending' ) : ?>
        <div class="pix-payment-pending">
            <p class="pending-message">
                <?php esc_html_e( 'Your order is awaiting PIX payment. Please complete the payment using one of the methods below:', 'woocommerce-pay' ); ?>
            </p>

            <?php if ( ! empty( $qr_code ) ) : ?>
                <div class="pix-qr-code">
                    <h3><?php esc_html_e( 'Scan QR Code', 'woocommerce-pay' ); ?></h3>
                    <p><?php esc_html_e( 'Scan this QR code with your banking app to complete the payment:', 'woocommerce-pay' ); ?></p>
                    <div class="qr-code-image">
                        <?php
                        // Display QR code image if it's a base64 image or URL
                        if ( preg_match( '/^data:image\//', $qr_code ) ) {
                            echo '<img src="' . esc_url( $qr_code ) . '" alt="PIX QR Code" />';
                        } elseif ( filter_var( $qr_code, FILTER_VALIDATE_URL ) ) {
                            echo '<img src="' . esc_url( $qr_code ) . '" alt="PIX QR Code" />';
                        } else {
                            // If it's just the QR code string, try to generate an image
                            echo '<div class="qr-code-text">' . esc_html( $qr_code ) . '</div>';
                        }
                        ?>
                    </div>
                    <p class="qr-code-text-instructions">
                        <?php esc_html_e( 'Or copy the QR code text above and paste it into your banking app.', 'woocommerce-pay' ); ?>
                    </p>
                </div>
            <?php endif; ?>

            <?php if ( ! empty( $payment_link ) ) : ?>
                <div class="pix-payment-link">
                    <h3><?php esc_html_e( 'Payment Link', 'woocommerce-pay' ); ?></h3>
                    <p><?php esc_html_e( 'Click the link below to complete your payment:', 'woocommerce-pay' ); ?></p>
                    <p>
                        <a href="<?php echo esc_url( $payment_link ); ?>" class="button button-primary" target="_blank">
                            <?php esc_html_e( 'Pay with PIX', 'woocommerce-pay' ); ?>
                        </a>
                    </p>
                </div>
            <?php endif; ?>

            <div class="pix-payment-info">
                <h3><?php esc_html_e( 'Order Details', 'woocommerce-pay' ); ?></h3>
                <ul>
                    <li>
                        <strong><?php esc_html_e( 'Order Number:', 'woocommerce-pay' ); ?></strong>
                        <?php echo esc_html( $order->get_order_number() ); ?>
                    </li>
                    <li>
                        <strong><?php esc_html_e( 'Order Total:', 'woocommerce-pay' ); ?></strong>
                        <?php echo wp_kses_post( $order->get_formatted_order_total() ); ?>
                    </li>
                    <li>
                        <strong><?php esc_html_e( 'Payment Status:', 'woocommerce-pay' ); ?></strong>
                        <?php echo esc_html( wc_get_order_status_name( $order->get_status() ) ); ?>
                    </li>
                </ul>
            </div>

            <div class="pix-payment-notes">
                <p class="notes">
                    <strong><?php esc_html_e( 'Important:', 'woocommerce-pay' ); ?></strong>
                    <?php esc_html_e( 'Please complete your payment within the time limit. Once your payment is confirmed, your order will be processed automatically.', 'woocommerce-pay' ); ?>
                </p>
            </div>
        </div>
    <?php else : ?>
        <div class="pix-payment-error">
            <p class="error-message">
                <?php esc_html_e( 'There was an issue processing your payment. Please contact us for assistance.', 'woocommerce-pay' ); ?>
            </p>
        </div>
    <?php endif; ?>

    <div class="pix-actions">
        <a href="<?php echo esc_url( $order->get_view_order_url() ); ?>" class="button">
            <?php esc_html_e( 'View Order', 'woocommerce-pay' ); ?>
        </a>
    </div>
</div>

<style>
    .woocommerce-pix-receipt {
        max-width: 800px;
        margin: 20px auto;
        padding: 20px;
        background: #fff;
        border: 1px solid #ddd;
        border-radius: 4px;
    }

    .woocommerce-pix-receipt h2 {
        margin-top: 0;
        color: #333;
    }

    .woocommerce-pix-receipt h3 {
        margin-top: 20px;
        color: #555;
    }

    .pix-payment-success .success-message {
        padding: 15px;
        background: #d4edda;
        color: #155724;
        border: 1px solid #c3e6cb;
        border-radius: 4px;
    }

    .pix-payment-pending .pending-message {
        padding: 15px;
        background: #fff3cd;
        color: #856404;
        border: 1px solid #ffeaa7;
        border-radius: 4px;
    }

    .pix-qr-code,
    .pix-payment-link {
        margin: 20px 0;
        padding: 20px;
        background: #f9f9f9;
        border: 1px solid #e0e0e0;
        border-radius: 4px;
    }

    .qr-code-image {
        text-align: center;
        margin: 20px 0;
    }

    .qr-code-image img {
        max-width: 300px;
        border: 1px solid #ddd;
        padding: 10px;
        background: #fff;
    }

    .qr-code-text {
        padding: 15px;
        background: #fff;
        border: 1px solid #ddd;
        border-radius: 4px;
        font-family: monospace;
        word-break: break-all;
        font-size: 12px;
    }

    .pix-payment-info ul {
        list-style: none;
        padding: 0;
    }

    .pix-payment-info li {
        padding: 10px 0;
        border-bottom: 1px solid #eee;
    }

    .pix-payment-info li:last-child {
        border-bottom: none;
    }

    .pix-payment-notes {
        margin-top: 20px;
        padding: 15px;
        background: #e7f3ff;
        border-left: 4px solid #0066cc;
    }

    .pix-payment-error .error-message {
        padding: 15px;
        background: #f8d7da;
        color: #721c24;
        border: 1px solid #f5c6cb;
        border-radius: 4px;
    }

    .pix-actions {
        margin-top: 30px;
        text-align: center;
    }
</style>

