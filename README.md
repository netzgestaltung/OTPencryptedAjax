# OTPencryptedAjax
Increase http security with a one-time-PIN you calculate yourself. 
Ajax traffic will be -aes-256-cbc encrypted even before you send the password


This is how it works:

The login screen looks like this:

     username:  ___________
     challenge: ___________
     PIN:       ___________
                  [decrypt]

After the user enters his username, he will be given a random number
in the challenge field. With the challenge the user doesn't have to 
enter his secret PIN to the web-form. Instead he or she uses the 
following algorithm to calculate a one-time PIN.

For example if challenge = 306 and the users secret PIN = 810,
I calculate the one-time-PIN by first adding the numbers digit-by-digit
without carry (modulo 10):

     challenge:    3 0 6
     secret PIN:   8 1 0
     ===================
     one-time PIN: 1+1+6 = 8

and in the second step I add those results together.
So in this case the one-time-PIN would be 8.

After the user enters the PIN and presses [decrypt] he or she will see 
his or her avatar (ensuring the user is not connected to a fake website) 
and a password input field at the place, where the "challenge" and "PIN" 
fields have been before.


     username:  ___________
       |\_/|   
      / @ @ \ 
     ( > º < )
      `>>x<<´ 
      /  O  \ 
     password:  ___________
                    [login]

WARNING
Please don't use it with a short secret PIN.

A small keyspace is still a problem:
Unless you have a very long secret PIN (more than 20 digits),
which makes it a hassle to calculate the one-time-PIN from,
the AES encryption can easily be broken with a brute-force attack.
It took me 0.2 seconds to find the key for a 8-digit PIN.
Please write me, if you have any ideas.
I just added the perl-script "calculate-OTP.pl", which can be used
to calculate really long one-time-PINs. Since I don't use any BigInt
library yet, one-time-PINs are currently limited in length (<20 digits).

Document verification to prevent injections

I calculate the SHA256sums of all javascript code within javascript
code and transfer a SHA256sum of those hashes in the first encrypted request.
The server can now warn the user with another avatar, if the code is injected 
with a backdoor.

"But if a MITM can inject the javascript code, why can't he
replace those ^^checks as well?", you might ask.

Well yes, MITM could replace those checks and i.e. send some
static SHA256sums instead, but it becomes more difficult
for MITM to fake the correct SHA256sums, if the server varies
the javascripts (and thereby the SHA256sums of those)
with every request. (<- that's still a TODO)
