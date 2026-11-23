function outdir = export_complete_numerical_study_csv(study, outdir)
%EXPORT_COMPLETE_NUMERICAL_STUDY_CSV Export rectangular reviewer-facing CSV tables.
if nargin < 2 || isempty(outdir)
    if isfield(study,'spec') && isfield(study.spec,'results_root')
        outdir = fullfile(study.spec.results_root, 'complete_csv');
    else
        outdir = fullfile(pwd, 'results', 'complete_csv');
    end
end
main_dir = fullfile(outdir,'main');
abl_dir = fullfile(outdir,'ablations');
if ~exist(main_dir,'dir'), mkdir(main_dir); end
if ~exist(abl_dir,'dir'), mkdir(abl_dir); end

main = local_getfield(study,'main',struct());
sec1 = local_getfield(main,'section1',struct());
T1 = local_build_section1_cases(sec1);
writetable(T1, fullfile(main_dir,'section1_cases_complete.csv'));
T2 = local_build_section1_summary(T1);
writetable(T2, fullfile(main_dir,'section1_summary_complete.csv'));
T3 = local_build_section1_horizon(sec1);
writetable(T3, fullfile(main_dir,'section1_horizon_complete.csv'));

Tn = local_build_section2(local_getfield(main,'section2_nano',struct()), 'nano');
writetable(Tn, fullfile(main_dir,'section2_nano_complete.csv'));
Tv = local_build_section2(local_getfield(main,'section2_vsc_hvdc',struct()), 'vsc_hvdc');
writetable(Tv, fullfile(main_dir,'section2_vsc_hvdc_complete.csv'));
Tall = local_union_tables({Tn,Tv});
writetable(Tall, fullfile(main_dir,'section2_all_complete.csv'));

Ts = local_build_synthesis(local_getfield(main,'synthesis',struct()));
writetable(Ts, fullfile(main_dir,'synthesis_complete.csv'));

abl = local_getfield(study,'ablations',struct());
local_write_any(local_getfield(abl,'prediction_energy',table()), fullfile(abl_dir,'prediction_energy_sweep.csv'),'prediction_energy_sweep');
local_write_any(local_getfield(abl,'section2_energy',table()), fullfile(abl_dir,'section2_energy_sweep.csv'),'section2_energy_sweep');
local_write_any(local_getfield(abl,'horizon',table()), fullfile(abl_dir,'horizon_sweep.csv'),'horizon_sweep');
local_write_any(local_getfield(abl,'penalty',table()), fullfile(abl_dir,'penalty_sweep.csv'),'penalty_sweep');
local_write_any(local_getfield(abl,'seed_robustness',table()), fullfile(abl_dir,'seed_robustness.csv'),'seed_robustness');
local_write_any(local_getfield(abl,'noise_robustness',table()), fullfile(abl_dir,'noise_robustness.csv'),'noise_robustness');

Tf = local_build_failures(local_getfield(study,'failures',struct()));
writetable(Tf, fullfile(outdir,'failures_complete.csv'));

fprintf('\nCSV export completed:\n%s\n', outdir);
end

function T = local_build_section1_cases(sec1)
rows = {};
if isstruct(sec1) && isfield(sec1,'datasets')
    dnames = fieldnames(sec1.datasets);
    for id = 1:numel(dnames)
        ds = dnames{id};
        cases = sec1.datasets.(ds);
        for ic = 1:numel(cases)
            Ri = cases(ic);
            mnames = fieldnames(Ri.methods);
            for im = 1:numel(mnames)
                m = mnames{im};
                M = Ri.methods.(m).metrics;
                rr = struct('dataset',string(ds),'case_name',string(Ri.case),'method',string(m), ...
                    'rmse', local_getfield(M,'rmse',NaN), 'mae', local_getfield(M,'mae',NaN), ...
                    'nrmse', local_getfield(M,'nrmse',NaN), 'fit', local_getfield(M,'fit',NaN), ...
                    'r2', local_getfield(M,'r2',NaN), 'multi_rmse', local_getfield(M,'multi_rmse',NaN), ...
                    'multi_mae', local_getfield(M,'multi_mae',NaN), 'multi_r2', local_getfield(M,'multi_r2',NaN), ...
                    'mean_solve_ms', local_getfield(M,'mean_solve_ms',NaN), 'median_solve_ms', local_getfield(M,'median_solve_ms',NaN), ...
                    'p95_solve_ms', local_getfield(M,'p95_solve_ms',NaN), 'worst_solve_ms', local_getfield(M,'worst_solve_ms',NaN), ...
                    'order', local_getfield(M,'order',NaN), 'order_mean', local_getfield(M,'order_mean',NaN));
                rows{end+1} = rr; %#ok<AGROW>
            end
        end
    end
