function [ber, pdr] = ber_pdr(rssi, cfg)
% BER_PDR  Eqs (M3)-(M4): BPSK BER from SNR, and link PDR = (1-BER)^L.
  snr = 10 .^ ((rssi - cfg.N0) / 10);     % linear SNR
  ber = qfunc(sqrt(2 .* snr));
  pdr = (1 - ber) .^ cfg.pktBits;
end
