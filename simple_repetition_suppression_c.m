function simple_repetition_suppression_c(app, output_filename)
    % Read input file
    input_fullpath = fullfile(app.filepath, app.filename);
    fid = fopen(input_fullpath, 'rb');
    if fid == -1
        error('Cannot open input file: %s', input_fullpath);
    end
    file_data = fread(fid, inf, 'uint8')';
    fclose(fid);
    
    % Suppression target and threshold (as in lecture: suppress runs of '0' longer than 3)
    target = uint8('0');      % character to suppress
    threshold = 3;            % run length > threshold triggers encoding
    
    % Compress
    compressed = repetition_suppression_encode(file_data, target, threshold);
    
    % Save compressed file
    output_fullpath = fullfile(app.filepath, output_filename);
    save_suppressed(output_fullpath, compressed, target, threshold);
end

function compressed = repetition_suppression_encode(data, target, threshold)
    compressed = [];
    i = 1;
    while i <= length(data)
        if data(i) == target
            start = i;
            while i <= length(data) && data(i) == target
                i = i + 1;
            end
            run_len = i - start;
            if run_len > threshold
                % Encode: target, marker (255), run_len
                compressed(end+1) = target;
                compressed(end+1) = 255;      % flag for encoded run
                compressed(end+1) = run_len;  % run_len fits in uint8 (max 255)
            else
                % Output unchanged
                compressed(end+1:end+run_len) = repmat(target, 1, run_len);
            end
        else
            compressed(end+1) = data(i);
            i = i + 1;
        end
    end
end

function save_suppressed(filename, compressed, target, threshold)
    fid = fopen(filename, 'wb');
    if fid == -1
        error('Cannot create compressed file: %s', filename);
    end
    fwrite(fid, target, 'uint8');
    fwrite(fid, threshold, 'uint8');
    fwrite(fid, length(compressed), 'uint32');
    fwrite(fid, compressed, 'uint8');
    fclose(fid);
end