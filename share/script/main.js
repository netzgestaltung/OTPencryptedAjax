/**
 * OTPencryptedAjax
 * ================
 * this is the main program
 * 
 * @author: Raphael Wegmann
 * @url: https://github.com/raph431/OTPencryptedAjax
 */
;(function(CryptoJS, nanoajax){
  var get_challenge = function get_challenge (username) {
        var username = document.getElementById("username").value;
        
        console.log("get_challenge() was called with " + username);
        
        nanoajax.ajax('/index.cgi?rm=get_challenge&username = ' + username, function (code, challenge) { 
          console.log("rm=get_challenge?username .. returned code " + code);
          if ( code == 200 ) {
            console.log("rm=get_challenge?username .. returned text " + challenge);
            var res = JSON.parse(challenge);
            document.getElementById("challenge").value = res.randomA;
          }
        });
      },
      decrypt_form = function decrypt_form(form) {
      
        console.log("form e: " + (form));
        var username = document.getElementById("username").value;
        var pin      = document.getElementById("pin").value;
        var client_ip = <!-- TMPL_VAR client_ip -->;
      
      // at this point we have no idea, whether our OTP is correct or not
      
        var plaintext_request = '{"get": "password_field"}';
        var hashed_pin = CryptoJS.SHA256(pin).toString().toUpperCase();
      
        var crypted_request = CryptoJS.AES.encrypt(plaintext_request, hashed_pin).toString();
        var request_string = crypted_request.replace('+', '#', 'g');
      
        nanoajax.ajax({ url: '/index.cgi', method: 'POST', 
                 body: 'rm=enc_req&username='+username+'&DATA='+request_string},
          function (code, HTML_CODE, request) { 
            console.log("get password_field .. returned code "+code);
            if (code == 200) {
               var HTML_CODE_oneline = HTML_CODE.replace('\n', '', 'g');
               var decrypted = CryptoJS.AES.decrypt(HTML_CODE_oneline, hashed_pin);
               var plaintext = decrypted.toString(CryptoJS.enc.Latin1);
               var otp  = document.getElementById("otp");
               otp.innerHTML = plaintext;
            }
        });
      };
   
  
  document.addEventListener("DOMContentLoaded", function(event) { 
    var userobj = document.getElementById("username"),
        loginForm = document.getElementById('login');
        
    userobj.addEventListener("blur", function(event) { 
      var uservalue = userobj.value;
      
      if ( uservalue.length > 0 ) {
        get_challenge(uservalue);
      }
    });
    
    loginForm.addEventListener('submit', function(event){
      decrypt_form(this);
      return false;
    });
  });
})(CryptoJS, nanoajax);
