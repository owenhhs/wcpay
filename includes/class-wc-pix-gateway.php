<?php
/**
 * PIX Gateway class
 *
 * @package WooCommerce_pay/Classes/Gateway
 * @version 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

require_once WC_ABSPATH . 'includes/legacy/abstract-wc-legacy-order.php';
require_once dirname( __FILE__ ) . '/channels/class-wc-pix-channel.php';

/**
 * PIX Gateway.
 */
class WC_PIX_Gateway extends WC_Payment_Gateway {

    /**
     * PIX Channel instance.
     *
     * @var WC_PIX_Channel
     */
    protected $channel;

    /**
     * Constructor for the gateway.
     */
    public function __construct() {
        $this->id                 = 'pix';
        $this->icon               = apply_filters( 'woocommerce_pix_icon', plugins_url( 'assets/images/pix.png', plugin_dir_path( __FILE__ ) ) );
        $this->method_title       = __( 'PIX Payment', 'woocommerce-pay' );
        $this->method_description = __( 'Accept PIX payments via instant bank transfer.', 'woocommerce-pay' );
        $this->order_button_text  = __( 'Proceed to PIX Payment', 'woocommerce-pay' );

        // Load the form fields.
        $this->init_form_fields();

        // Load the settings.
        $this->init_settings();

        // Define user set variables.
        $this->title       = $this->get_option( 'title' );
        $this->description = $this->get_option( 'description' );
        $this->enabled     = $this->get_option( 'enabled' );
        $this->sandbox     = $this->get_option( 'sandbox', 'no' );
        $this->debug       = $this->get_option( 'debug' );

        // Active logs.
        if ( 'yes' === $this->debug ) {
            if ( function_exists( 'wc_get_logger' ) ) {
                $this->log = wc_get_logger();
            } else {
                $this->log = new WC_Logger();
            }
        }

        // Set the channel.
        $this->channel = new WC_PIX_Channel( $this );

        // Main actions.
        add_action( 'woocommerce_update_options_payment_gateways_' . $this->id, array( $this, 'process_admin_options' ) );
        add_action( 'woocommerce_receipt_' . $this->id, array( $this, 'receipt_page' ) );
        add_action( 'woocommerce_api_wc_pix_gateway', array( $this, 'check_ipn_response' ) );
    }

