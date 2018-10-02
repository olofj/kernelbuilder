FROM local/stage3-native as base

# Need to disable sandboxes due to lack of elevated privileges during build
RUN FEATURE="nodoc noinfo noman" emerge crossdev

# continue with image build ...
