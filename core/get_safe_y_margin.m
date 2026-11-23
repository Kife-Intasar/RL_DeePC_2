function y_margin = get_safe_y_margin(plant, margin_raw)
%GET_SAFE_Y_MARGIN Clip robustness margin to keep constraints meaningful.

yr = plant.y_max - plant.y_min;
y_margin = min(margin_raw, 0.24*min(yr));
y_margin = max(y_margin, 0);
end