end
T = local_rows_to_table(rows,'section1_cases');
end

function T = local_build_section1_summary(Tcases)
if isempty(Tcases) || height(Tcases)==0 || ismember('status',Tcases.Properties.VariableNames)
    T = local_placeholder('section1_summary','No Section 1 cases rows available.'); return;
end
[G, dataset, method] = findgroups(Tcases.dataset, Tcases.method);
rmse = splitapply(@mean, Tcases.rmse, G);
mae = splitapply(@mean, Tcases.mae, G);
fit = splitapply(@mean, Tcases.fit, G);
multi_rmse = splitapply(@mean, Tcases.multi_rmse, G);
mean_solve_ms = splitapply(@mean, Tcases.mean_solve_ms, G);
order_mean = splitapply(@mean, Tcases.order_mean, G);
T = table(dataset, method, rmse, mae, fit, multi_rmse, mean_solve_ms, order_mean);
end

function T = local_build_section1_horizon(sec1)
rows = {};
if isstruct(sec1) && isfield(sec1,'datasets')
    dnames = fieldnames(sec1.datasets);
    for id = 1:numel(dnames)
        ds = dnames{id};
        cases = sec1.datasets.(ds);
        for ic = 1:numel(cases)
            Ri = cases(ic);
            mnames = fieldnames(Ri.methods);
            for im = 1:numel(mnames)
                m = mnames{im};
                M = Ri.methods.(m).metrics;
                hr = local_getfield(M,'horizon_rmse',[]);
                hm = local_getfield(M,'horizon_mae',[]);
                hb = local_getfield(M,'horizon_bias',[]);
                H = max([numel(hr), numel(hm), numel(hb)]);
                for h = 1:H
                    rr = struct('dataset',string(ds),'case_name',string(Ri.case),'method',string(m),'horizon',h, ...
                        'horizon_rmse',local_vecget(hr,h),'horizon_mae',local_vecget(hm,h),'horizon_bias',local_vecget(hb,h));
                    rows{end+1}=rr; %#ok<AGROW>
                end
            end
        end
    end
end
T = local_rows_to_table(rows,'section1_horizon');
end

function T = local_build_section2(sec2, caselabel)
rows = {};
if isstruct(sec2) && isfield(sec2,'results')
    mnames = fieldnames(sec2.results);
    for im = 1:numel(mnames)
        m = mnames{im};
        x = sec2.results.(m).metrics;
        rr = struct('case_name',string(caselabel),'method',string(m), ...
            'rmse',local_getfield(x,'rmse',NaN),'mae',local_getfield(x,'mae',NaN), ...
            'nrmse',local_getfield(x,'nrmse',NaN),'fit',local_getfield(x,'fit',NaN), ...
            'cumulative_stage_cost',local_getfield(x,'cumulative_stage_cost',NaN), ...
            'mean_solve_ms',local_getfield(x,'mean_solve_ms',NaN), ...
            'order',local_getfield(x,'reduced_order',local_getfield(x,'order',NaN)), ...
            'latent_dim',local_getfield(x,'latent_dim',NaN));
        if isfield(sec2,'case_plot') && isfield(sec2.case_plot,'ref_y') && isfield(sec2.results.(m),'Y')
            [rr.ref_rmse, rr.ref_mae] = local_ref_metrics(sec2.case_plot.ref_y, sec2.results.(m).Y);
        else
            rr.ref_rmse = NaN; rr.ref_mae = NaN;
        end
        rows{end+1} = rr; %#ok<AGROW>
    end
end
T = local_rows_to_table(rows,['section2_' caselabel]);
end

