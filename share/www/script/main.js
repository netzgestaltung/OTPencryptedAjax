/**
 * OTPencryptedAjax
 * ================
 * this is the main program
 * 
 * @author: Raphael Wegmann
 * @url: https://github.com/raph431/OTPencryptedAjax
 */

function get_challenge (username) {
        var username = document.getElementById("login-username").value;
        
        console.log("get_challenge() was called with " + username);
        
        nanoajax.ajax('/index.cgi?rm=get_challenge&username=' + username, function (code, challenge) { 
          console.log("rm=get_challenge?username .. returned code " + code);
          if ( code == 200 ) {
            console.log("rm=get_challenge?username .. returned text " + challenge);
            var res = JSON.parse(challenge);
            document.getElementById("challenge").value = res.randomA;
          }
        });
}

function decrypt_form(form) {
      
   console.log("form e: " + (form));
   var username = document.getElementById("login-username").value;
   var pin      = document.getElementById("pin").value;
//   var client_ip = <!-- TMPL_VAR client_ip -->;
 
 // at this point we have no idea, whether our OTP is correct or not

   var myHashes_serialized = "/index.cgi:"+myHashes["/index.cgi"]+',';
   var cryptoJsDir = "/ext/crypto/";
   var flist = ["core.js", "enc-base64.js", "md5.js", "evpkdf.js", "cipher-core.js", "aes.js", "sha256.js"];
   for (f in flist) {
       myHashes_serialized += cryptoJsDir+flist[f] + ':' + myHashes[cryptoJsDir+flist[f]]+',';
   }
   myHashes_serialized += "/script/main.js:"+myHashes["/script/main.js"];
   console.log("serialized hashes ["+myHashes_serialized+"]");
   var hash_of_hashes = CryptoJS.SHA256(myHashes_serialized).toString();
   console.log("hash of hashes ["+hash_of_hashes+"]");

   var plaintext_request = '{"get": "password_field", '
                          +'"hash": "'+ hash_of_hashes +'"}';
   console.log("plaintext_request ["+plaintext_request+"]");
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
          var otp_section = document.getElementById("otp-section");
          otp_section.innerHTML = plaintext;
       }
   });
}
   
// hopefully this runs immediately
  
  document.addEventListener('DOMContentLoaded', function(event) { 
    var usernameInput = document.getElementById('login-username');
    var     loginForm = document.getElementById('login');
        
    usernameInput.addEventListener('blur', function(event) { 
      var username = this.value;
      
      if ( username.length > 0 ) {
        get_challenge(username);
console.log("myHashes: "+JSON.stringify(myHashes));
      }
    });
    
    loginForm.addEventListener('submit', function(event){
      decrypt_form(this);
      if (event.preventDefault) {
        event.preventDefault();
      } else {
        event.returnValue = false;
      }
    });
  });


