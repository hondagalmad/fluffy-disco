function variable_length_c(app, output_filename)
    % Construct full input file path
    input_fullpath = fullfile(app.filepath, app.filename);
    
    % Read input file
    fid = fopen(input_fullpath, 'rb');
    file_data = fread(fid, inf, 'uint8')';
    fclose(fid);
    
    % Calculate symbol frequencies
    symbols = unique(file_data);
    frequencies = zeros(1, length(symbols));
    for i = 1:length(symbols)
        frequencies(i) = sum(file_data == symbols(i));
    end
    
    % Build Variable-Length dictionary (Huffman)
    dict = variable_dict(symbols, frequencies);
    
    % Encode the data
    encoded_data = '';
    for i = 1:length(file_data)
        encoded_data = [encoded_data, dict(file_data(i))];
    end
    
    % Save compressed file
    output_fullpath = fullfile(app.filepath, output_filename);
    save_variable_compressed(output_fullpath, encoded_data, dict, symbols, frequencies);
end

function dict = variable_dict(symbols, frequencies)
    n = length(symbols);
    
    % Initialize leaf nodes
    nodes = struct('symbol', [], 'freq', [], 'left', [], 'right', []);
    for i = 1:n
        nodes(i).symbol = symbols(i);
        nodes(i).freq   = frequencies(i);
        nodes(i).left   = [];
        nodes(i).right  = [];
    end
    
    % Build Huffman tree
    while length(nodes) > 1
        [~, idx] = sort([nodes.freq]);
        nodes = nodes(idx);
        
        new_node.symbol = [];
        new_node.freq   = nodes(1).freq + nodes(2).freq;
        new_node.left   = nodes(1);
        new_node.right  = nodes(2);
        
        nodes = [nodes(3:end), new_node];
    end
    
    % Assign variable-length codes by traversing tree
    dict = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    traverse_tree(nodes(1), '');
    
    % Handle single-symbol edge case
    if length(keys(dict)) == 1
        k = keys(dict);
        dict(k{1}) = '0';
    end
    
    function traverse_tree(node, code)
        if isempty(node.symbol)
            if ~isempty(node.left)
                traverse_tree(node.left,  [code, '0']);
            end
            if ~isempty(node.right)
                traverse_tree(node.right, [code, '1']);
            end
        else
            dict(node.symbol) = code;
        end
    end
end

function save_variable_compressed(filename, encoded_data, dict, symbols, frequencies)
    fid = fopen(filename, 'wb');
    
    % Write header: number of symbols + symbols + frequencies
    fwrite(fid, length(symbols), 'uint32');
    fwrite(fid, symbols, 'uint8');
    fwrite(fid, frequencies, 'uint32');
    
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