function T = local_build_synthesis(syn)
rows = {};
if isstruct(syn)
    bnames = fieldnames(syn);
    for ib = 1:numel(bnames)
        bname = bnames{ib};
        b = syn.(bname);
        if isstruct(b) && isfield(b,'methods')
            mnames = fieldnames(b.methods);
            for im = 1:numel(mnames)
                m = mnames{im};
                x = b.methods.(m);
                rr = struct('benchmark',string(bname),'method',string(m), ...
                    'rmse',local_getfield(x,'rmse',NaN),'mae',local_getfield(x,'mae',NaN), ...
                    'fit',local_getfield(x,'fit',NaN),'cumulative_stage_cost',local_getfield(x,'cumulative_stage_cost',NaN), ...
                    'mean_solve_ms',local_getfield(x,'mean_solve_ms',NaN),'order',local_getfield(x,'reduced_order',local_getfield(x,'latent_dim',NaN)));
                rows{end+1}=rr; %#ok<AGROW>
            end
        end
        if isstruct(b) && isfield(b,'failures')
            fns = fieldnames(b.failures);
            for jf = 1:numel(fns)
                rr = struct('benchmark',string(bname),'method',string(fns{jf}),'rmse',NaN,'mae',NaN,'fit',NaN,'cumulative_stage_cost',NaN,'mean_solve_ms',NaN,'order',NaN,'status',"failed", ...
                    'error_message',string(local_getfield(b.failures.(fns{jf}),'message','')));
                rows{end+1}=rr; %#ok<AGROW>
            end
        end
    end
end
T = local_rows_to_table(rows,'synthesis');
end

function T = local_build_failures(failures)
rows = {};
if isstruct(failures)
    fns = fieldnames(failures);
    for i = 1:numel(fns)
        f = failures.(fns{i});
        rr = struct('step',string(fns{i}),'ok',local_getfield(f,'ok',true),'identifier',string(local_getfield(f,'identifier','')),'message',string(local_getfield(f,'message','')));
        rows{end+1}=rr; %#ok<AGROW>
    end
end
T = local_rows_to_table(rows,'failures');
end

function local_write_any(x, fname, label)
if istable(x)
    T = x;
elseif isempty(x)
    T = local_placeholder(label,'Missing or empty.');
else
    T = local_rows_to_table({struct('content',string(evalc('disp(x)')))}, label);
end
writetable(T, fname);
end

function [rmse, mae] = local_ref_metrics(R, Y)
T = min(size(R,2), size(Y,2));
if T<=0, rmse=NaN; mae=NaN; return; end
E = Y(:,1:T) - R(:,1:T);
rmse = sqrt(mean(E(:).^2));
mae = mean(abs(E(:)));
end

function T = local_rows_to_table(rows, label)
if nargin < 2, label = 'data'; end
if isempty(rows)
    T = local_placeholder(label,'No rows produced.');
    return;
end
allvars = {};
for i = 1:numel(rows), allvars = union(allvars, fieldnames(rows{i}), 'stable'); end
S = repmat(struct(), numel(rows), 1);
for i = 1:numel(rows)
    rr = rows{i};
    for j = 1:numel(allvars)
        v = allvars{j};
        if isfield(rr,v), S(i).(v) = rr.(v); else, S(i).(v) = missing_value(); end
    end
end
T = struct2table(S);
T = T(:, allvars);
end

function T = local_union_tables(Tlist)
keep = Tlist(~cellfun(@isempty, Tlist));
if isempty(keep), T = local_placeholder('section2_all','No rows produced.'); return; end
% Prefer real row tables over placeholders when available.
real_idx = cellfun(@(Ti) ~(ismember('status', Ti.Properties.VariableNames) && height(Ti)==1 && strcmpi(string(Ti.status(1)),"placeholder")), keep);
if any(real_idx)
    keep = keep(real_idx);
end
allvars = {};
for i = 1:numel(keep), allvars = union(allvars, keep{i}.Properties.VariableNames, 'stable'); end
for i = 1:numel(keep)
    Ti = keep{i};
    for j = 1:numel(allvars)
        if ~ismember(allvars{j}, Ti.Properties.VariableNames)
            Ti.(allvars{j}) = repmat(missing_value(), height(Ti), 1);
        end
    end
    keep{i} = Ti(:, allvars);
end
T = vertcat(keep{:});
end

function T = local_placeholder(label, msg)
T = table(string(label), string(msg), "placeholder", 'VariableNames', {'block','message','status'});
end

function v = local_getfield(s,name,default)
if isstruct(s) && isfield(s,name), v=s.(name); else, v=default; end
end

function v = local_vecget(x,i)
if isempty(x) || numel(x)<i, v = NaN; else, v = x(i); end
end

function v = missing_value()
v = string("");
end
