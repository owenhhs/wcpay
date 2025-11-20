(function ( $ ) {
	'use strict';

	$( function () {

		/**
		 * Switch transparent checkout options display basead in payment type.
		 *
		 * @param {String} method
		 */
		function SwitchTCOptions( method ) {
			var fields  = $( '#woocommerce__tc_credit' ).closest( '.form-table' ),
				heading = fields.prev( 'h3' );

			console.log( 'foi?' );

			if ( 'transparent' === method ) {
				fields.show();
				heading.show();
			} else {
				fields.hide();
				heading.hide();
			}
		}

		/**
		 * Switch banking ticket message display.
		 *
		 * @param {String} checked
		 */
		function SwitchOptions( checked ) {
			var fields = $( '#woocommerce__tc_ticket_message' ).closest( 'tr' );

			if ( checked ) {
				fields.show();
			} else {
				fields.hide();
			}
		}

		/**
		 * Awitch user data for sandbox and production.
		 *
		 * @param {String} checked
		 */
		function SwitchUserData( checked ) {
			var email = $( '#woocommerce__email' ).closest( 'tr' ),
				token = $( '#woocommerce__token' ).closest( 'tr' ),
				sandboxEmail = $( '#woocommerce__sandbox_email' ).closest( 'tr' ),
				sandboxToken = $( '#woocommerce__sandbox_token' ).closest( 'tr' );

			if ( checked ) {
				email.hide();
				token.hide();
				sandboxEmail.show();
				sandboxToken.show();
			} else {
				email.show();
				token.show();
				sandboxEmail.hide();
				sandboxToken.hide();
			}
		}

		SwitchTCOptions( $( '#woocommerce__method' ).val() );

		$( 'body' ).on( 'change', '#woocommerce__method', function () {
			SwitchTCOptions( $( this ).val() );
		}).change();

		SwitchOptions( $( '#woocommerce__tc_ticket' ).is( ':checked' ) );
		$( 'body' ).on( 'change', '#woocommerce__tc_ticket', function () {
			SwitchOptions( $( this ).is( ':checked' ) );
		});

		SwitchUserData( $( '#woocommerce__sandbox' ).is( ':checked' ) );
		$( 'body' ).on( 'change', '#woocommerce__sandbox', function () {
			SwitchUserData( $( this ).is( ':checked' ) );
		});
	});

}( jQuery ));
