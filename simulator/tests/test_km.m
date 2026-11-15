function test_km()
% TEST_KM  Karnik-Mendel type-reduction: yl<=yr, within centroid range, and a
% degenerate-FOU case reduces to the standard centroid.
  set_seed(7);
  for t = 1:200
    M = randi([2 30]);
    c  = sort(rand(M,1));
    fu = 0.2 + 0.8*rand(M,1);
    fl = fu .* (0.2 + 0.8*rand(M,1));     % lower <= upper
    [yl, yr] = km_type_reduction(fl, fu, c);
    assert(yl <= yr + 1e-9, 'yl>yr');
    assert(yl >= min(c)-1e-9 && yr <= max(c)+1e-9, 'out of centroid range');
  end
  % degenerate: fl==fu  => interval collapses to the weighted centroid
  c=[0;0.5;1]; f=[0.3;0.6;0.9];
  [yl,yr]=km_type_reduction(f,f,c);
  cen = (f.'*c)/sum(f);
  assert(abs(yl-cen)<1e-9 && abs(yr-cen)<1e-9, 'degenerate FOU mismatch');
  fprintf('test_km: PASS\n');
end
