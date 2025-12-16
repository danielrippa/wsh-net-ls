
  do ->

    encode = -> encodeURIComponent it
    decode = -> decodeURICompontnt it

    encode-object = (object) -> [ "#{ encode key }=#{ encode value }" for key, value of object ] * '&'

    {
      encode, decode, encode-object
    }