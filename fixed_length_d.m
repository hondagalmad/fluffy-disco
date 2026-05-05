function fixed_length_d(app, output_filename)
    % Construct full input file path
    input_fullpath = fullfile(app.filepath, app.filename);
    
    % Read compressed file
    fid = fopen(input_fullpath, 'rb');
    
    % Read header
    num_symbols    = fread(fid, 1, 'uint32');
    symbols        = fread(fid, num_symbols, 'uint8')';
    bits_per_symbol = fread(fid, 1, 'uint8');
    
    % Rebuild dictionary: index -> symbol
    dict = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
    for i = 1:num_symbols
        dict(dec2bin(i-1, bits_per_symbol)) = symbols(i);
    end
    
    % Read padding info and compressed bytes
    padding_needed = fread(fid, 1, 'uint8');
    bytes          = fread(fid, inf, 'uint8')';
    
    fclose(fid);
    
    % Convert bytes back to binary string
    binary_str = '';
    for i = 1:length(bytes)
        binary_str = [binary_str, dec2bin(bytes(i), 8)];
    end
    
    % Remove padding
    if padding_needed > 0
        binary_str = binary_str(1 : end - padding_needed);
    end
    
    % Decode: read bits_per_symbol bits at a time
    decoded_data = zeros(1, length(binary_str) / bits_per_symbol, 'uint8');
    idx = 1;
    for i = 1 : bits_per_symbol : length(binary_str)
        code = binary_str(i : i + bits_per_symbol - 1);
        if isKey(dict, code)
            decoded_data(idx) = dict(code);
            idx = idx + 1;
        end
    end
    decoded_data = decoded_data(1:idx-1);
    
    % Write output file
    output_fullpath = fullfile(app.filepath, output_filename);
    fid = fopen(output_fullpath, 'wb');
    fwrite(fid, decoded_data, 'uint8');
    fclose(fid);
end
