function plant = make_benchmark(bname, cfg)
%MAKE_BENCHMARK Create plant benchmark by name.

if nargin < 2
    cfg = struct();
end

fun = str2func(['make_' lower(bname)]);

% Prefer zero-argument plant constructors.
try
    plant = fun();
catch ME
    % Fallback for plant constructors that expect cfg
    if contains(ME.message, 'Too many input arguments') || ...
       contains(ME.message, 'Not enough input arguments')
        plant = fun(cfg);
    else
        rethrow(ME);
    end
end

end