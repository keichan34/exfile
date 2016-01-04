# Clean out the temporary files path to ensure consistent tests.
File.rm_rf!(Path.expand("./tmp"))

# Prepare tmp/cache because we'll be writing files there before the backend is
# initialized.
File.mkdir_p!(Path.expand("./tmp/cache"))

ExUnit.start()

Exfile.ProcessorRegistry.register "reverse", Exfile.ReverseProcessor
Exfile.ProcessorRegistry.register "reverse-tempfile", Exfile.ReverseTempfileProcessor
Exfile.ProcessorRegistry.register "truncate", Exfile.TruncateProcessor
