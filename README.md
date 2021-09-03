
Password and Pin Generator
==========================

Generate a set of passwords and pin codes derived from
input string given by user.

The inspiration to this program came from PassGen sailfish application,
which is good software but did not create pin codes. Also, instead of
having multiple fields in UI, user can just structure the data to one
input field, in any way user desires.

This program generates different keys from same input than PassGen
(or any other of these applications (AFAIK all of those generate
different keys)). I think it is good, more entropy is good in this
field.

Four lines of "codes" are generated:

1. 5 groups of 8 characters; "evenly" from "alphabet" of 64 characters

2. 5 groups of 8 characters; each 8-character group has at least one
   character in [a-z], one in [A-Z], one in [0-9] and one in [%+,-./:=]

3. 5 groups of 8 characters; "evenly" from "alphabet" of 64 characters

4. 9 groups of 4 characters; evenly from [0-9] (pin codes)

The 64 character "alphabet" is `ACDEFGHJKLMNPQRTUVWXYZ` (22) +
`abcdefghijkmnpqrstuvwxyz` (24) + `0123456789` (10) + `%+,-./:=` (8).

The 32 character "alphabet" is `abcdefghijklmnopqrstuvwxyz234679`
(I just noticed that almost 'The Base 32 Alphabet' in RFC 4648)
-- `5` instead of `9` there.

If output has character that are not allowed in some service, just
replace it with some other char (or choose next in line).

Have a semi-secret memorizable plan how to create input strings for
services the generated passwords are to be used.

Install
-------

In CLI use, just copy/symlink the python application (or compile
the C 'ref' version with `sh pwpingen-ref.sh`)

For Sailfish use, install the .noarch package from repo. If you find
out how to build the package (pwpingen.spec has info how I did it,
but I am not sure how that should actually be done).

Tech
----

The codes are derived using blake2b (512bit) hash algoritm. There is
prefix string to which user input is appended and all this hashed.
After half of the bytes (32 bytes, 256 bits) of the hash output is
consumed, the whole 64 bytes (512 bits) of data is re-hashed with
the same blake2b and the same byte consumption cycle is restarted.
Argon2 uses pretty much the same procedure to get more input data;
previous incarnation of the key derivation used that -- but then
I thought that is too complex and it would have been harder to
create the C "reference" implementation.
