function localip --description 'Print en0 IPv4 address'
    ifconfig en0 | grep 'net[ ]' | awk '{print $2}'
end
