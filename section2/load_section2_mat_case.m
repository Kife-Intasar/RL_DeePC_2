function case_data = load_section2_mat_case(matfile)
%LOAD_SECTION2_MAT_CASE Load a frozen official-style Section 2 case from .mat.
S = load(matfile);
if isfield(S,'case_data')
    case_data = S.case_data;
else
    required = {'name','train_U','train_Y','ref_y','official_u','official_y'};
    for i = 1:numel(required)
        if ~isfield(S, required{i})
            error('load_section2_mat_case:MissingField', ...
                'MAT file must contain case_data or fields including %s.', required{i});
        end
    end
    case_data = struct();
    case_data.name = S.name;
    case_data.train_U = S.train_U;
    case_data.train_Y = S.train_Y;
    case_data.ref_y = S.ref_y;
    case_data.official_u = S.official_u;
    case_data.official_y = S.official_y;
    if isfield(S,'input_labels'), case_data.input_labels = S.input_labels; end
    if isfield(S,'output_labels'), case_data.output_labels = S.output_labels; end
end
case_data.train_U = double(case_data.train_U);
case_data.train_Y = double(case_data.train_Y);
case_data.ref_y = double(case_data.ref_y);
case_data.official_u = double(case_data.official_u);
case_data.official_y = double(case_data.official_y);

if ~isfield(case_data,'meta') || isempty(case_data.meta)
    case_data.meta = struct();
    case_data.meta.source = case_data.name;
    case_data.meta.case_kind = 'official_overlay';
end

if isfield(case_data,'official_u') && isfield(case_data,'official_y')
    if ~isfield(case_data,'init_u_hist') && isfield(case_data,'meta') && isfield(case_data.meta,'Tini_default')
        Tini0 = min(case_data.meta.Tini_default, size(case_data.official_u,2));
        case_data.init_u_hist = case_data.official_u(:,1:Tini0);
        case_data.init_y_hist = case_data.official_y(:,1:Tini0);
    end
end

end
