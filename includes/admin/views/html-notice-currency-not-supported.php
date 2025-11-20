<?php
/**
 * Admin View: Notice - Currency not supported.
 *
 * @package WooCommerce_pay/Admin/Notices
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

?>

<div class="error inline">
    <p><strong><?php _e( 'pay Disabled', 'woocommerce-pay' ); ?></strong>: <?php printf( __( 'Currency <code>%s</code> is not supported. Works only with Brazilian Real.', 'woocommerce-pay' ), get_woocommerce_currency() ); ?>
    </p>
</div>
