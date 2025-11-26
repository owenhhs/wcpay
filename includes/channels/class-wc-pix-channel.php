<?php
/**
 * PIX Payment Channel class
 *
 * @package WooCommerce_pay/Channels
 * @version 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

require_once dirname( __FILE__ ) . '/abstract-wc-payment-channel.php';

/**
 * PIX Payment Channel.
 */
class WC_PIX_Channel extends WC_Payment_Channel {

    /**
     * Channel ID.
     *
     * @var string
     */
    protected $channel_id = 'pix';

    /**
     * Channel name.
     *
     * @var string
     */
    protected $channel_name = 'PIX';

    /**
     * Get API endpoint URL.
     *
     * @param string $endpoint Endpoint path.
     * @return string
     */
    protected function get_api_url( $endpoint ) {
        $base_url = $this->gateway->get_option( 'pix_api_base_url', 'https://api.example.com' );
        $base_url = rtrim( $base_url, '/' );
        $endpoint = ltrim( $endpoint, '/' );
        return $base_url . '/' . $endpoint;
    }

    /**
     * Get API headers.
     *
     * @return array
     */
    protected function get_api_headers() {
        $app_id    = $this->gateway->get_option( 'pix_app_id' );
        $sign_key  = $this->gateway->get_option( 'pix_sign_key' );
        $auth_str  = base64_encode( $app_id . ':' . $sign_key );

        return array(
            'Content-Type'  => 'application/json',
            'Authorization' => 'Basic ' . $auth_str,
        );
    }

    /**
     * Get supported currencies.
     *
     * @return array
     */
    public function get_supported_currencies() {
        return array( 'BRL' );
    }

    /**
     * Create payment request.
     *
     * @param WC_Order $order Order object.
     * @param array    $posted Posted data.
     * @return array Response data.
     */
    public function create_payment( $order, $posted = array() ) {
        $billing_data = $this->get_billing_data( $order );
        
        // Get CPF/CNPJ from order meta or posted data
        $national_id = '';
        if ( method_exists( $order, 'get_meta' ) ) {
            $national_id = $order->get_meta( '_billing_cpf' );
            if ( empty( $national_id ) ) {
                $national_id = $order->get_meta( '_billing_cnpj' );
            }
        } else {
            $national_id = get_post_meta( $order->id, '_billing_cpf', true );
            if ( empty( $national_id ) ) {
                $national_id = get_post_meta( $order->id, '_billing_cnpj', true );
            }
        }
        
        // Get from posted data if available
        if ( empty( $national_id ) && isset( $posted['billing_cpf'] ) ) {
            $national_id = $posted['billing_cpf'];
        }
        if ( empty( $national_id ) && isset( $posted['billing_cnpj'] ) ) {
            $national_id = $posted['billing_cnpj'];
        }

        // Get address components
        $address_components = $this->parse_address( $billing_data['address_1'] );
        $neighborhood = '';
        if ( method_exists( $order, 'get_meta' ) ) {
            $neighborhood = $order->get_meta( '_billing_neighborhood' );
        } else {
            $neighborhood = get_post_meta( $order->id, '_billing_neighborhood', true );
        }
        if ( empty( $neighborhood ) ) {
            $neighborhood = '212'; // Default value as per requirements
        }

        // Get address number
        $address_number = '';
        if ( method_exists( $order, 'get_meta' ) ) {
            $address_number = $order->get_meta( '_billing_number' );
        } else {
            $address_number = get_post_meta( $order->id, '_billing_number', true );
        }
        if ( empty( $address_number ) ) {
            $address_number = '3213'; // Default value as per requirements
        }

        // Build payment request data
        $request_data = array(
            'amount'   => $this->format_amount( $order->get_total() ),
            'billing'  => array(
                'address'    => array(
                    'city'         => ! empty( $billing_data['city'] ) ? $billing_data['city'] : 'R11',
                    'country'      => 'BRA',
                    'neighborhood' => $neighborhood,
                    'number'       => $address_number,
                    'line1'        => ! empty( $billing_data['address_1'] ) ? $billing_data['address_1'] : '2311312',
                    'postcode'     => ! empty( $billing_data['postcode'] ) ? preg_replace( '/[^0-9]/', '', $billing_data['postcode'] ) : '12345678',
                    'region'       => ! empty( $billing_data['state'] ) ? $billing_data['state'] : 'MG',
                ),
                'email'      => ! empty( $billing_data['email'] ) ? $billing_data['email'] : '',
                'phone'      => ! empty( $billing_data['phone'] ) ? preg_replace( '/[^0-9]/', '', $billing_data['phone'] ) : '',
                'nationalId' => ! empty( $national_id ) ? preg_replace( '/[^0-9]/', '', $national_id ) : '',
            ),
            'type'     => 'PIX',
            'card'     => array(
                'firstName' => ! empty( $billing_data['first_name'] ) ? $billing_data['first_name'] : 'Michael',
                'lastName'  => ! empty( $billing_data['last_name'] ) ? $billing_data['last_name'] : 'Jackson',
            ),
            'currency' => 'BRL',
            'orderNo'  => (string) $order->get_id(),
            'deviceInfo' => array(
                'clientIp' => $this->get_client_ip(),
                'language' => 'en-US',
            ),
        );

        // Make API request
        $response = $this->make_request(
            $this->get_api_url( 'payment/create' ),
            $request_data,
            'POST'
        );

        return $response;
    }

