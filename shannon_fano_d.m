function shannon_fano_d(app, output_filename)
    % Decompresses the file and saves as text file
    input_fullpath = fullfile(app.filepath, app.filename);
    output_fullpath = fullfile(app.filepath, output_filename);

    [encoded_bits, symbols, frequencies] = load_compressed(input_fullpath);

    [sorted_symbols, sorted_frequencies] = sort_by_frequency(symbols, frequencies);
    dict = shannon_fano_dict(sorted_symbols, sorted_frequencies);

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

function [encoded_bits, symbols, frequencies] = load_compressed(filename)
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

function [sorted_symbols, sorted_frequencies] = sort_by_frequency(symbols, frequencies)
    [sorted_frequencies, idx] = sort(double(frequencies), 'descend');
    sorted_symbols = symbols(idx);
    sorted_frequencies = uint32(sorted_frequencies);
end

function dict = shannon_fano_dict(symbols, frequencies)
    dict = containers.Map('KeyType', 'uint32', 'ValueType', 'any');

    if isempty(symbols)
        return;
    end

    assign_codes(symbols, frequencies, '');

    function assign_codes(local_symbols, local_frequencies, prefix)
        if length(local_symbols) == 1
            if isempty(prefix)
                dict(uint32(local_symbols(1))) = '0';
            else
                dict(uint32(local_symbols(1))) = prefix;
            end
            return;
        end

        split_idx = find_split_index(local_frequencies);

        assign_codes(local_symbols(1:split_idx), local_frequencies(1:split_idx), [prefix, '0']);
        assign_codes(local_symbols(split_idx+1:end), local_frequencies(split_idx+1:end), [prefix, '1']);
    end
end

function split_idx = find_split_index(frequencies)
    total_freq = sum(double(frequencies));
    running_sum = 0;
    best_diff = inf;
    split_idx = 1;

    for i = 1:length(frequencies)-1
        running_sum = running_sum + double(frequencies(i));
        diff = abs(total_freq - 2 * running_sum);
        if diff < best_diff
            best_diff = diff;
            split_idx = i;
        end
    end
end
