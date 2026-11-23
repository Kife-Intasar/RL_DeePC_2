function out = method_adding_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_ADDING_DEEPC Online adding DeePC baseline with SVD reduction.
out = run_online_deepc_comparison_closed_loop(plant, ref, info, cfg, 'adding_deepc');
out.method = 'adding_deepc';
out.is_proposed = false;
out.reference_family = 'paper-online-adding';
out.true_online_reduction = true;
end
