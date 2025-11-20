<?php
/**
 * HTML email instructions.
 *
 * @author  Claudio_Sanches
 * @package WooCommerce_depositexpress/Templates
 * @version 2.7.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit; // Exit if accessed directly.
}
?>

    <h2><?php _e( 'Payment', 'woocommerce-depositexpress' ); ?></h2>

<?php if ( 2 == $type ) : ?>

    <p class="order_details"><?php _e( 'Please use the link below to view your Banking Ticket, you can print and pay in your internet banking or in a depositexpress retailer:', 'woocommerce-depositexpress' ); ?><br /><a class="button" href="<?php echo esc_url( $link ); ?>" target="_blank"><?php _e( 'Pay the Banking Ticket', 'woocommerce-depositexpress' ); ?></a><br /><?php _e( 'After we receive the ticket payment confirmation, your order will be processed.', 'woocommerce-depositexpress' ); ?></p>

<?php elseif ( 3 == $type ) : ?>

    <p class="order_details"><?php _e( 'Please use the link below to make the payment in your bankline:', 'woocommerce-depositexpress' ); ?><br /><a class="button" href="<?php echo esc_url( $link ); ?>" target="_blank"><?php _e( 'Pay at your bank', 'woocommerce-depositexpress' ); ?>.<br /><?php _e( 'After we receive the confirmation from the bank, your order will be processed.', 'woocommerce-depositexpress' ); ?></a></p>

<?php else : ?>

    <p class="order_details"><?php echo sprintf( __( 'You just made the payment in %s using the %s.', 'woocommerce-depositexpress' ), '<strong>' . $installments . 'x</strong>', '<strong>' . $method . '</strong>' ); ?><br /><?php _e( 'As soon as the credit card operator confirm the payment, your order will be processed.', 'woocommerce-depositexpress' ); ?></p>

<?php
endif;
