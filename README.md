# OTPencryptedAjax
increase http security with a one-time-PIN you calculate yourself. 
Ajax traffic will be -aes-256-cbc encrypted even before you send the password


This is how it works:

The login screen looks like this:

     username:  ___________
     challenge: ___________
     PIN:       ___________
                  [decrypt]

after the user enters his username, he will be given a random number
in the challenge field. With the challenge the user doesn't have to 
enter his secret PIN to the web-form. Instead he or she uses the 
following algorithm to calculate a one-time PIN.

For example if challenge = 306 and the users secret PIN = 810,
I calculate the one-time-PIN by first adding the numbers digit-by-digit
without carry (modulo 10):

     (3 + 8)%10 = 1
      0 + 1     = 1
      6 + 0     = 6

and in the second step I add those results together.
So in this case the one-time-PIN would be 8.

After the user enters the PIN and presses [decrypt] he or she will see 
his or her avatar (ensuring the user is not connected to a fake website) 
and a password input field at the place, 
where the "challenge" and "PIN" fields have been before.


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

Currently get_callenge() reveals usernames, because the challenge
contains as many digits as the secret PIN of the user. If the username
is unknown, it returns a challenge of random length, and is thereby
revealing it doesn't know the user. (can be fixed easily)

What is more difficult to fix, is the problem with a short keyspace:
Unless you have a very long secret PIN (more than 20 digits),
which makes it a hassle to calculate the one-time-PIN from,
the AES encryption can easily be broken with a brute-force attack.
It took me 0.2 seconds to find the key for a 8-digit PIN.
Please write me, if you have any ideas.

TODO

Calculate the SHA256sums of all javascript code within javascript
code and transfer the results in the first encrypted request.
The server can then warn the user with another avatar,
if the code is injected with a backdoor.

"But if a MITM can inject the javascript code, why can't he
replace those ^^checks as well?", you might ask.

Well yes, MITM could replace those checks and i.e. send some
static SHA256sums instead, but it becomes more difficult
for MITM to fake the correct SHA256sums, if the server varies
the javascripts (and thereby the SHA256sums of those)
with every request.
