function save_section2_case_mat(matfile, case_data)
%SAVE_SECTION2_CASE_MAT Save a frozen official-style Section 2 case.
required = {'name','train_U','train_Y','ref_y','official_u','official_y'};
for i = 1:numel(required)
    if ~isfield(case_data, required{i})
        error('save_section2_case_mat:MissingField', ...
            'case_data.%s is required.', required{i});
    end
end
folder = fileparts(matfile);
if ~isempty(folder) && ~exist(folder,'dir')
    mkdir(folder);
end
save(matfile, 'case_data');
end
