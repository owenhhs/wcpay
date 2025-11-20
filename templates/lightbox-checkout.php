<?php
/**
 * Lightbox checkout.
 *
 * @author  Claudio_Sanches
 * @package WooCommerce_wallet/Templates
 * @version 2.10.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit; // Exit if accessed directly.
}
?>
<div style="text-align: center;">
    <p id="browser-no-has-javascript"><?php _e( 'Automatically jump to payment after three seconds.', 'woocommerce-wallet' ); ?></p>
    <div id="qrcode" style="width:200px; height:200px; margin:0 auto"></div>
    <input type="hidden" id="pay_url" value="<?php echo $_GET['use_shipping']?>">
</div>

<script type="text/javascript">
    function pay(){
        if("<?php echo $_GET['use_shipping']?>")
        window.location.href="<?php echo $_GET['use_shipping']?>";
    }
    setInterval("pay()", 3000);
</script>



