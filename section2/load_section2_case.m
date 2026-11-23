function case_data = load_section2_case(rootdir, cfg)
%LOAD_SECTION2_CASE Load official-style Section 2 case data.
source = lower(cfg.section2_case_source);

switch source
    case 'nano'
        case_data = load_nano_official_case(rootdir, cfg.section2_case, cfg.section2_train_file, cfg.Tini);
        if ~isfield(case_data,'input_labels')
            case_data.input_labels = {'ftot','omegax','omegay','omegaz'};
        end
        if ~isfield(case_data,'output_labels')
            case_data.output_labels = {'x','y','z'};
        end

    case {'matfile','vsc_hvdc','vschvdc'}
        case_data = load_section2_mat_case(cfg.section2_mat_file);

    otherwise
        error('Unknown Section 2 case source: %s', cfg.section2_case_source);
end
end