function code_assignment_d(input_source, output_filename)
    % Code assignment decompressor for the Shannon-Fano style codebook
    % written by code_assignment_c.

    if nargin < 2
        error('code_assignment_d requires input_source and output_filename.');
    end

    app = normalize_input_source(input_source);
    input_fullpath = fullfile(app.filepath, app.filename);
    output_fullpath = fullfile(app.filepath, output_filename);

    [encoded_bits, symbols, frequencies] = load_compressed(input_fullpath);
    [sorted_symbols, sorted_frequencies] = sort_by_frequency(symbols, frequencies);
    dict = build_codebook(sorted_symbols, sorted_frequencies);

    reverse_dict = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
    symbol_keys = keys(dict);
    for i = 1:numel(symbol_keys)
        reverse_dict(dict(symbol_keys{i})) = uint32(symbol_keys{i});
    end

    decoded_data = zeros(1, numel(encoded_bits), 'uint8');
    current_code = '';
    out_idx = 1;

    for i = 1:numel(encoded_bits)
        current_code = [current_code, encoded_bits(i)];
        if isKey(reverse_dict, current_code)
            decoded_data(out_idx) = uint8(reverse_dict(current_code));
            out_idx = out_idx + 1;
            current_code = '';
        end
    end

    decoded_data = decoded_data(1:out_idx - 1);

    fid = fopen(output_fullpath, 'wb');
    if fid == -1
        error('Cannot create output file: %s', output_fullpath);
    end
    fwrite(fid, decoded_data, 'uint8');
    fclose(fid);
end

function app = normalize_input_source(input_source)
    if ischar(input_source) || (isstring(input_source) && isscalar(input_source))
        input_path = char(input_source);
        [filepath, name, ext] = fileparts(input_path);

        if isempty(filepath)
            filepath = pwd;
        end

        app = struct('filepath', filepath, 'filename', [name, ext]);
        return;
    end

    if isstruct(input_source) || isobject(input_source)
        if isprop_or_field(input_source, 'filepath') && isprop_or_field(input_source, 'filename')
            app = struct();
            app.filepath = char(read_prop_or_field(input_source, 'filepath'));
            app.filename = char(read_prop_or_field(input_source, 'filename'));
            return;
        end
    end

    error('input_source must be an app-like object/struct or an input file path.');
end

function tf = isprop_or_field(value, name)
    tf = isstruct(value) && isfield(value, name);
    if ~tf && isobject(value)
        tf = isprop(value, name);
    end
end

function out = read_prop_or_field(value, name)
    out = value.(name);
end

function [encoded_bits, symbols, frequencies] = load_compressed(filename)
    fid = fopen(filename, 'rb');
    if fid == -1
        error('Cannot open compressed file: %s', filename);
    end

    num_symbols = fread(fid, 1, 'uint32');
    symbols = fread(fid, num_symbols, 'uint8')';
    frequencies = fread(fid, num_symbols, 'uint32')';
    padding_needed = fread(fid, 1, 'uint8');
    bytes = fread(fid, inf, 'uint8')';
    fclose(fid);

    encoded_bits = '';
    for i = 1:numel(bytes)
        encoded_bits = [encoded_bits, dec2bin(bytes(i), 8)];
    end

    if padding_needed > 0
        encoded_bits = encoded_bits(1:end - padding_needed);
    end
end

function [sorted_symbols, sorted_frequencies] = sort_by_frequency(symbols, frequencies)
    [sorted_frequencies, idx] = sort(double(frequencies), 'descend');
    sorted_symbols = symbols(idx);
    sorted_frequencies = uint32(sorted_frequencies);
end

function dict = build_codebook(symbols, frequencies)
    dict = containers.Map('KeyType', 'uint32', 'ValueType', 'any');

    if isempty(symbols)
        return;
    end

    assign_codes(symbols, frequencies, '');

    function assign_codes(local_symbols, local_frequencies, prefix)
        if numel(local_symbols) == 1
            if isempty(prefix)
                dict(uint32(local_symbols(1))) = '0';
            else
                dict(uint32(local_symbols(1))) = prefix;
            end
            return;
        end

        split_idx = find_split_index(local_frequencies);

        assign_codes(local_symbols(1:split_idx), local_frequencies(1:split_idx), [prefix, '0']);
        assign_codes(local_symbols(split_idx + 1:end), local_frequencies(split_idx + 1:end), [prefix, '1']);
    end
end

function split_idx = find_split_index(frequencies)
    total_freq = sum(double(frequencies));
    running_sum = 0;
    best_diff = inf;
    split_idx = 1;

    for i = 1:numel(frequencies) - 1
        running_sum = running_sum + double(frequencies(i));
        diff_value = abs(total_freq - 2 * running_sum);
        if diff_value < best_diff
            best_diff = diff_value;
            split_idx = i;
        end
    end
end
