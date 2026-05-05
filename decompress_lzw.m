% New MATLAB Script
function decompress_lzw(app, input_filename, output_filename)
    input_fullpath = fullfile(app.filepath, input_filename);

    fid = fopen(input_fullpath, 'rb');

    n = fread(fid, 1, 'uint32');
    compressed = fread(fid, n, 'uint32')';
    fclose(fid);

    % Initialize dictionary
    dict = containers.Map('KeyType','uint32','ValueType','char');
    for i = 0:255
        dict(i) = char(i);
    end

    next_code = 256;

    w = dict(compressed(1));
    result = w;

    for i = 2:length(compressed)
        k = compressed(i);

        if isKey(dict, k)
            entry = dict(k);
        elseif k == next_code
            entry = [w w(1)];
        else
            error('Invalid compressed data');
        end

        result = [result entry];

        dict(next_code) = [w entry(1)];
        next_code = next_code + 1;

        w = entry;
    end

    % Save decompressed file
    output_fullpath = fullfile(app.filepath, output_filename);
    fid = fopen(output_fullpath, 'wb');

    fwrite(fid, uint8(result), 'uint8');

    fclose(fid);
end
