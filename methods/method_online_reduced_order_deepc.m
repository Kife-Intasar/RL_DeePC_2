function out = method_online_reduced_order_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_ONLINE_REDUCED_ORDER_DEEPC Paper-style selective online reduced-order DeePC.
out = run_online_deepc_comparison_closed_loop(plant, ref, info, cfg, 'online_reduced_order_deepc');
out.method = 'online_reduced_order_deepc';
out.is_proposed = false;
out.reference_family = 'paper-online-reduced-order';
out.true_online_reduction = true;
end
