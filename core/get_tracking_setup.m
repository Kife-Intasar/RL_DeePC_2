function setup = get_tracking_setup(ref, cfg, plant, k)
%GET_TRACKING_SETUP Return objective type and horizon references at time k.

N = cfg.N;
p = plant.p;
m = plant.m;

setup.mode = 'y';
setup.Qbar = kron(eye(N), cfg.Qy);
setup.Rbar = kron(eye(N), cfg.Ru);
setup.Rdu = cfg.Rdu;
setup.rvec = zeros(p*N,1);
setup.ucmd = zeros(m*N,1);
setup.uref = zeros(m*N,1);
setup.soft_y_penalty = cfg.soft_y_penalty;

setup.fix_first_input = false;
setup.fix_full_input = false;
setup.u_first = zeros(m,1);
setup.ufix = zeros(m*N,1);

% if isfield(cfg,'Qu_track') && ~isempty(cfg.Qu_track)
%     setup.Su = kron(eye(N), cfg.Qu_track);
% else
%     setup.Su = zeros(m*N);
% end

% Section 2 input-tracking weight.
% Only use it when dimensions match the current plant input dimension.
if isfield(cfg,'Qu_track') && ~isempty(cfg.Qu_track)
    if isscalar(cfg.Qu_track)
        Qu_local = cfg.Qu_track * eye(m);
    elseif isequal(size(cfg.Qu_track), [m m])
        Qu_local = cfg.Qu_track;
    else
        % Do not let a Section 2-specific Qu_track (e.g. 4x4 for nano/VSC)
        % leak into synthetic benchmarks with different input dimension.
        Qu_local = zeros(m);
    end
    setup.Su = kron(eye(N), Qu_local);
else
    setup.Su = zeros(m*N);
end

if isstruct(ref)
    switch lower(ref.mode)
        case 'input_safety_filter'
            setup.mode = 'u';
            setup.Qbar = kron(eye(N), max(cfg.Ru, 1e-3*eye(m)));
            setup.ucmd = ref.u(:, k:k+N-1);
            setup.ucmd = setup.ucmd(:);

        case 'output_and_input_tracking'
            setup.mode = 'yu';
            setup.rvec = ref.y(:, k:k+N-1);
            setup.rvec = setup.rvec(:);

            setup.uref = ref.u(:, k:k+N-1);
            setup.uref = setup.uref(:);

            if isfield(cfg,'section2_track_official_input') && cfg.section2_track_official_input
                if isfield(cfg,'section2_input_match_mode')
                    switch lower(cfg.section2_input_match_mode)
                        case 'fixed_first_move'
                            setup.fix_first_input = true;
                            setup.u_first = ref.u(:,k);

                        case 'fixed_full_horizon'
                            setup.fix_full_input = true;
                            setup.ufix = ref.u(:, k:k+N-1);
                            setup.ufix = setup.ufix(:);
                    end
                end
            end

        otherwise
            setup.mode = 'y';
            setup.rvec = ref.y(:, k:k+N-1);
            setup.rvec = setup.rvec(:);
    end
else
    setup.mode = 'y';
    setup.rvec = ref(:, k:k+N-1);
    setup.rvec = setup.rvec(:);
end
end