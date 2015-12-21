ExUnit.start()

Exfile.ProcessorRegistry.register "reverse", Exfile.ReverseProcessor
Exfile.ProcessorRegistry.register "truncate", Exfile.TruncateProcessor
