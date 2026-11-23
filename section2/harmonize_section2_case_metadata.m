function [case_data, cfg] = harmonize_section2_case_metadata(case_data, cfg)
%HARMONIZE_SECTION2_CASE_METADATA Auto-harmonize cfg with official case metadata.

if ~isfield(case_data,'meta') || isempty(case_data.meta)
    case_data.meta = struct();
end

meta = case_data.meta;

% ------------------------------------------------------------
% Infer defaults if metadata is missing
% ------------------------------------------------------------
if ~isfield(meta,'Tini_default') || isempty(meta.Tini_default)
    if isfield(case_data,'init_u_hist') && ~isempty(case_data.init_u_hist)
        meta.Tini_default = size(case_data.init_u_hist,2);
    else
        meta.Tini_default = cfg.Tini;
    end
end

if ~isfield(meta,'N_default') || isempty(meta.N_default)
    if isfield(case_data,'name') && contains(lower(case_data.name),'vsc')
        meta.N_default = 120;
    elseif isfield(case_data,'name') && contains(lower(case_data.name),'nano')
        meta.N_default = 8;
    else
        meta.N_default = cfg.N;
    end
end

if ~isfield(meta,'init_strategy') || isempty(meta.init_strategy)
    meta.init_strategy = 'pinvC';
end

% ------------------------------------------------------------
% Apply case defaults unless user explicitly forces own horizon
% ------------------------------------------------------------
if isfield(cfg,'section2_use_case_metadata') && cfg.section2_use_case_metadata && ...
   ~(isfield(cfg,'force_user_horizon') && cfg.force_user_horizon)

    cfg.Tini = meta.Tini_default;
    cfg.N = meta.N_default;

    if isfield(cfg,'section2_apply_case_weights') && cfg.section2_apply_case_weights
        if isfield(meta,'Qy_default') && ~isempty(meta.Qy_default), cfg.Qy = meta.Qy_default; end
        if isfield(meta,'Ru_default') && ~isempty(meta.Ru_default), cfg.Ru = meta.Ru_default; end
        if isfield(meta,'Rdu_default') && ~isempty(meta.Rdu_default), cfg.Rdu = meta.Rdu_default; end
        if isfield(meta,'lambda_g_default') && ~isempty(meta.lambda_g_default), cfg.lambda_g = meta.lambda_g_default; end
        if isfield(meta,'lambda_sigma_default') && ~isempty(meta.lambda_sigma_default), cfg.lambda_sigma = meta.lambda_sigma_default; end
        if isfield(meta,'markov_len_default') && ~isempty(meta.markov_len_default), cfg.markov_len = meta.markov_len_default; end
        if isfield(meta,'era_s_default') && ~isempty(meta.era_s_default), cfg.era_s = meta.era_s_default; end
        if isfield(meta,'era_l_default') && ~isempty(meta.era_l_default), cfg.era_l = meta.era_l_default; end
        if isfield(meta,'max_id_order_default') && ~isempty(meta.max_id_order_default), cfg.max_id_order = meta.max_id_order_default; end
    end
end

% ------------------------------------------------------------
% Rebuild init history so it always matches the effective cfg.Tini
% ------------------------------------------------------------
if isfield(case_data,'official_u') && isfield(case_data,'official_y')
    Tini_eff = min(cfg.Tini, size(case_data.official_u,2));
    if isfield(cfg,'section2_rebuild_init_from_cfg') && cfg.section2_rebuild_init_from_cfg
        case_data.init_u_hist = case_data.official_u(:,1:Tini_eff);
        case_data.init_y_hist = case_data.official_y(:,1:Tini_eff);
    end
    cfg.Tini = Tini_eff;
end

% ------------------------------------------------------------
% Clip horizon if user asked for too much
% ------------------------------------------------------------
if isfield(case_data,'ref_y') && ~isempty(case_data.ref_y)
    Ttotal = size(case_data.ref_y,2);
    Nmax = max(1, Ttotal - cfg.Tini);
    cfg.N = min(cfg.N, Nmax);
end

case_data.meta = meta;
end