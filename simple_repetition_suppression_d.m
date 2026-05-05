function simple_repetition_suppression_d(app, output_filename)
    % Load compressed file
    input_fullpath = fullfile(app.filepath, app.filename);
    [compressed, target, threshold] = load_suppressed(input_fullpath);
    
    % Decode
    decoded = repetition_suppression_decode(compressed, target);
    
    % Save as text (same as Huffman example)
    output_fullpath = fullfile(app.filepath, output_filename);
    decoded_text = char(decoded);
    fid = fopen(output_fullpath, 'w');
    if fid == -1
        error('Cannot create output file: %s', output_fullpath);
    end
    fprintf(fid, '%s', decoded_text);
    fclose(fid);
end

function [compressed, target, threshold] = load_suppressed(filename)
    fid = fopen(filename, 'rb');
    if fid == -1
        error('Cannot open compressed file: %s', filename);
    end
    target = fread(fid, 1, 'uint8');
    threshold = fread(fid, 1, 'uint8');
    data_len = fread(fid, 1, 'uint32');
    compressed = fread(fid, data_len, 'uint8')';
    fclose(fid);
end

function decoded = repetition_suppression_decode(compressed, target)
    decoded = [];
    i = 1;
    while i <= length(compressed)
        if compressed(i) == target && i+2 <= length(compressed) && compressed(i+1) == 255
            run_len = compressed(i+2);
            decoded(end+1:end+run_len) = repmat(target, 1, run_len);
            i = i + 3;
        else
            decoded(end+1) = compressed(i);
            i = i + 1;
        end
    end
end