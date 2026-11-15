function nbr = neighbors(net, cfg)
% NEIGHBORS  Communication-range adjacency (alive nodes within cfg.commRange).
  N = numel(net.x);
  nbr = cell(1,N);
  for i = 1:N
    d = hypot(net.x - net.x(i), net.y - net.y(i));
    nbr{i} = find(d > 0 & d <= cfg.commRange & net.alive);
  end
end
