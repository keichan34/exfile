ExUnit.start()

Exfile.ProcessorRegistry.register "reverse", Exfile.ReverseProcessor
Exfile.ProcessorRegistry.register "reverse-tempfile", Exfile.ReverseTempfileProcessor
Exfile.ProcessorRegistry.register "truncate", Exfile.TruncateProcessor
