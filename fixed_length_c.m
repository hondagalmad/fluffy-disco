function fixed_length_c(app, output_filename)
    % Construct full input file path
    input_fullpath = fullfile(app.filepath, app.filename);
    
    % Read input file
    fid = fopen(input_fullpath, 'rb');
    file_data = fread(fid, inf, 'uint8')';
    fclose(fid);
    
    % Get unique symbols
    symbols = unique(file_data);
    n = length(symbols);
    
    % Calculate bits per symbol: ceil(log2(n))
    if n == 1
        bits_per_symbol = 1;
    else
        bits_per_symbol = ceil(log2(n));
    end
    
    % Build Fixed-Length dictionary: each symbol gets same number of bits
    dict = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    for i = 1:n
        dict(symbols(i)) = dec2bin(i-1, bits_per_symbol);
    end
    
    % Encode the data
    encoded_data = '';
    for i = 1:length(file_data)
        encoded_data = [encoded_data, dict(file_data(i))];
    end
    
    % Save compressed file
    output_fullpath = fullfile(app.filepath, output_filename);
    save_fixed_compressed(output_fullpath, encoded_data, dict, symbols, bits_per_symbol);
end

function save_fixed_compressed(filename, encoded_data, dict, symbols, bits_per_symbol)
    fid = fopen(filename, 'wb');
    
    % Write header: number of symbols + symbols + bits_per_symbol
    fwrite(fid, length(symbols), 'uint32');
    fwrite(fid, symbols, 'uint8');
    fwrite(fid, bits_per_symbol, 'uint8');
    
    % Pad encoded data to multiple of 8
    padding_needed = mod(8 - mod(length(encoded_data), 8), 8);
    padded_data = [encoded_data, repmat('0', 1, padding_needed)];
    
    % Convert binary string to bytes
    num_bytes = length(padded_data) / 8;
    bytes = zeros(1, num_bytes, 'uint8');
    for i = 1:num_bytes
        byte_str = padded_data((i-1)*8+1 : i*8);
        bytes(i) = bin2dec(byte_str);
    end
    
    fwrite(fid, padding_needed, 'uint8');
    fwrite(fid, bytes, 'uint8');
    
    fclose(fid);
end
