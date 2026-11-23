function out = merge_cfg(a, b)
%MERGE_CFG Merge structs, fields in b overwrite fields in a.
out = a;
if isempty(b), return; end
fn = fieldnames(b);
for i = 1:numel(fn)
    out.(fn{i}) = b.(fn{i});
end
end
