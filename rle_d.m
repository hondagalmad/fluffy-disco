function rle_d(app, output_filename)
    % 1. Construct input path (the compressed file)
    input_fullpath = fullfile(app.filepath, app.filename);
    
    % 2. Read the compressed binary data
    fid = fopen(input_fullpath, 'rb');
    compressed_data = fread(fid, inf, 'uint8')';
    fclose(fid);
    
    % 3. Decompress
    % Data is in pairs: [Value, Count, Value, Count...]
    symbols = compressed_data(1:2:end);
    counts = compressed_data(2:2:end);
    
    % Reconstruct using repelem (very fast in MATLAB)
    original_data = repelem(symbols, counts);
    
    % 4. Save the recovered file
    output_fullpath = fullfile(app.filepath, output_filename);
    fid_out = fopen(output_fullpath, 'wb');
    fwrite(fid_out, original_data, 'uint8');
    fclose(fid_out);
end