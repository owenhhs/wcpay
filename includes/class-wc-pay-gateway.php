<?php
/**
 * Gateway class
 *
 * @package WooCommerce_pay/Classes/Gateway
 * @version 2.13.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

require_once WC_ABSPATH . 'includes/legacy/abstract-wc-legacy-order.php';

/**
 * Gateway.
 */
class WC_pay_Gateway extends WC_Payment_Gateway {

    /**
     * Constructor for the gateway.
     */
    public function __construct() {
        $this->id                 = 'pay';
        $this->icon               = apply_filters( 'woocommerce_pay_pay_icon', plugins_url( 'assets/images/pay.png', plugin_dir_path( __FILE__ ) ) );
        $this->method_title       = __( 'pay', 'woocommerce-pay' );
        $this->method_description = __( 'Pay with pay.', 'woocommerce-pay' );
        $this->order_button_text  = __( 'Proceed to payment', 'woocommerce-pay' );

        // Load the form fields.
        $this->init_form_fields();

        // Load the settings.
        $this->init_settings();

        // Define user set variables.
        $this->title             = $this->get_option( 'title' );
        $this->order_button_text  = $this->get_option( 'order_button_text' );
        $this->description       = $this->get_option( 'description' );
        $this->email             = $this->get_option( 'email' );
        $this->token             = $this->get_option( 'token' );
        $this->app_id             = $this->get_option( 'app_id' );
        $this->secret_key             = $this->get_option( 'secret_key' );
        $this->public_key             = $this->get_option( 'public_key' );
        $this->sandbox_email     = $this->get_option( 'sandbox_email' );
        $this->sandbox_token     = $this->get_option( 'sandbox_token' );
        $this->sandbox_app_id     = $this->get_option( 'sandbox_app_id' );
        $this->sandbox_secret_key     = $this->get_option( 'sandbox_secret_key' );
        $this->sandbox_public_key     = $this->get_option( 'sandbox_public_key' );
        $this->method            = $this->get_option( 'method', 'direct' );
        $this->tc_credit         = $this->get_option( 'tc_credit', 'yes' );
        $this->tc_transfer       = $this->get_option( 'tc_transfer', 'yes' );
        $this->tc_ticket         = $this->get_option( 'tc_ticket', 'yes' );
        $this->tc_ticket_message = $this->get_option( 'tc_ticket_message', 'yes' );
        $this->send_only_total   = $this->get_option( 'send_only_total', 'no' );
        $this->invoice_prefix    = $this->get_option( 'invoice_prefix', 'WC-' );
        $this->sandbox           = $this->get_option( 'sandbox', 'no' );
        $this->debug             = $this->get_option( 'debug' );

        // Active logs.
        if ( 'yes' === $this->debug ) {
            if ( function_exists( 'wc_get_logger' ) ) {
                $this->log = wc_get_logger();
            } else {
                $this->log = new WC_Logger();
            }
        }

        // Set the API.
        $this->api = new WC_pay_API( $this );

        // Main actions.
//		add_action( 'woocommerce_api_wc_pay_gateway', array( $this, 'ipn_handler' ) );
        add_action( 'valid_pay_ipn_request', array( $this, 'update_order_status' ) );
        add_action( 'woocommerce_update_options_payment_gateways_' . $this->id, array( $this, 'process_admin_options' ) );
        add_action( 'woocommerce_receipt_' . $this->id, array( $this, 'receipt_page' ) );

        add_action( 'woocommerce_api_wc_pay_gateway', array( $this, 'check_ipn_response' ) );

        // Transparent checkout actions.
        if ( 'transparent' === $this->method ) {
            add_action( 'woocommerce_thankyou_' . $this->id, array( $this, 'thankyou_page' ) );
            add_action( 'woocommerce_email_after_order_table', array( $this, 'email_instructions' ), 10, 3 );
            add_action( 'wp_enqueue_scripts', array( $this, 'checkout_scripts' ) );
        }
    }

    /**
     * Returns a bool that indicates if currency is amongst the supported ones.
     *
     * @return bool
     */
    public function using_supported_currency() {
        return true;
        if(get_woocommerce_currency() === 'BRL' || get_woocommerce_currency() === 'R$'){
            return true;
        }
        return false;
    }

