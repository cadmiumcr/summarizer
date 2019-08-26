# summarizer

Inspired from [sumy](https://github.com/miso-belica/sumy), summarizer lets you summarize any input text through extraction based algorithms.

As of now, the following algorithms are implemented :

- Luhn
- SumBasic

More are being worked on.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     summarizer:
       github: your-github-user/summarizer
   ```

2. Run `shards install`

## Usage

```crystal
require "summarizer"

SumBasicSummarizer.new.summarize(long_text)
```

## Contributing

1. Fork it (<https://github.com/cadmiumcr/summarizer/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Rémy Marronnier](https://github.com/rmarronnier) - creator and maintainer