<?php
/**
 * Abstract Payment Channel class
 *
 * @package WooCommerce_pay/Channels
 * @version 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Abstract Payment Channel.
 *
 * This abstract class provides a base for all payment channels.
 * Each payment channel should extend this class and implement the required methods.
 */
abstract class WC_Payment_Channel {

    /**
     * Gateway instance.
     *
     * @var WC_Payment_Gateway
     */
    protected $gateway;

    /**
     * Channel ID.
     *
     * @var string
     */
    protected $channel_id;

    /**
     * Channel name.
     *
     * @var string
     */
    protected $channel_name;

    /**
     * Constructor.
     *
     * @param WC_Payment_Gateway $gateway Gateway instance.
     */
    public function __construct( $gateway ) {
        $this->gateway = $gateway;
    }

    /**
     * Get channel ID.
     *
     * @return string
     */
    public function get_channel_id() {
        return $this->channel_id;
    }

    /**
     * Get channel name.
     *
     * @return string
     */
    public function get_channel_name() {
        return $this->channel_name;
    }

    /**
     * Create payment request.
     *
     * @param WC_Order $order Order object.
     * @param array    $posted Posted data.
     * @return array Response data.
     */
    abstract public function create_payment( $order, $posted = array() );

    /**
     * Query payment status.
     *
     * @param string $order_id Order ID.
     * @param string $transaction_id Transaction ID (optional).
     * @return array Response data.
     */
    abstract public function query_payment( $order_id, $transaction_id = '' );

    /**
     * Process IPN callback.
     *
     * @param array $data IPN data.
     * @return bool
     */
    abstract public function process_ipn( $data );

    /**
     * Verify IPN signature.
     *
     * @param string $data Raw POST data.
     * @param array  $headers Request headers.
     * @return bool
     */
    abstract public function verify_signature( $data, $headers = array() );

    /**
     * Get supported currencies.
     *
     * @return array
     */
    abstract public function get_supported_currencies();

    /**
     * Get API endpoint URL.
     *
     * @param string $endpoint Endpoint path.
     * @return string
     */
    abstract protected function get_api_url( $endpoint );

    /**
     * Get API headers.
     *
     * @return array
     */
    abstract protected function get_api_headers();

    /**
     * Make API request.
     *
     * @param string $url Request URL.
     * @param array  $data Request data.
     * @param string $method Request method.
     * @return array|WP_Error
     */
    protected function make_request( $url, $data = array(), $method = 'POST' ) {
        $headers = $this->get_api_headers();
        $params  = array(
            'method'  => $method,
            'timeout' => 60,
            'headers' => $headers,
        );

        if ( 'POST' === $method && ! empty( $data ) ) {
            $params['body'] = is_array( $data ) ? json_encode( $data ) : $data;
        }

        $response = wp_safe_remote_request( $url, $params );

        if ( is_wp_error( $response ) ) {
            if ( 'yes' === $this->gateway->debug ) {
                $this->gateway->log->add(
                    $this->gateway->id,
                    'Error in API request: ' . $response->get_error_message()
                );
            }
            return $response;
        }

        $body = wp_remote_retrieve_body( $response );
        $code = wp_remote_retrieve_response_code( $response );

        if ( 'yes' === $this->gateway->debug ) {
            $this->gateway->log->add(
                $this->gateway->id,
                'API Request: ' . $url . PHP_EOL . 'Request Data: ' . print_r( $data, true ) . PHP_EOL . 'Response Code: ' . $code . PHP_EOL . 'Response Body: ' . $body
            );
        }

        return array(
            'code' => $code,
            'body' => json_decode( $body, true ),
            'raw'  => $body,
        );
    }

    /**
     * Format amount.
     *
     * @param float $amount Amount.
     * @return string
     */
    protected function format_amount( $amount ) {
        return number_format( $amount, 2, '.', '' );
    }

    /**
     * Get client IP address.
     *
     * @return string
     */
    protected function get_client_ip() {
        $ip = isset( $_SERVER['REMOTE_ADDR'] ) ? $_SERVER['REMOTE_ADDR'] : '127.0.0.1';
        
        if ( isset( $_SERVER['HTTP_CLIENT_IP'] ) && preg_match( '/^([0-9]{1,3}\.){3}[0-9]{1,3}$/', $_SERVER['HTTP_CLIENT_IP'] ) ) {
            $ip = $_SERVER['HTTP_CLIENT_IP'];
        } elseif ( isset( $_SERVER['HTTP_X_FORWARDED_FOR'] ) && preg_match_all( '#\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}#s', $_SERVER['HTTP_X_FORWARDED_FOR'], $matches ) ) {
            foreach ( $matches[0] as $xip ) {
                if ( ! preg_match( '#^(10|172\.16|192\.168)\.#', $xip ) ) {
                    $ip = $xip;
                    break;
                }
            }
        }
        
        return $ip;
    }

    /**
     * Get order billing data.
     *
     * @param WC_Order $order Order object.
     * @return array
     */
    protected function get_billing_data( $order ) {
        if ( method_exists( $order, 'get_billing_first_name' ) ) {
            return array(
                'first_name' => $order->get_billing_first_name(),
                'last_name'  => $order->get_billing_last_name(),
                'email'      => $order->get_billing_email(),
                'phone'      => $order->get_billing_phone(),
                'country'    => $order->get_billing_country(),
                'state'      => $order->get_billing_state(),
                'city'       => $order->get_billing_city(),
                'postcode'   => $order->get_billing_postcode(),
                'address_1'  => $order->get_billing_address_1(),
                'address_2'  => $order->get_billing_address_2(),
            );
        } else {
            return array(
                'first_name' => $order->billing_first_name,
                'last_name'  => $order->billing_last_name,
                'email'      => $order->billing_email,
                'phone'      => $order->billing_phone,
                'country'    => $order->billing_country,
                'state'      => $order->billing_state,
                'city'       => $order->billing_city,
                'postcode'   => $order->billing_postcode,
                'address_1'  => $order->billing_address_1,
                'address_2'  => $order->billing_address_2,
            );
        }
    }
}

