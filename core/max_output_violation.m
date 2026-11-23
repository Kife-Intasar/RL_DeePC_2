function v = max_output_violation(Y, ymin, ymax)
%MAX_OUTPUT_VIOLATION Max absolute output constraint violation.

lo = max(ymin - Y, 0);
hi = max(Y - ymax, 0);
v = max([lo(:); hi(:); 0]);
end
