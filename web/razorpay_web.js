window.openRazorpayCheckout = function(optionsJson, onSuccess, onFailed) {
  var options = JSON.parse(optionsJson);
  
  // Custom success handler
  options.handler = function (response) {
    onSuccess(response.razorpay_payment_id);
  };

  var rzp = new Razorpay(options);

  // Custom failure handler
  rzp.on('payment.failed', function (response) {
    onFailed(response.error.description || 'Payment Failed');
  });

  rzp.open();
};
