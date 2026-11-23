function out = method_replacement_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_REPLACEMENT_DEEPC Online replacement DeePC baseline.
out = run_online_deepc_comparison_closed_loop(plant, ref, info, cfg, 'replacement_deepc');
out.method = 'replacement_deepc';
out.is_proposed = false;
out.reference_family = 'paper-online-replacement';
out.true_online_reduction = false;
end
