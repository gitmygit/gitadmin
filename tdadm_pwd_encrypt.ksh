#!/bin/ksh

print -n "Enter Passphrase: "
stty -echo
read pass
stty echo
print "\n"

# Validate Input Job Parameters
if [ X"$pass" = X ] ; then
        echo "[Error] No input"
        exit 1
fi

print -n "Re-enter Passphrase: "
stty -echo
read pass1
stty echo
print "\n"
if [ "$pass" != "$pass1" ] ; then
        echo "[Error] Password mismatch"
        exit 2
fi

print "\n"

set +x

/tdadm/bin/password_encryption/Password_Encryption/Password_Encryption_run.sh --context_param Password="$pass"


