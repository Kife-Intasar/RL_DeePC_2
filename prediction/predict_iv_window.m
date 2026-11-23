function yhat = predict_iv_window(pred, u_ini, y_ini, u_fut)
%PREDICT_IV_WINDOW Predict future outputs using direct IV predictor.
yvec = pred.Pu * u_ini(:) + pred.Py * y_ini(:) + pred.G * u_fut(:);
yhat = yvec(:);
end
