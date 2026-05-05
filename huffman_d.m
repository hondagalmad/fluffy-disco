function huffman_d(app, output_filename)
    % Decompresses the file and saves as text file
    % Input: output_filename - name for the decompressed text output file
    % The compressed input file is app.filename from app
    
    input_fullpath = fullfile(app.filepath, app.filename);
    output_fullpath = fullfile(app.filepath, output_filename);
    
    [encoded_bits, symbols, frequencies, padding_needed] = load_compressed(input_fullpath);
    
    dict = huffman_dict(symbols, frequencies);
    
    reverse_dict = containers.Map('KeyType', 'char', 'ValueType', 'any');
    keys_list = keys(dict);
    for i = 1:length(keys_list)
        reverse_dict(dict(keys_list{i})) = keys_list{i};
    end
    
    decoded_data = [];
    current_code = '';
    
    for i = 1:length(encoded_bits)
        current_code = [current_code, encoded_bits(i)];
        if isKey(reverse_dict, current_code)
            decoded_data = [decoded_data, reverse_dict(current_code)];
            current_code = '';
        end
    end
    
    % Convert numeric bytes to characters and save as text file
    decoded_text = char(decoded_data);
    
    fid = fopen(output_fullpath, 'w');
    fprintf(fid, '%s', decoded_text);
    fclose(fid);
end

function [encoded_bits, symbols, frequencies, padding_needed] = load_compressed(filename)
    fid = fopen(filename, 'rb');
    
    num_symbols = fread(fid, 1, 'uint32');
    symbols = fread(fid, num_symbols, 'uint8')';
    frequencies = fread(fid, num_symbols, 'uint32')';
    padding_needed = fread(fid, 1, 'uint8');
    
    bytes = fread(fid, inf, 'uint8')';
    fclose(fid);
    
    encoded_bits = '';
    for i = 1:length(bytes)
        byte_str = dec2bin(bytes(i), 8);
        encoded_bits = [encoded_bits, byte_str];
    end
    
    if padding_needed > 0
        encoded_bits = encoded_bits(1:end-padding_needed);
    end
end

function dict = huffman_dict(symbols, frequencies)
    n = length(symbols);
    
    nodes = struct('symbol', [], 'freq', [], 'left', [], 'right', []);
    for i = 1:n
        nodes(i).symbol = symbols(i);
        nodes(i).freq = frequencies(i);
        nodes(i).left = [];
        nodes(i).right = [];
    end
    
    while length(nodes) > 1
        [~, idx] = sort([nodes.freq]);
        nodes = nodes(idx);
        
        new_node.symbol = [];
        new_node.freq = nodes(1).freq + nodes(2).freq;
        new_node.left = nodes(1);
        new_node.right = nodes(2);
        
        nodes = [nodes(3:end), new_node];
    end
    
    dict = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    traverse_tree(nodes(1), '');
    
    function traverse_tree(node, code)
        if isempty(node.symbol)
            if ~isempty(node.left)
                traverse_tree(node.left, [code, '0']);
            end
            if ~isempty(node.right)
                traverse_tree(node.right, [code, '1']);
            end
        else
            dict(node.symbol) = code;
        end
    end
end