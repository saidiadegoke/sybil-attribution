function net = elect_competition(net, cfg, score, Rc, eligible) %#ok<INUSL>
% ELECT_COMPETITION  Greedy local-maximum competition: among eligible alive
% nodes (descending 'score'), a node becomes CH unless an already-chosen CH lies
% within its radius Rc. The within-radius test is vectorised over chosen CHs.
  N = numel(net.x);
  net.role = zeros(1,N); net.cid = zeros(1,N);
  idx = find(eligible & net.alive);
  if isempty(idx), return; end
  [~, o] = sort(score(idx), 'descend');
  idx = idx(o);
  cx = []; cy = [];                       % chosen CH coordinates
  for i = idx
    if isempty(cx) || ~any(hypot(net.x(i)-cx, net.y(i)-cy) <= Rc(i))
      net.role(i) = 1; net.cid(i) = i;
      cx(end+1) = net.x(i); cy(end+1) = net.y(i); %#ok<AGROW>
    end
  end
  if isempty(cx)
    i = idx(1); net.role(i) = 1; net.cid(i) = i;
  end
end
