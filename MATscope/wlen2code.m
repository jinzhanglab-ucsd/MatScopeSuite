function code = wlen2code(wlen)
    word = decimal2binary(wlen, 16, 'left-msb');
    low_order = binary2decimal(word(9:16), 'left-msb');
    high_order = binary2decimal(word(1:8), 'left-msb');
    code = [low_order high_order];
end