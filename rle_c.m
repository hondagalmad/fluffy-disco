function rle_c(app, output_filename)
    % 1. Construct full input file path
    input_fullpath = fullfile(app.filepath, app.filename);
    
    % 2. Read input file as bytes
    fid = fopen(input_fullpath, 'rb');
    if fid == -1, error('Cannot open file'); end
    file_data = fread(fid, inf, 'uint8')';
    fclose(fid);
    
    if isempty(file_data)
        return;
    end

    % 3. Run-Length Encoding Logic
    % We find where the data changes
    changes = [find(file_data(1:end-1) ~= file_data(2:end)), length(file_data)];
    counts = diff([0, changes]);
    symbols = file_data(changes);
    
    % 4. Save compressed file
    % Format: [Symbol (1 byte)][Count (1 byte)] repeat...
    output_fullpath = fullfile(app.filepath, output_filename);
    fid_out = fopen(output_fullpath, 'wb');
    
    for i = 1:length(symbols)
        fwrite(fid_out, symbols(i), 'uint8'); % The actual byte
        fwrite(fid_out, counts(i), 'uint8');  % How many times it repeats
    end
    
    fclose(fid_out);
end
