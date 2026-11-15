# localization/ — intentionally empty (out of scope)

RSSI is used in this project **only as a link-quality metric** (channel/), never
for node positioning. Anchor-based localization, trilateration, error-correction,
and the FULL/LIGHT/NONE Adaptive Localization Mode were **kicked back** in the
design audit (`reviews/methodology-design-v2-with-refworks.md`, items A8/A9) as
out of scope; they would re-introduce an anchor dependency the protocol avoids.

This folder is a placeholder so the directory layout matches the design doc.
Localization is named future work, not part of STITCH.
