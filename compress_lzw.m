function compress_lzw(app, output_filename)
    input_fullpath = fullfile(app.filepath, app.filename);

    fid = fopen(input_fullpath, 'rb');
    data = fread(fid, inf, 'uint8')';
    fclose(fid);

    % Initialize dictionary
    dict = containers.Map('KeyType','char','ValueType','uint32');
    for i = 0:255
        dict(char(i)) = i;
    end

    next_code = 256;
    w = '';
    compressed = [];

    for i = 1:length(data)
        c = char(data(i));
        wc = [w c];

        if isKey(dict, wc)
            w = wc;
        else
            compressed(end+1) = dict(w);
            dict(wc) = next_code;
            next_code = next_code + 1;
            w = c;
        end
    end

    if ~isempty(w)
        compressed(end+1) = dict(w);
    end

    % Save file
    output_fullpath = fullfile(app.filepath, output_filename);
    fid = fopen(output_fullpath, 'wb');

    fwrite(fid, length(compressed), 'uint32');
    fwrite(fid, compressed, 'uint32');

    fclose(fid);
end