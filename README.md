# OTPencryptedAjax
increase http security with a one-time-PIN you calculate yourself. 
Ajax traffic will be -aes-256-cbc encrypted even before you send the password


Please don't use it with a short secret PIN.

Currently get_callenge() reveals usernames, because the challenge
contains as many digits as the secret PIN of the user. If the username
is unknown, it returns a challenge of random length, and is thereby
revealing it doesn't know the user. (can be easily fixed)

What is more difficult to fix, is the problem with a short keyspace:
Unless you have a very long secret PIN (more than 20 digits),
which makes it a hassle to calculate the one-time-PIN from,
the AES encryption can easily broken with a brute-force attack.
It took me 0.2 seconds to find the key for a 8-digit PIN.
Please write me, if you have any ideas.