    /**
     * Get email.
     *
     * @return string
     */
    public function get_email() {
        return 'yes' === $this->sandbox ? $this->sandbox_email : $this->email;
    }

    /**
     * Get token.
     *
     * @return string
     */
    public function get_token() {
        return 'yes' === $this->sandbox ? $this->sandbox_token : $this->token;
    }

    public function app_id() {
        return 'yes' === $this->sandbox ? $this->sandbox_app_id : $this->app_id;
    }

    public function secret_key() {
        return 'yes' === $this->sandbox ? $this->sandbox_secret_key : $this->secret_key;
    }
    public function public_key() {
        return 'yes' === $this->sandbox ? $this->sandbox_public_key : $this->public_key;
    }
    public function gateway_url() {
        return 'yes' === $this->sandbox ? 'https://gateway-test.larkpay.com' : 'https://gateway.larkpay.com';

    }

    /**
     * Returns a value indicating the the Gateway is available or not. It's called
     * automatically by WooCommerce before allowing customers to use the gateway
     * for payment.
     *
     * @return bool
     */
    public function is_available() {
        // Test if is valid for use.
        $available = 'yes' === $this->get_option( 'enabled' ) && '' !== $this->app_id() && '' !== $this->secret_key()&& '' !== $this->public_key() && $this->using_supported_currency();
        if ( 'transparent' === $this->method && ! class_exists( 'Extra_Checkout_Fields_For_Brazil' ) ) {
            $available = false;
        }

        return $available;
    }

    /**
     * Has fields.
     *
     * @return bool
     */
    public function has_fields() {
        return 'transparent' === $this->method;
    }

    /**
     * Checkout scripts.
     */
    public function checkout_scripts() {
        if ( is_checkout() && $this->is_available() ) {
            if ( ! get_query_var( 'order-received' ) ) {
                $session_id = $this->api->get_session_id();
                $suffix     = defined( 'SCRIPT_DEBUG' ) && SCRIPT_DEBUG ? '' : '.min';

                wp_enqueue_style( 'pay-checkout', plugins_url( 'assets/css/frontend/transparent-checkout' . $suffix . '.css', plugin_dir_path( __FILE__ ) ), array(), WC_pay_VERSION );
                wp_enqueue_script( 'pay-library', $this->api->get_direct_payment_url(), array(), WC_pay_VERSION, true );
                wp_enqueue_script( 'pay-checkout', plugins_url( 'assets/js/frontend/transparent-checkout' . $suffix . '.js', plugin_dir_path( __FILE__ ) ), array( 'jquery', 'pay-library', 'woocommerce-extra-checkout-fields-for-brazil-front' ), WC_pay_VERSION, true );

                wp_localize_script(
                    'pay-checkout',
                    'wc_pay_params',
                    array(
                        'session_id'         => $session_id,
                        'interest_free'      => __( 'interest free', 'woocommerce-pay' ),
                        'invalid_card'       => __( 'Invalid credit card number.', 'woocommerce-pay' ),
                        'invalid_expiry'     => __( 'Invalid expiry date, please use the MM / YYYY date format.', 'woocommerce-pay' ),
                        'expired_date'       => __( 'Please check the expiry date and use a valid format as MM / YYYY.', 'woocommerce-pay' ),
                        'general_error'      => __( 'Unable to process the data from your credit card on the pay, please try again or contact us for assistance.', 'woocommerce-pay' ),
                        'empty_installments' => __( 'Select a number of installments.', 'woocommerce-pay' ),
                    )
                );
            }
        }
    }

