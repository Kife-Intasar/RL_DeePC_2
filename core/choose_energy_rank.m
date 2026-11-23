function r = choose_energy_rank(s, energy)
%CHOOSE_ENERGY_RANK Smallest rank reaching desired cumulative energy.

if isempty(s) || all(s <= 0)
    r = 1;
    return;
end
s = real(s(:));
cs = cumsum(s) / max(sum(s), eps);
r = find(cs >= energy, 1, 'first');
if isempty(r), r = numel(s); end
end