    /**
     * Query payment status.
     *
     * @param string $order_id Order ID.
     * @param string $transaction_id Transaction ID (optional).
     * @return array Response data.
     */
    public function query_payment( $order_id, $transaction_id = '' ) {
        $endpoint = 'payment/query';
        $data     = array(
            'orderNo' => (string) $order_id,
        );

        if ( ! empty( $transaction_id ) ) {
            $data['transactionId'] = $transaction_id;
        }

        $response = $this->make_request(
            $this->get_api_url( $endpoint ),
            $data,
            'POST'
        );

        return $response;
    }

    /**
     * Process IPN callback.
     *
     * @param array $data IPN data.
     * @return bool
     */
    public function process_ipn( $data ) {
        if ( empty( $data ) || ! isset( $data['orderNo'] ) ) {
            return false;
        }

        $order_id = $data['orderNo'];
        $order    = wc_get_order( $order_id );

        if ( ! $order ) {
            return false;
        }

        // Update order status based on payment status
        $status = isset( $data['status'] ) ? $data['status'] : '';

        switch ( strtoupper( $status ) ) {
            case 'SUCCESS':
            case 'PAID':
            case 'COMPLETED':
                $order->update_status( 'completed', __( 'PIX payment completed.', 'woocommerce-pay' ) );
                break;
            case 'FAILED':
            case 'REFUSED':
                $order->update_status( 'failed', __( 'PIX payment failed.', 'woocommerce-pay' ) );
                break;
            case 'PENDING':
            case 'PROCESSING':
                $order->update_status( 'pending', __( 'PIX payment pending.', 'woocommerce-pay' ) );
                break;
            case 'CANCELLED':
            case 'CANCEL':
                $order->update_status( 'cancelled', __( 'PIX payment cancelled.', 'woocommerce-pay' ) );
                break;
        }

        // Save transaction ID if available
        if ( isset( $data['transactionId'] ) ) {
            if ( method_exists( $order, 'update_meta_data' ) ) {
                $order->update_meta_data( '_pix_transaction_id', $data['transactionId'] );
                $order->save();
            } else {
                update_post_meta( $order->id, '_pix_transaction_id', $data['transactionId'] );
            }
        }

        return true;
    }

    /**
     * Verify IPN signature.
     *
     * @param string $data Raw POST data.
     * @param array  $headers Request headers.
     * @return bool
     */
    public function verify_signature( $data, $headers = array() ) {
        // Get signature from headers
        $signature = '';
        if ( isset( $_SERVER['HTTP_X_SIGNATURE'] ) ) {
            $signature = $_SERVER['HTTP_X_SIGNATURE'];
        } elseif ( isset( $headers['X-Signature'] ) ) {
            $signature = $headers['X-Signature'];
        }

        if ( empty( $signature ) ) {
            return false;
        }

        // Get sign key
        $sign_key = $this->gateway->get_option( 'pix_sign_key' );

        // Calculate signature
        $calculated_signature = hash_hmac( 'sha256', $data, $sign_key );

        // Compare signatures
        return hash_equals( $signature, $calculated_signature );
    }

    /**
     * Parse address string to extract components.
     *
     * @param string $address Address string.
     * @return array
     */
    private function parse_address( $address ) {
        // Simple address parsing - can be enhanced based on requirements
        return array(
            'street' => $address,
            'number' => '',
        );
    }
}