    /**
     * Get log.
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
     * Initialise Gateway Settings Form Fields.
     */
    public function init_form_fields() {
        $this->form_fields = array(
            'enabled'              => array(
                'title'   => __( 'Enable/Disable', 'woocommerce-pay' ),
                'type'    => 'checkbox',
                'label'   => __( 'Enable pay', 'woocommerce-pay' ),
                'default' => 'yes',
            ),
            'title'                => array(
                'title'       => __( 'Title', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => __( 'This controls the title which the user sees during checkout.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => __( 'Payment', 'woocommerce-pay' ),
            ),
            'order_button_text'                => array(
                'title'       => __( 'Order Button', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => __( 'Isso controla qual botão o usuário vê ao enviar o checkout.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => __( 'Payment', 'woocommerce-pay' ),
            ),
            'description'          => array(
                'title'       => __( 'Description', 'woocommerce-pay' ),
                'type'        => 'textarea',
                'description' => __( 'This controls the description which the user sees during checkout.', 'woocommerce-pay' ),
                'default'     => __( 'Aggregate payment', 'woocommerce-pay' ),
            ),
            'integration'          => array(
                'title'       => __( 'Integration', 'woocommerce-pay' ),
                'type'        => 'title',
                'description' => sprintf( __( 'This is needed to process the payment and notifications. Is possible generate  %s.', 'woocommerce-pay' ), '<a href="https://www.larkpay.com/">' . __( 'here', 'woocommerce-pay' ) . '</a>' ),
            ),

            'sandbox'              => array(
                'title'       => __( 'pay Sandbox', 'woocommerce-pay' ),
                'type'        => 'checkbox',
                'label'       => __( 'Enable pay Sandbox', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => 'no',
                'description' => __( 'pay Sandbox can be used to test the payments.', 'woocommerce-pay' ),
            ),
            'app_id'                => array(
                'title'       => __( 'APP ID', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => __( 'Please enter your pay APP ID address. This is needed in order to take payment.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => '',
            ),
            'secret_key'                => array(
                'title'       => __( 'pay Secret key', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => __( 'Please enter your pay Secret key address. This is needed in order to take payment.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => '',
            ),
            'public_key'                => array(
                'title'       => __( 'pay Public key', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => __( 'Please enter your pay Public key address. This is needed in order to take payment.', 'woocommerce-pay' ),
                'desc_tip'    => true,
                'default'     => '',
            ),
            'sandbox_app_id'        => array(
                'title'       => __( 'pay Sandbox APP ID', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => '',
                'default'     => '2017051914172236111',
            ),
            'sandbox_secret_key'        => array(
                'title'       => __( 'pay Sandbox Secret key', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => '',
                'default'     => 'TEST_APP_KEY',
            ),
            'sandbox_public_key'        => array(
                'title'       => __( 'pay Sandbox Public key', 'woocommerce-pay' ),
                'type'        => 'text',
                'description' => '',
                'default'     => 'TEST_APP_KEY',
            ),
            'testing'              => array(
                'title'       => __( 'Gateway Testing', 'woocommerce-pay' ),
                'type'        => 'title',
                'description' => '',
            ),
            'debug'                => array(
                'title'       => __( 'Debug Log', 'woocommerce-pay' ),
                'type'        => 'checkbox',
                'label'       => __( 'Enable logging', 'woocommerce-pay' ),
                'default'     => 'no',
                'description' => sprintf( __( 'Log pay events, such as API requests, inside %s', 'woocommerce-pay' ), $this->get_log_view() ),
            ),
        );
    }

    /**
     * Admin page.
     */
    public function admin_options() {
        $suffix = defined( 'SCRIPT_DEBUG' ) && SCRIPT_DEBUG ? '' : '.min';

        wp_enqueue_script( 'pay-admin', plugins_url( 'assets/js/admin/admin' . $suffix . '.js', plugin_dir_path( __FILE__ ) ), array( 'jquery' ), WC_pay_VERSION, true );

        include dirname( __FILE__ ) . '/admin/views/html-admin-page.php';
    }

    /**
     * Send email notification.
     *
     * @param string $subject Email subject.
     * @param string $title   Email title.
     * @param string $message Email message.
     */
    protected function send_email( $subject, $title, $message ) {
        $mailer = WC()->mailer();

        $mailer->send( get_option( 'admin_email' ), $subject, $mailer->wrap_message( $title, $message ) );
    }

    /**
     * Payment fields.
     */
    public function payment_fields() {

        wp_enqueue_script( 'wc-credit-card-form' );

        $description = $this->get_description();

        if ( $description ) {
            echo wpautop( wptexturize( $description ) ); // WPCS: XSS ok.
        }

        $cart_total = $this->get_order_total();
        wc_get_template(
            'transparent-checkout-form.php', array(
            'cart_total'        => $cart_total,
            'tc_credit'         => $this->tc_credit,
            'tc_transfer'       => $this->tc_transfer,
            'tc_ticket'         => $this->tc_ticket,
            'tc_ticket_message' => $this->tc_ticket_message,
            'app_id' => $this->app_id(),
            'public_key' => $this->public_key(),
            'sandbox' => $this->sandbox,
            'flag'              => plugins_url( 'assets/images/brazilian-flag.png', plugin_dir_path( __FILE__ ) ),
        ), 'woocommerce/pay/', WC_pay::get_templates_path()
        );
    }
    /**
     * Money format.
     *
     * @param  int/float $value Value to fix.
     *
     * @return float            Fixed value.
     */
    protected function money_format( $value ) {
        return number_format( $value, 2, '.', '' );
    }

    /**
     * Process the payment and return the result.
     *
     * @param  int $order_id Order ID.
     * @return array
     */
    public function process_payment($order_id ) {

        $order = wc_get_order( $order_id );
        $data = (array)$order;
        $total    = $this->get_order_total();
        $exchange_rate = (float)$this->get_option('exchange_rate');
        if ( 'yes' === $this->debug ) {
            $this->log->add( $this->id, $order->get_total());
            $this->log->add( $this->id, $data);

        }
        if ($exchange_rate <= 0) {
            $exchange_rate = 1;
        }
        if($order->get_billing_country() == 'BR'){
            $regions = 'BRA';
        }else if($order->get_billing_country() == 'MX'){
            $regions = 'MEX';
        }else if($order->get_billing_country() == 'CL'){
            $regions = 'CHL';
        }else if($order->get_billing_country() == 'CO'){
            $regions = 'COL';
        }else if($order->get_billing_country() == 'AR'){
            $regions = 'ARG';
        }else if($order->get_billing_country() == 'PE'){
            $regions = 'PER';
        }else if($order->get_billing_country() == 'EC'){
            $regions = 'ECU';
        }else if($order->get_billing_country() == 'BO'){
            $regions = 'BOL';
        }
        $order_data = array(
            "app_id"=>$this->app_id(),
            "timestamp"=>date('Y-m-d H:i:s',time()),
            "out_trade_no"=>$order_id,
            // "method"=>"pay",
            "order_currency"=>get_woocommerce_currency(),
            "regions"=>array($regions),

            "order_amount"=>$order->get_total(),
            "subject"=>'subject',
            "content"=>'content',
            "notify_url"=>add_query_arg( 'wc-api', 'WC_pay_Gateway', home_url( '/' ) ),
            "return_url"=>$order->get_checkout_order_received_url( true ) ,

            "buyer_id"=>$_POST['billing_email'],
            "trade_type" => 'WEB',
            "customer"=>array(
                "name"=>$data["\0*\0data"]['billing']['first_name'].' '.$data["\0*\0data"]['billing']['last_name'],
                "email"=>$_POST['billing_email'],
                "phone"=>$_POST['billing_phone'],
            ),
        );
        $curl = $this->gateway_url().'/trade/create';
        $pag_response = $this->curl_post_json_header($curl,$order_data);
        $pag_response = json_decode($pag_response,true);
            if( $pag_response['code'] == "10000" && $pag_response['msg'] == "Success"){
                WC()->cart->empty_cart();
                $use_shipping = isset( $pag_response['web_url'] ) ? $pag_response['web_url'] : ''; // WPCS: input var ok, CSRF ok.
                return array(
                    'result'   => 'success',
                    'redirect' => $use_shipping
                );
            }else{
                wc_add_notice( $pag_response['msg'], 'error' );
                $order->update_status('cancelled',__('Missing Required Arguments','woocommerce-pay'));
                return array(
                    'result'   => $pag_response,
                    'redirect' => '',
                );
            }

    }

    public function check_ipn_response(){
        $sign = $this->GatewaySign(file_get_contents('php://input'));
        $data = json_decode(file_get_contents('php://input'),true);
        if ( 'yes' === $this->debug ) {
            $this->log->add( $this->id, file_get_contents('php://input') );
        }

        $order_id = $data['out_trade_no'];
        $order = wc_get_order($order_id);
        if ( 'yes' === $this->debug ) {
            $this->log->add( $this->id, $data );
            $this->log->add( $this->id, 'order_id : '.$order_id );
            $this->log->add( $this->id, 'sign : '.$sign );
        }
        if(!$sign){
            $order->update_status('pending',__('Awaiting check payment','woocommerce-pay'));
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'sign error : '.$sign );
            }
            echo "sign error";exit();
        }

        if($data['trade_status'] == 'SUCCESS'){
            
            $a = $order->update_status('completed',__('Awaiting check payment','woocommerce-pay'));
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'SUCCESS' );
                $this->log->add( $this->id, 'update status :'.$a );
            }
            echo "success";exit();
        }elseif ($data['trade_status'] == 'REFUND' || $data['trade_status'] =='REFUND_MER' || $data['trade_status'] =='REFUND_PRT'){
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'REFUND' );
            }
            $order->update_status('refunded',__('Awaiting check payment','woocommerce-pay'));
            echo 'success';exit;
        }elseif($data['trade_status'] == 'REFUSED'){
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'REFUSED' );
            }
            $order->update_status('failed',__('Awaiting check payment','woocommerce-pay'));
            echo 'success';exit();

        }elseif($data['trade_status'] == 'CANCEL'){
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'CANCEL' );
            }
            $order->update_status('cancelled',__('Awaiting check payment','woocommerce-pay'));
            echo 'success';exit();

        }elseif($data['trade_status'] == 'RISK_CONTROLLING'){
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'RISK_CONTROLLING' );
            }
            $order->update_status('pending',__('Awaiting check payment','woocommerce-pay'));
            echo 'success';exit();

        }elseif($data['trade_status'] == 'DISPUTE'){
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'DISPUTE' );
            }
            $order->update_status('pending',__('Awaiting check payment','woocommerce-pay'));
            echo 'success';exit();

        }elseif($data['trade_status'] == 'REFUNDED'){
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'REFUNDED' );
            }
            $order->update_status('refunded',__('Awaiting check payment','woocommerce-pay'));
            echo 'success';exit();

        }elseif($data['trade_status'] == 'CHARGEBACK'){
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'CHARGEBACK' );
            }
            $order->update_status('processing',__('Awaiting check payment','woocommerce-pay'));
            echo 'success';exit();

        }else{
            if ( 'yes' === $this->debug ) {
                $this->log->add( $this->id, 'error' );
            }
            echo $data['trade_status'];exit();
        }
    }

    private function GatewaySign($post_data){
        $header_sign_str = $_SERVER['HTTP_LARKPAY_SIGNATURE'];

        if(empty($header_sign_str)){
            return false;
        }

        $header_sign = $header_sign_str;
        //解析$header_sign_str
        $header_sign_arr = explode(',',$header_sign_str);//获取sign v2  时间t
        $header_sign_v2 = explode('=',$header_sign_arr['1']);//获取v2值
        $header_sign = $header_sign_v2['1'];
        $sign = hash_hmac('sha256',$post_data,$this->secret_key());
        if ( 'yes' === $this->debug ) {
            $this->log->add( $this->id, '-------sign---------' );
            $this->log->add( $this->id, $header_sign );
            $this->log->add( $this->id, '-------sign end-------' );
            $this->log->add( $this->id, $sign );
        }
        if($header_sign == $sign){
            return true;
        }else{
            return false;
        }
    }

    private function curl_post_json_header($url, $params) {
        $header = array(
            'Content-Type: application/json',
            'Authorization: Basic '.base64_encode($this->app_id().':'.$this->secret_key())
        );

        $data_string = json_encode ( $params );
        $ch = curl_init ();
        curl_setopt ( $ch, CURLOPT_POST, 1 );
        curl_setopt ( $ch, CURLOPT_URL, $url );
        curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)');
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
        curl_setopt($ch, CURLOPT_AUTOREFERER, 1);
        curl_setopt($ch, CURLOPT_REFERER, "http://XXX");
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
        curl_setopt ( $ch, CURLOPT_POSTFIELDS, $data_string );
        curl_setopt ( $ch, CURLOPT_HTTPHEADER, $header);
        ob_start ();
        curl_exec ( $ch );
        $return_content = ob_get_contents ();
        ob_end_clean ();
        if ( 'yes' === $this->debug ) {
            $this->log->add( $this->id, '-----------------------------');
            $this->log->add( $this->id, $url);
            $this->log->add( $this->id, $this->app_id().':'.$this->secret_key());
            $this->log->add( $this->id, json_encode($header));
            $this->log->add( $this->id, json_encode ( $params ));
            $this->log->add( $this->id, $return_content);
            $this->log->add( $this->id, '-----------------------------');
        }

        return $return_content;
    }
    /**
     * Output for the order received page.
     *
     * @param int $order_id Order ID.
     */
    public function receipt_page( $order_id ) {
        $order        = wc_get_order( $order_id );
        $order_data = array(
            "app_id"=>$this->app_id(),
            "timestamp"=>date('Y-m-d H:i:s',time()),
            "out_trade_no"=>(string)$order_id,
            "trade_no"=>'',
        );

        $curl = $this->gateway_url().'/trade/query';
        $pag_response = $this->curl_post_json_header($curl,$order_data);
        $pag_response = json_decode($pag_response,true);
        if ( 'yes' === $this->debug ) {
            $this->log->add( $this->id, json_encode($pag_response));
        }

        if($pag_response['code'] == 10000 && $pag_response['trade_status'] == "SUCCESS"){
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'Thank you for your order, credit card payment was successful.',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }elseif ($pag_response['trade_status'] == "RISK_CONTROLLING"){
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'Estamos processando o pagamento. Em até 2 dias úteis informaremos por e-mail se foi aprovado ou se precisamos de mais informações.',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }elseif ($pag_response['trade_status'] == "REFUSED"){
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'Seu pagamento foi recusado. Escolha outra forma de pagamento. Recomendamos meios de pagamento em dinheiro.',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }elseif ($pag_response['trade_status'] == "PROCESSING"){
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'Payment processing',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }elseif ($pag_response['trade_status'] == "CANCEL"){
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'Payment cancellation',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }elseif ($pag_response['trade_status'] == "DISPUTE"){
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'Dispute processing',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }elseif ($pag_response['trade_status'] == "REFUNDED"){
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'Refund occurred',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }elseif ($pag_response['trade_status'] == "CHARGEBACK"){
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'Chargeback occurred',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }else{
            wc_get_template(
                'lightbox-checkout.php', array(
                'cancel_order_url'    => $order->get_cancel_order_url(),
                'message'         => 'O pedido foi bem-sucedido. Verifique o e-mail para pagamento.',
                'lightbox_script_url' => $this->api->get_lightbox_url(),
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }
    }

    /**
     * IPN handler.
     */
    public function ipn_handler() {
        @ob_clean(); // phpcs:ignore Generic.PHP.NoSilencedErrors.Discouraged

        $ipn = $this->api->process_ipn_request( $_POST ); // WPCS: input var ok, CSRF ok.

        if ( $ipn ) {
            header( 'HTTP/1.1 200 OK' );
            do_action( 'valid_pay_ipn_request', $ipn );
            exit();
        } else {
            wp_die( esc_html__( 'pay Request Unauthorized', 'woocommerce-pay' ), esc_html__( 'pay Request Unauthorized', 'woocommerce-pay' ), array( 'response' => 401 ) );
        }
    }

    public function get_client_ip() {
        $ip = $_SERVER['REMOTE_ADDR'];
        if (isset($_SERVER['HTTP_CLIENT_IP']) && preg_match('/^([0-9]{1,3}\.){3}[0-9]{1,3}$/', $_SERVER['HTTP_CLIENT_IP'])) {
            $ip = $_SERVER['HTTP_CLIENT_IP'];
        } elseif(isset($_SERVER['HTTP_X_FORWARDED_FOR']) AND preg_match_all('#\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}#s', $_SERVER['HTTP_X_FORWARDED_FOR'], $matches)) {
            foreach ($matches[0] AS $xip) {
                if (!preg_match('#^(10|172\.16|192\.168)\.#', $xip)) {
                    $ip = $xip;
                    break;
                }
            }
        }
        return $ip;
    }

    /**
     * Save payment meta data.
     *
     * @param WC_Order $order Order instance.
     * @param array    $posted Posted data.
     */
    protected function save_payment_meta_data( $order, $posted ) {
        $meta_data    = array();
        $payment_data = array(
            'type'         => '',
            'method'       => '',
            'installments' => '',
            'link'         => '',
        );

        if ( isset( $posted->sender->email ) ) {
            $meta_data[ __( 'Payer email', 'woocommerce-pay' ) ] = sanitize_text_field( (string) $posted->sender->email );
        }
        if ( isset( $posted->sender->name ) ) {
            $meta_data[ __( 'Payer name', 'woocommerce-pay' ) ] = sanitize_text_field( (string) $posted->sender->name );
        }
        if ( isset( $posted->paymentMethod->type ) ) { // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar
            $payment_data['type'] = intval( $posted->paymentMethod->type ); // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar

            $meta_data[ __( 'Payment type', 'woocommerce-pay' ) ] = $this->api->get_payment_name_by_type( $payment_data['type'] );
        }
        if ( isset( $posted->paymentMethod->code ) ) { // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar
            $payment_data['method'] = $this->api->get_payment_method_name( intval( $posted->paymentMethod->code ) ); // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar

            $meta_data[ __( 'Payment method', 'woocommerce-pay' ) ] = $payment_data['method'];
        }
        if ( isset( $posted->installmentCount ) ) { // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar
            $payment_data['installments'] = sanitize_text_field( (string) $posted->installmentCount ); // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar

            $meta_data[ __( 'Installments', 'woocommerce-pay' ) ] = $payment_data['installments'];
        }
        if ( isset( $posted->paymentLink ) ) { // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar
            $payment_data['link'] = sanitize_text_field( (string) $posted->paymentLink ); // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar

            $meta_data[ __( 'Payment URL', 'woocommerce-pay' ) ] = $payment_data['link'];
        }
        if ( isset( $posted->creditorFees->intermediationRateAmount ) ) { // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar
            $meta_data[ __( 'Intermediation Rate', 'woocommerce-pay' ) ] = sanitize_text_field( (string) $posted->creditorFees->intermediationRateAmount ); // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar
        }
        if ( isset( $posted->creditorFees->intermediationFeeAmount ) ) { // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar
            $meta_data[ __( 'Intermediation Fee', 'woocommerce-pay' ) ] = sanitize_text_field( (string) $posted->creditorFees->intermediationFeeAmount ); // phpcs:ignore WordPress.NamingConventions.ValidVariableName.NotSnakeCaseMemberVar
        }

        $meta_data['_wc_pay_payment_data'] = $payment_data;

        // WooCommerce 3.0 or later.
        if ( method_exists( $order, 'update_meta_data' ) ) {
            foreach ( $meta_data as $key => $value ) {
                $order->update_meta_data( $key, $value );
            }
            $order->save();
        } else {
            foreach ( $meta_data as $key => $value ) {
                update_post_meta( $order->id, $key, $value );
            }
        }
    }

    /**
     * Update order status.
     *
     * @param array $posted pay post data.
     */
    public function update_order_status( $posted ) {
        if ( isset( $posted->reference ) ) {
            $id    = (int) str_replace( $this->invoice_prefix, '', $posted->reference );
            $order = wc_get_order( $id );

            // Check if order exists.
            if ( ! $order ) {
                return;
            }

            $order_id = method_exists( $order, 'get_id' ) ? $order->get_id() : $order->id;

            // Checks whether the invoice number matches the order.
            // If true processes the payment.
            if ( $order_id === $id ) {
                if ( 'yes' === $this->debug ) {
                    $this->log->add( $this->id, 'pay payment status for order ' . $order->get_order_number() . ' is: ' . intval( $posted->status ) );
                }

                // Save meta data.
                $this->save_payment_meta_data( $order, $posted );

                switch ( intval( $posted->status ) ) {
                    case 1:
                        $order->update_status( 'on-hold', __( 'pay: The buyer initiated the transaction, but so far the pay not received any payment information.', 'woocommerce-pay' ) );

                        break;
                    case 2:
                        $order->update_status( 'on-hold', __( 'pay： Payment under review.', 'woocommerce-pay' ) );

                        // Reduce stock for billets.
                        if ( function_exists( 'wc_reduce_stock_levels' ) ) {
                            wc_reduce_stock_levels( $order_id );
                        }

                        break;
                    case 3:
                        // Sometimes pay should change an order from cancelled to paid, so we need to handle it.
                        if ( method_exists( $order, 'get_status' ) && 'cancelled' === $order->get_status() ) {
                            $order->update_status( 'processing', __( 'pay： Payment approved.', 'woocommerce-pay' ) );
                            wc_reduce_stock_levels( $order_id );
                        } else {
                            $order->add_order_note( __( 'pay： Payment approved.', 'woocommerce-pay' ) );

                            // Changing the order for processing and reduces the stock.
                            $order->payment_complete( sanitize_text_field( (string) $posted->code ) );
                        }

                        break;
                    case 4:
                        $order->add_order_note( __( 'pay： Payment completed and credited to your account.', 'woocommerce-pay' ) );

                        break;
                    case 5:
                        $order->update_status( 'on-hold', __( 'pay： Payment came into dispute.', 'woocommerce-pay' ) );
                        $this->send_email(
                        /* translators: %s: order number */
                            sprintf( __( 'Payment for order %s came into dispute', 'woocommerce-pay' ), $order->get_order_number() ),
                            __( 'Payment in dispute', 'woocommerce-pay' ),
                            /* translators: %s: order number */
                            sprintf( __( 'Order %s has been marked as on-hold, because the payment came into dispute in pay.', 'woocommerce-pay' ), $order->get_order_number() )
                        );

                        break;
                    case 6:
                        $order->update_status( 'refunded', __( 'pay： Payment refunded.', 'woocommerce-pay' ) );
                        $this->send_email(
                        /* translators: %s: order number */
                            sprintf( __( 'Payment for order %s refunded', 'woocommerce-pay' ), $order->get_order_number() ),
                            __( 'Payment refunded', 'woocommerce-pay' ),
                            /* translators: %s: order number */
                            sprintf( __( 'Order %s has been marked as refunded by pay.', 'woocommerce-pay' ), $order->get_order_number() )
                        );

                        if ( function_exists( 'wc_increase_stock_levels' ) ) {
                            wc_increase_stock_levels( $order_id );
                        }

                        break;
                    case 7:
                        $order->update_status( 'cancelled', __( 'pay： Payment canceled.', 'woocommerce-pay' ) );

                        if ( function_exists( 'wc_increase_stock_levels' ) ) {
                            wc_increase_stock_levels( $order_id );
                        }

                        break;

                    default:
                        break;
                }
            } else {
                if ( 'yes' === $this->debug ) {
                    $this->log->add( $this->id, 'Error: Order Key does not match with pay reference.' );
                }
            }
        }
    }

    /**
     * Thank You page message.
     *
     * @param int $order_id Order ID.
     */
    public function thankyou_page( $order_id ) {
        $order = wc_get_order( $order_id );
        // WooCommerce 3.0 or later.
        if ( method_exists( $order, 'get_meta' ) ) {
            $data = $order->get_meta( '_wc_pay_payment_data' );
        } else {
            $data = get_post_meta( $order->id, '_wc_pay_payment_data', true );
        }

        if ( isset( $data['type'] ) ) {
            wc_get_template(
                'payment-instructions.php', array(
                'type'         => $data['type'],
                'link'         => $data['link'],
                'method'       => $data['method'],
                'installments' => $data['installments'],
            ), 'woocommerce/pay/', WC_pay::get_templates_path()
            );
        }
    }

    /**
     * Add content to the WC emails.
     *
     * @param  WC_Order $order         Order object.
     * @param  bool     $sent_to_admin Send to admin.
     * @param  bool     $plain_text    Plain text or HTML.
     * @return string
     */
    public function email_instructions( $order, $sent_to_admin, $plain_text = false ) {
        // WooCommerce 3.0 or later.
        if ( method_exists( $order, 'get_meta' ) ) {
            if ( $sent_to_admin || 'on-hold' !== $order->get_status() || $this->id !== $order->get_payment_method() ) {
                return;
            }

            $data = $order->get_meta( '_wc_pay_payment_data' );
        } else {
            if ( $sent_to_admin || 'on-hold' !== $order->status || $this->id !== $order->payment_method ) {
                return;
            }

            $data = get_post_meta( $order->id, '_wc_pay_payment_data', true );
        }

        if ( isset( $data['type'] ) ) {
            if ( $plain_text ) {
                wc_get_template(
                    'emails/plain-instructions.php', array(
                    'type'         => $data['type'],
                    'link'         => $data['link'],
                    'method'       => $data['method'],
                    'installments' => $data['installments'],
                ), 'woocommerce/pay/', WC_pay::get_templates_path()
                );
            } else {
                wc_get_template(
                    'emails/html-instructions.php', array(
                    'type'         => $data['type'],
                    'link'         => $data['link'],
                    'method'       => $data['method'],
                    'installments' => $data['installments'],
                ), 'woocommerce/pay/', WC_pay::get_templates_path()
                );
            }
        }
    }
}
