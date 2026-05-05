function variable_length_d(app, output_filename)
    % Construct full input file path
    input_fullpath = fullfile(app.filepath, app.filename);
    
    % Read compressed file
    fid = fopen(input_fullpath, 'rb');
    
    % Read header
    num_symbols = fread(fid, 1, 'uint32');
    symbols     = fread(fid, num_symbols, 'uint8')';
    frequencies = fread(fid, num_symbols, 'uint32')';
    
    % Read padding and compressed bytes
    padding_needed = fread(fid, 1, 'uint8');
    bytes          = fread(fid, inf, 'uint8')';
    
    fclose(fid);
    
    % Rebuild Huffman tree and dictionary from symbols + frequencies
    dict = variable_dict(symbols, frequencies);
    
    % Reverse dictionary: code -> symbol
    keysList   = keys(dict);
    valuesList = values(dict);
    rev_dict   = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
    for i = 1:length(keysList)
        rev_dict(valuesList{i}) = keysList{i};
    end
    
    % Convert bytes back to binary string
    binary_str = '';
    for i = 1:length(bytes)
        binary_str = [binary_str, dec2bin(bytes(i), 8)];
    end
    
    % Remove padding
    if padding_needed > 0
        binary_str = binary_str(1 : end - padding_needed);
    end
    
    % Decode using prefix matching
    decoded_data = zeros(1, length(binary_str), 'uint8');
    buffer = '';
    idx    = 1;
    
    for i = 1:length(binary_str)
        buffer = [buffer, binary_str(i)];
        if isKey(rev_dict, buffer)
            decoded_data(idx) = rev_dict(buffer);
            idx    = idx + 1;
            buffer = '';
        end
    end
    decoded_data = decoded_data(1:idx-1);
    
    % Write output file
    output_fullpath = fullfile(app.filepath, output_filename);
    fid = fopen(output_fullpath, 'wb');
    fwrite(fid, decoded_data, 'uint8');
    fclose(fid);
end

% -------------------------------------------------------
function dict = variable_dict(symbols, frequencies)
    n = length(symbols);
    
    nodes = struct('symbol', [], 'freq', [], 'left', [], 'right', []);
    for i = 1:n
        nodes(i).symbol = symbols(i);
        nodes(i).freq   = frequencies(i);
        nodes(i).left   = [];
        nodes(i).right  = [];
    end
    
    while length(nodes) > 1
        [~, idx] = sort([nodes.freq]);
        nodes = nodes(idx);
        
        new_node.symbol = [];
        new_node.freq   = nodes(1).freq + nodes(2).freq;
        new_node.left   = nodes(1);
        new_node.right  = nodes(2);
        
        nodes = [nodes(3:end), new_node];
    end
    
    dict = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    traverse_tree(nodes(1), '');
    
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
