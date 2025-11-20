<?php
/**
 * Plugin Name:          pay
 * Version:              1.1.4
 *
 * @package pay
 */

defined( 'ABSPATH' ) || exit;

// Plugin constants.
define( 'WC_pay_VERSION', '1.1.4' );
define( 'WC_pay_PLUGIN_FILE', __FILE__ );

if ( ! class_exists( 'WC_pay' ) ) {
    include_once dirname( __FILE__ ) . '/includes/class-wc-pay.php';
    add_action( 'plugins_loaded', array( 'WC_pay', 'init' ) );
}
