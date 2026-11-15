function R = build_rulebase_tao()
% BUILD_RULEBASE_TAO  The published 27-rule base of UCT2TSK, transcribed
% verbatim from Table 1 of:
%   Tao, Y., Zhang, J., & Yang, L. (2020). An unequal clustering algorithm for
%   wireless sensor networks based on interval type-2 TSK fuzzy logic theory.
%   IEEE Access, 8, 197173-197183.  doi:10.1109/ACCESS.2020.3034607
%
% Unlike BUILD_RULEBASE (which derives consequents from a monotone score), every
% consequent here is a published number, so this baseline is a transcription
% rather than a reconstruction.
%
% Returns a 27 x 5 matrix: [RDB  RE  ND  Cr  Rank]
%   antecedent codes : RDB 1=Close 2=Medium 3=Far
%                      RE  1=Low   2=Medium 3=High
%                      ND  1=Low   2=Medium 3=High
%   consequents      : Cr, Rank are crisp TSK singletons drawn from the 11
%                      levels {0, 0.1, ..., 1.0} (Tao, §IV-A-1).
%
% Sanity checks against the prose of Tao §IV-A-2:
%   RDB Far,   RE High, ND Low   -> Cr   = 1 (max)   [rule 27]
%   RDB Close, RE Low,  ND High  -> Cr   = 0 (min)   [rule  1]
%   RDB Close, RE High, ND High  -> Rank = 1 (max)   [rule  7]
%   RDB Far,   RE Low,  ND Low   -> Rank = 0 (min)   [rule 21]

  R = [ ...
  % RDB  RE  ND    Cr   Rank
      1   1   3   0.0   0.4    % 1  Close  Low     High
      1   1   2   0.1   0.3    % 2  Close  Low     Medium
      1   1   1   0.2   0.2    % 3  Close  Low     Low
      1   2   3   0.1   0.7    % 4  Close  Medium  High
      1   2   2   0.2   0.6    % 5  Close  Medium  Medium
      1   2   1   0.3   0.5    % 6  Close  Medium  Low
      1   3   3   0.2   1.0    % 7  Close  High    High
      1   3   2   0.3   0.9    % 8  Close  High    Medium
      1   3   1   0.4   0.8    % 9  Close  High    Low
      2   1   3   0.3   0.3    % 10 Medium Low     High
      2   1   2   0.4   0.2    % 11 Medium Low     Medium
      2   1   1   0.5   0.1    % 12 Medium Low     Low
      2   2   3   0.4   0.6    % 13 Medium Medium  High
      2   2   2   0.5   0.5    % 14 Medium Medium  Medium
      2   2   1   0.6   0.4    % 15 Medium Medium  Low
      2   3   3   0.5   0.9    % 16 Medium High    High
      2   3   2   0.6   0.8    % 17 Medium High    Medium
      2   3   1   0.7   0.7    % 18 Medium High    Low
      3   1   3   0.6   0.2    % 19 Far    Low     High
      3   1   2   0.7   0.1    % 20 Far    Low     Medium
      3   1   1   0.8   0.0    % 21 Far    Low     Low
      3   2   3   0.7   0.5    % 22 Far    Medium  High
      3   2   2   0.8   0.4    % 23 Far    Medium  Medium
      3   2   1   0.9   0.3    % 24 Far    Medium  Low
      3   3   3   0.8   0.8    % 25 Far    High    High
      3   3   2   0.9   0.7    % 26 Far    High    Medium
      3   3   1   1.0   0.6 ]; % 27 Far    High    Low
end
