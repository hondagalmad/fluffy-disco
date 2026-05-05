function shannon_fano_c(app, output_filename)
    % Construct full input file path
    input_fullpath = fullfile(app.filepath, app.filename);

    % Read input file
    fid = fopen(input_fullpath, 'rb');
    file_data = fread(fid, inf, 'uint8')';
    fclose(fid);

    if isempty(file_data)
        output_fullpath = fullfile(app.filepath, output_filename);
        save_compressed(output_fullpath, '', uint8([]), uint32([]));
        return;
    end

    % Calculate symbol frequencies
    symbols = unique(file_data);
    frequencies = zeros(1, length(symbols), 'uint32');
    for i = 1:length(symbols)
        frequencies(i) = sum(file_data == symbols(i));
    end

    % Build Shannon-Fano dictionary
    [sorted_symbols, sorted_frequencies] = sort_by_frequency(symbols, frequencies);
    dict = shannon_fano_dict(sorted_symbols, sorted_frequencies);

    % Encode the data
    encoded_data = '';
    for i = 1:length(file_data)
        encoded_data = [encoded_data, dict(uint32(file_data(i)))];
    end

    % Save compressed file
    output_fullpath = fullfile(app.filepath, output_filename);
    save_compressed(output_fullpath, encoded_data, sorted_symbols, sorted_frequencies);
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

function save_compressed(filename, encoded_data, symbols, frequencies)
    fid = fopen(filename, 'wb');

    fwrite(fid, length(symbols), 'uint32');
    fwrite(fid, symbols, 'uint8');
    fwrite(fid, frequencies, 'uint32');

    padding_needed = mod(8 - mod(length(encoded_data), 8), 8);
    padded_data = [encoded_data, repmat('0', 1, padding_needed)];

    num_bytes = length(padded_data) / 8;
    bytes = zeros(1, num_bytes, 'uint8');
    for i = 1:num_bytes
        byte_str = padded_data((i-1)*8+1:i*8);
        bytes(i) = bin2dec(byte_str);
    end

    fwrite(fid, padding_needed, 'uint8');
    fwrite(fid, bytes, 'uint8');

    fclose(fid);
end