    /**
     * Initialise Gateway Settings Form Fields.
     */
    public function init_form_fields() {
        $this->form_fields = array(
            'enabled'         => array(
                'title'   => __( 'Enable/Disable', 'woocommerce-pay' ),
                'type'    => 'checkbox',
                'label'   => __( 'Enable PIX Payment', 'woocommerce-pay' ),
                'default' => 'no',
            ),
            'title'           => array(
                'title'       => __( 'Title', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => __( 'This controls the title which the user sees during checkout.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => __( 'PIX Payment', 'woocommerce-pay' ),
            ),
            'description'     => array(
                'title'       => __( 'Description', 'woocommerce-pay' ),
                'type'        => 'textarea',
                'description' => __( 'This controls the description which the user sees during checkout.', 'woocommerce-pay' ),
                'default'     => __( 'Pay instantly with PIX - Brazil instant payment system.', 'woocommerce-pay' ),
            ),
            'integration'     => array(
                'title'       => __( 'API Integration', 'woocommerce-pay' ),
                'type'        => 'title',
                'description' => sprintf( __( 'Enter your PIX API credentials. You can get these from %s.', 'woocommerce-pay' ), '<a href="https://s.apifox.cn/5bba2671-7bd9-4078-9cac-5074cd3bb826?pwd=5F6R083g" target="_blank">' . __( 'here', 'woocommerce-pay' ) . '</a>' ),
            ),
            'sandbox'         => array(
                'title'       => __( 'Sandbox Mode', 'woocommerce-pay' ),
                'type'        => 'checkbox',
                'label'       => __( 'Enable Sandbox Mode', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => 'no',
                'description' => __( 'Sandbox mode can be used to test the payments.', 'woocommerce-pay' ),
            ),
            'pix_api_base_url' => array(
                'title'       => __( 'API Base URL', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => __( 'The base URL of the PIX payment API.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => '',
                'placeholder' => 'https://api.example.com',
            ),
            'pix_app_id'      => array(
                'title'       => __( 'App ID', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => __( 'Your PIX API App ID.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => '',
            ),
            'pix_sign_key'    => array(
                'title'       => __( 'Sign Key', 'woocommerce-pay' ),
                'type'        => 'password',
                'description' => __( 'Your PIX API Sign Key.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => '',
            ),
            'testing'         => array(
                'title'       => __( 'Gateway Testing', 'woocommerce-pay' ),
                'type'        => 'title',
                'description' => '',
            ),
            'debug'           => array(
                'title'       => __( 'Debug Log', 'woocommerce-pay' ),
                'type'        => 'checkbox',
                'label'       => __( 'Enable logging', 'woocommerce-pay' ),
                'default'     => 'no',
                'description' => sprintf( __( 'Log PIX events, such as API requests, inside %s', 'woocommerce-pay' ), $this->get_log_view() ),
            ),
        );
    }

    /**
     * Get log view.
     *
     * @return string
     */
    protected function get_log_view() {
        if ( defined( 'WC_VERSION' ) && version_compare( WC_VERSION, '2.2', '>=' ) ) {
            return '<a href="' . esc_url( admin_url( 'admin.php?page=wc-status&tab=logs&log_file=' . esc_attr( $this->id ) . '-' . sanitize_file_name( wp_hash( $this->id ) ) . '.log' ) ) . '">' . __( 'System Status &gt; Logs', 'woocommerce-pay' ) . '</a>';
        }
        return '<code>woocommerce/logs/' . esc_attr( $this->id ) . '-' . sanitize_file_name( wp_hash( $this->id ) ) . '.txt</code>';
    }

    /**
     * Returns a value indicating the Gateway is available or not.
     *
     * @return bool
     */
    public function is_available() {
        $available = 'yes' === $this->enabled;
        
        if ( ! $available ) {
            return false;
        }

        // Check currency
        $currency = get_woocommerce_currency();
        if ( ! in_array( $currency, $this->channel->get_supported_currencies(), true ) ) {
            return false;
        }

        // Check API credentials
        $app_id  = $this->get_option( 'pix_app_id' );
        $sign_key = $this->get_option( 'pix_sign_key' );
        if ( empty( $app_id ) || empty( $sign_key ) ) {
            return false;
        }

        return true;
    }

    /**
     * Process the payment and return the result.
     *
     * @param  int $order_id Order ID.
     * @return array
     */
    public function process_payment( $order_id ) {
        $order = wc_get_order( $order_id );

        if ( 'yes' === $this->debug ) {
            $this->log->add( $this->id, 'Processing payment for order #' . $order_id );
        }

        // Create payment via channel
        $posted = $_POST; // WPCS: input var ok, CSRF ok.
        $response = $this->channel->create_payment( $order, $posted );

        if ( is_wp_error( $response ) ) {
            wc_add_notice( __( 'Payment error: ', 'woocommerce-pay' ) . $response->get_error_message(), 'error' );
            return array(
                'result'   => 'fail',
                'redirect' => '',
            );
        }

        // Check response code
        if ( isset( $response['code'] ) && 200 === $response['code'] ) {
            $body = $response['body'];

            // Check if payment was created successfully
            if ( isset( $body['code'] ) && in_array( $body['code'], array( 'SUCCESS', '200', '0' ), true ) ) {
                // Store transaction ID
                if ( isset( $body['transactionId'] ) ) {
                    if ( method_exists( $order, 'update_meta_data' ) ) {
                        $order->update_meta_data( '_pix_transaction_id', $body['transactionId'] );
                        $order->save();
                    } else {
                        update_post_meta( $order->id, '_pix_transaction_id', $body['transactionId'] );
                    }
                }

                // Store QR code or payment link if available
                if ( isset( $body['qrCode'] ) ) {
                    if ( method_exists( $order, 'update_meta_data' ) ) {
                        $order->update_meta_data( '_pix_qr_code', $body['qrCode'] );
                        $order->save();
                    } else {
                        update_post_meta( $order->id, '_pix_qr_code', $body['qrCode'] );
                    }
                }

                if ( isset( $body['paymentLink'] ) ) {
                    if ( method_exists( $order, 'update_meta_data' ) ) {
                        $order->update_meta_data( '_pix_payment_link', $body['paymentLink'] );
                        $order->save();
                    } else {
                        update_post_meta( $order->id, '_pix_payment_link', $body['paymentLink'] );
                    }
                }

                // Update order status
                $order->update_status( 'pending', __( 'Awaiting PIX payment.', 'woocommerce-pay' ) );

                // Reduce stock levels
                wc_reduce_stock_levels( $order_id );

                // Empty cart
                WC()->cart->empty_cart();

                // Return success with redirect to receipt page
                return array(
                    'result'   => 'success',
                    'redirect' => $this->get_return_url( $order ),
                );
            } else {
                // Payment creation failed
                $error_msg = isset( $body['message'] ) ? $body['message'] : __( 'Payment creation failed.', 'woocommerce-pay' );
                wc_add_notice( $error_msg, 'error' );
                
                if ( 'yes' === $this->debug ) {
                    $this->log->add( $this->id, 'Payment creation failed: ' . print_r( $body, true ) );
                }

                return array(
                    'result'   => 'fail',
                    'redirect' => '',
                );
            }
        } else {
            // API request failed
            $error_msg = __( 'Payment error. Please try again or contact us for assistance.', 'woocommerce-pay' );
            wc_add_notice( $error_msg, 'error' );

            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'API request failed: ' . print_r( $response, true ) );
            }

            return array(
                'result'   => 'fail',
                'redirect' => '',
            );
        }
    }

    /**
     * Output for the order received page.
     *
     * @param int $order_id Order ID.
     */
    public function receipt_page( $order_id ) {
        $order = wc_get_order( $order_id );

        // Query payment status
        $response = $this->channel->query_payment( $order_id );

        // Get QR code or payment link from order meta
        $qr_code = '';
        if ( method_exists( $order, 'get_meta' ) ) {
            $qr_code = $order->get_meta( '_pix_qr_code' );
        } else {
            $qr_code = get_post_meta( $order->id, '_pix_qr_code', true );
        }

        $payment_link = '';
        if ( method_exists( $order, 'get_meta' ) ) {
            $payment_link = $order->get_meta( '_pix_payment_link' );
        } else {
            $payment_link = get_post_meta( $order->id, '_pix_payment_link', true );
        }

        // Load receipt template
        $template_path = WC_pay::get_templates_path();
        if ( file_exists( $template_path . 'pix-receipt.php' ) ) {
            include $template_path . 'pix-receipt.php';
        } else {
            // Fallback template
            echo '<div class="woocommerce-pix-receipt">';
            echo '<h2>' . esc_html__( 'PIX Payment Instructions', 'woocommerce-pay' ) . '</h2>';
            if ( ! empty( $qr_code ) ) {
                echo '<div class="pix-qr-code"><p>' . esc_html__( 'QR Code:', 'woocommerce-pay' ) . '</p>';
                echo '<div class="qr-code-text">' . esc_html( $qr_code ) . '</div></div>';
            }
            if ( ! empty( $payment_link ) ) {
                echo '<div class="pix-payment-link">';
                echo '<a href="' . esc_url( $payment_link ) . '" class="button" target="_blank">' . esc_html__( 'Pay with PIX', 'woocommerce-pay' ) . '</a>';
                echo '</div>';
            }
            echo '</div>';
        }
    }

    /**
     * Check IPN response.
     */
    public function check_ipn_response() {
        $raw_data = file_get_contents( 'php://input' );
        $data     = json_decode( $raw_data, true );
        
        if ( 'yes' === $this->debug ) {
            $this->log->add( $this->id, 'IPN received: ' . $raw_data );
        }

        // Verify signature
        if ( ! $this->channel->verify_signature( $raw_data, $_SERVER ) ) {
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'IPN signature verification failed.' );
            }
            wp_die( 'Invalid signature', 'IPN Error', array( 'response' => 401 ) );
        }

        // Process IPN
        if ( $this->channel->process_ipn( $data ) ) {
            http_response_code( 200 );
            echo 'success';
        } else {
            http_response_code( 400 );
            echo 'error';
        }
        exit;
    }
}

